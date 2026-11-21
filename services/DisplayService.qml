pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    property var monitors: []
    property int monitorCount: monitors.length
    property bool hasMultipleMonitors: monitorCount > 1
    property string selectedMonitor: ""
    property string activePreset: "extend"
    property bool busy: queryProc.running || applyProc.running

    // 10-Second Revert / Confirmation State
    property bool isConfirming: false
    property int revertCountdown: 10
    property var pendingChange: null

    signal requestOpenSettings(int tabIndex)

    function openDisplaySettings() {
        CenterState.open("Display");
        requestOpenSettings(7);
    }

    // Selected monitor object helper
    readonly property var currentMonitor: {
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].name === selectedMonitor) return monitors[i];
        }
        return monitors.length > 0 ? monitors[0] : null;
    }

    Component.onCompleted: {
        refresh();
    }

    // Monitor event listener via Quickshell.Hyprland
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "monitoradded" || event.name === "monitorremoved" || event.name === "configreloaded") {
                if (!root.isConfirming) {
                    refresh();
                }
            }
        }
    }

    // 10-Second Confirmation Countdown Timer
    Timer {
        id: revertTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.revertCountdown--;
            if (root.revertCountdown <= 0) {
                stop();
                root.revertChanges();
            }
        }
    }

    // Query monitors from Hyprland
    function refresh() {
        if (queryProc.running) return;
        queryProc.command = ["hyprctl", "monitors", "all", "-j"];
        queryProc.running = true;
    }

    Process {
        id: queryProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    let rawList = JSON.parse(text);
                    if (!Array.isArray(rawList)) return;

                    let parsed = [];
                    let hasMirror = false;
                    let internalDisabled = false;
                    let externalDisabled = false;

                    for (let i = 0; i < rawList.length; i++) {
                        let m = rawList[i];
                        let isInt = m.name.indexOf("eDP") === 0 || m.name.indexOf("LVDS") === 0 || m.name.indexOf("dsi") === 0;
                        let mirror = (m.mirrorOf && m.mirrorOf !== "none") ? m.mirrorOf : "";
                        if (mirror) hasMirror = true;
                        if (m.disabled) {
                            if (isInt) internalDisabled = true;
                            else externalDisabled = true;
                        }

                        let rr = Math.round((m.refreshRate || 60) * 100) / 100;
                        let modes = Array.isArray(m.availableModes) ? m.availableModes : [];
                        
                        // Determine native physical maximum dimensions
                        let natW = m.width || 1920;
                        let natH = m.height || 1080;
                        if (modes.length > 0 && modes[0].indexOf("x") !== -1) {
                            let p = modes[0].split("@")[0].split("x");
                            natW = parseInt(p[0]);
                            natH = parseInt(p[1]);
                        }

                        parsed.push({
                            id: m.id !== undefined ? m.id : i,
                            name: m.name || ("Display-" + i),
                            description: m.description || (m.make ? (m.make + " " + m.model) : (isInt ? "Built-in Display" : "External Display")),
                            width: m.width || 1920,
                            height: m.height || 1080,
                            nativeWidth: natW,
                            nativeHeight: natH,
                            refreshRate: rr,
                            x: m.x || 0,
                            y: m.y || 0,
                            scale: m.scale || 1.0,
                            transform: m.transform || 0,
                            focused: Boolean(m.focused),
                            disabled: Boolean(m.disabled),
                            mirrorOf: mirror,
                            availableModes: modes,
                            isInternal: isInt,
                            modeString: (m.width && m.height) ? (m.width + "x" + m.height + "@" + Math.round(rr) + "Hz") : "Auto"
                        });
                    }

                    root.monitors = parsed;

                    // Update selected monitor if needed
                    let found = false;
                    for (let i = 0; i < parsed.length; i++) {
                        if (parsed[i].name === root.selectedMonitor) {
                            found = true;
                            break;
                        }
                    }
                    if (!found && parsed.length > 0) {
                        root.selectedMonitor = parsed[0].name;
                    }

                    // Compute active preset
                    if (hasMirror) {
                        root.activePreset = "mirror";
                    } else if (internalDisabled) {
                        root.activePreset = "secondOnly";
                    } else if (externalDisabled) {
                        root.activePreset = "internalOnly";
                    } else {
                        root.activePreset = "extend";
                    }
                } catch (e) {}
            }
        }
    }

    // Check if a resolution chip matches the monitor's current active resolution
    function isCurrentResolution(mon, chipValue) {
        if (!mon || !chipValue) return false;

        let targetRes = chipValue.split("@")[0];
        let currentRes = mon.width + "x" + mon.height;

        return currentRes === targetRes;
    }

    // Normalize resolution mode string for Hyprland
    function formatModeForHyprland(mon, modeValue) {
        if (!modeValue || modeValue === "preferred") return "preferred";

        // If it matches the native resolution, use "preferred" for 100% reliability
        if (mon && mon.nativeWidth && mon.nativeHeight) {
            let nativeBase = mon.nativeWidth + "x" + mon.nativeHeight;
            if (modeValue.indexOf(nativeBase) === 0) {
                return "preferred";
            }
        }

        // If exact availableMode exists in driver list
        if (mon && mon.availableModes) {
            for (let i = 0; i < mon.availableModes.length; i++) {
                let m = mon.availableModes[i];
                if (m.indexOf(modeValue) === 0 || modeValue === m.replace("Hz", "").replace(".00", "")) {
                    return m;
                }
            }
        }

        return modeValue;
    }

    // Apply monitor directives to Hyprland runtime via native hl.monitor
    function applyLuaDirectives(configs) {
        if (!configs || configs.length === 0) return;

        let luaLines = configs.map(c => {
            if (c.disabled) {
                return 'hl.monitor({ output = "' + c.output + '", disabled = true })';
            } else if (c.mirror) {
                return 'hl.monitor({ output = "' + c.output + '", mode = "preferred", position = "auto", scale = 1, mirror = "' + c.mirror + '" })';
            } else {
                let m = c.mode || "preferred";
                let p = c.position || "auto";
                let s = c.scale !== undefined ? c.scale : 1.0;
                let t = c.transform !== undefined ? c.transform : 0;
                return 'hl.monitor({ output = "' + c.output + '", mode = "' + m + '", position = "' + p + '", scale = ' + s + ', transform = ' + t + ' })';
            }
        }).join("; ");

        let cmd = "hyprctl eval '" + luaLines + "'";
        applyProc.command = ["sh", "-c", cmd];
        applyProc.running = false;
        applyProc.running = true;
    }

    // Save monitor directives permanently to ~/.config/hypr/monitors.lua & monitors.conf
    function persistMonitorsConfig() {
        let luaLines = root.monitors.map(m => {
            if (m.disabled) {
                return 'hl.monitor({ output = "' + m.name + '", disabled = true })';
            } else if (m.mirrorOf) {
                return 'hl.monitor({ output = "' + m.name + '", mode = "preferred", position = "auto", scale = 1, mirror = "' + m.mirrorOf + '" })';
            } else {
                let res = (m.width === m.nativeWidth && m.height === m.nativeHeight) ? "preferred" : (m.width + "x" + m.height + "@" + Math.round(m.refreshRate));
                let pos = (m.x !== undefined && m.y !== undefined) ? (m.x + "x" + m.y) : "auto";
                let sc = m.scale || 1.0;
                let trans = (m.transform !== undefined) ? m.transform : 0;
                return 'hl.monitor({ output = "' + m.name + '", mode = "' + res + '", position = "' + pos + '", scale = ' + sc + ', transform = ' + trans + ' })';
            }
        });

        let confLines = root.monitors.map(m => {
            if (m.disabled) {
                return 'monitor = ' + m.name + ',disable';
            } else if (m.mirrorOf) {
                return 'monitor = ' + m.name + ',preferred,auto,1,mirror,' + m.mirrorOf;
            } else {
                let res = (m.width === m.nativeWidth && m.height === m.nativeHeight) ? "preferred" : (m.width + "x" + m.height + "@" + Math.round(m.refreshRate));
                let pos = (m.x !== undefined && m.y !== undefined) ? (m.x + "x" + m.y) : "auto";
                let sc = m.scale || 1.0;
                let trans = (m.transform !== undefined) ? m.transform : 0;
                return 'monitor = ' + m.name + ',' + res + ',' + pos + ',' + sc + (trans ? (',transform,' + trans) : '');
            }
        });

        if (luaLines.length === 0) return;

        let headerLua = "-- Zenith display configuration - auto-generated";
        let scriptLua = 'printf "%s\\n" "' + headerLua + '" ' + luaLines.map(l => "'" + l + "'").join(" ") + ' > ~/.config/hypr/monitors.lua';
        let scriptConf = 'printf "%s\\n" "# Zenith display configuration - auto-generated" ' + confLines.map(l => "'" + l + "'").join(" ") + ' > ~/.config/hypr/monitors.conf';
        saveProc.command = ["sh", "-c", scriptLua + "; " + scriptConf];
        saveProc.running = false;
        saveProc.running = true;
    }

    Process { id: saveProc }

    Process {
        id: applyProc
        onExited: {
            refreshPollTimer.restart();
        }
    }

    Timer {
        id: refreshPollTimer
        interval: 350
        repeat: false
        onTriggered: {
            root.refresh();
        }
    }

    // Request resolution change with 10-second confirmation prompt
    function requestResolutionChange(monName, resHz) {
        let mon = null;
        for (let i = 0; i < root.monitors.length; i++) {
            if (root.monitors[i].name === monName) {
                mon = root.monitors[i];
                break;
            }
        }
        if (!mon) return;

        // If clicking already active resolution, do nothing
        if (isCurrentResolution(mon, resHz)) return;

        let targetMode = formatModeForHyprland(mon, resHz);
        let posVal = (mon.x !== undefined && mon.y !== undefined) ? (mon.x + "x" + mon.y) : "0x0";
        let scVal = mon.scale || 1.0;
        let transVal = mon.transform || 0;

        let oldMode = (mon.width === mon.nativeWidth && mon.height === mon.nativeHeight) ? "preferred" : (mon.width + "x" + mon.height + "@" + Math.round(mon.refreshRate));

        // Save pending change for revert
        root.pendingChange = {
            type: "resolution",
            output: monName,
            oldConfig: {
                output: monName,
                mode: oldMode,
                position: posVal,
                scale: scVal,
                transform: transVal
            },
            newTarget: resHz
        };

        // Apply immediately in Hyprland runtime
        applyLuaDirectives([{
            output: monName,
            mode: targetMode,
            position: posVal,
            scale: scVal,
            transform: transVal
        }]);

        // Start 10-second confirmation timer
        root.revertCountdown = 10;
        root.isConfirming = true;
        revertTimer.restart();
    }

    // Request scale change with 10-second confirmation prompt
    function requestScaleChange(monName, scaleVal) {
        let mon = null;
        for (let i = 0; i < root.monitors.length; i++) {
            if (root.monitors[i].name === monName) {
                mon = root.monitors[i];
                break;
            }
        }
        if (!mon) return;

        // If clicking already active scale, do nothing
        if (Math.abs((mon.scale || 1.0) - scaleVal) < 0.05) return;

        let resVal = (mon.width === mon.nativeWidth && mon.height === mon.nativeHeight) ? "preferred" : (mon.width + "x" + mon.height + "@" + Math.round(mon.refreshRate));
        let posVal = (mon.x !== undefined && mon.y !== undefined) ? (mon.x + "x" + mon.y) : "0x0";
        let oldScale = mon.scale || 1.0;
        let transVal = mon.transform || 0;

        let oldConfig = {
            output: monName,
            mode: resVal,
            position: posVal,
            scale: oldScale,
            transform: transVal
        };

        root.pendingChange = {
            type: "scale",
            output: monName,
            oldConfig: oldConfig,
            newTarget: scaleVal
        };

        // Apply immediately in Hyprland runtime
        applyLuaDirectives([{
            output: monName,
            mode: resVal,
            position: posVal,
            scale: scaleVal,
            transform: transVal
        }]);

        // Start 10-second confirmation timer
        root.revertCountdown = 10;
        root.isConfirming = true;
        revertTimer.restart();
    }

    // User accepts the change
    function keepChanges() {
        revertTimer.stop();
        root.isConfirming = false;
        persistMonitorsConfig();
        root.pendingChange = null;
        root.refresh();
    }

    // User reverts or 10-second timer expires
    function revertChanges() {
        revertTimer.stop();
        root.isConfirming = false;

        if (root.pendingChange && root.pendingChange.oldConfig) {
            applyLuaDirectives([root.pendingChange.oldConfig]);
        }
        root.pendingChange = null;
        persistMonitorsConfig();
        root.refresh();
    }

    // Direct set resolution (for compatibility)
    function setResolution(monName, resHz) {
        requestResolutionChange(monName, resHz);
    }

    // Direct set scale (for compatibility)
    function setScale(monName, scaleVal) {
        requestScaleChange(monName, scaleVal);
    }

    // Request transform / orientation change with 10-second confirmation prompt
    function requestTransformChange(monName, transVal) {
        let mon = null;
        for (let i = 0; i < root.monitors.length; i++) {
            if (root.monitors[i].name === monName) {
                mon = root.monitors[i];
                break;
            }
        }
        if (!mon) return;

        // If clicking already active transform, do nothing
        if ((mon.transform || 0) === transVal) return;

        let resVal = (mon.width === mon.nativeWidth && mon.height === mon.nativeHeight) ? "preferred" : (mon.width + "x" + mon.height + "@" + Math.round(mon.refreshRate));
        let posVal = (mon.x !== undefined && mon.y !== undefined) ? (mon.x + "x" + mon.y) : "0x0";
        let scVal = mon.scale || 1.0;
        let oldTrans = (mon.transform !== undefined) ? mon.transform : 0;

        let oldConfig = {
            output: monName,
            mode: resVal,
            position: posVal,
            scale: scVal,
            transform: oldTrans
        };

        root.pendingChange = {
            type: "orientation",
            output: monName,
            oldConfig: oldConfig,
            newTarget: transVal
        };

        // Apply immediately in Hyprland runtime
        applyLuaDirectives([{
            output: monName,
            mode: resVal,
            position: posVal,
            scale: scVal,
            transform: transVal
        }]);

        // Start 10-second confirmation timer
        root.revertCountdown = 10;
        root.isConfirming = true;
        revertTimer.restart();
    }

    // Direct set transform (for compatibility)
    function setTransform(monName, transVal) {
        requestTransformChange(monName, transVal);
    }

    // Multi-Monitor / Projector Presets
    function setPreset(preset) {
        root.activePreset = preset;

        let intMon = null;
        let extMon = null;

        for (let i = 0; i < root.monitors.length; i++) {
            if (root.monitors[i].isInternal && !intMon) {
                intMon = root.monitors[i];
            } else if (!extMon) {
                extMon = root.monitors[i];
            }
        }

        if (!intMon && root.monitors.length > 0) intMon = root.monitors[0];
        if (!extMon && root.monitors.length > 1) extMon = root.monitors[1];

        if (!intMon) return;

        let configs = [];

        if (preset === "extend") {
            configs.push({ output: intMon.name, mode: "preferred", position: "0x0", scale: (intMon.scale || 1.0) });
            if (extMon) {
                configs.push({ output: extMon.name, mode: "preferred", position: "auto", scale: (extMon.scale || 1.0) });
            }
        } else if (preset === "mirror") {
            // Projector mode: external/projector mirrors internal display
            configs.push({ output: intMon.name, mode: "preferred", position: "0x0", scale: (intMon.scale || 1.0) });
            if (extMon) {
                configs.push({ output: extMon.name, mode: "preferred", position: "auto", scale: 1, mirror: intMon.name });
            }
        } else if (preset === "secondOnly") {
            // External screen only (e.g. docked or projector presentation)
            configs.push({ output: intMon.name, disabled: true });
            if (extMon) {
                configs.push({ output: extMon.name, mode: "preferred", position: "0x0", scale: (extMon.scale || 1.0) });
            }
        } else if (preset === "internalOnly") {
            // Built-in laptop screen only
            configs.push({ output: intMon.name, mode: "preferred", position: "0x0", scale: (intMon.scale || 1.0) });
            if (extMon) {
                configs.push({ output: extMon.name, disabled: true });
            }
        }

        applyLuaDirectives(configs);
        persistMonitorsConfig();
    }
}
