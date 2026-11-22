pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

QtObject {
    id: root

    property bool nightLight: false
    property int nightLightTemp: 3800
    readonly property int nightLightIntensity: Math.max(0, Math.min(100, Math.round(((6500 - nightLightTemp) / 4500) * 100)))

    readonly property string nlCacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zenith"
    readonly property string nlStateTempPath: nlCacheDir + "/nightlight_temp.txt"
    readonly property string nlStateEnabledPath: nlCacheDir + "/nightlight_enabled.txt"

    property bool dnd: false
    property bool micMuted: false

    readonly property bool caffeineActive: CaffeineService.active

    function toggleCaffeine() {
        CaffeineService.toggle();
    }

    function toggleDnd() {
        dnd = !dnd;
        notifyProc.command = ["notify-send", "-a", "Do Not Disturb", "-i", "notifications-disabled",
            dnd ? "Do Not Disturb Enabled" : "Do Not Disturb Disabled",
            dnd ? "Notification popups silenced." : "Normal notification popups resumed."];
        notifyProc.running = true;
    }

    function setNightLightIntensity(intensity) {
        let i = Math.max(5, Math.min(100, intensity));
        let kelvin = Math.round(6500 - (i / 100) * 4500);
        kelvin = Math.round(kelvin / 50) * 50;
        setNightLightTemperature(kelvin);
    }

    function setNightLightTemperature(kelvin) {
        let k = Math.max(2000, Math.min(6000, kelvin));
        nightLightTemp = k;
        saveNlTemp();
        if (nightLight) {
            nlDebounceTimer.restart();
        }
    }

    function toggleNightLight() {
        if (nightLight) {
            disableNightLight();
        } else {
            enableNightLight();
        }
    }

    function enableNightLight() {
        nightLight = true;
        nlProc.command = ["sh", "-c", "if command -v hyprsunset >/dev/null 2>&1; then pgrep -f '(^|/)hyprsunset' >/dev/null || (setsid hyprsunset --identity </dev/null >/dev/null 2>&1 & sleep 0.15); hyprctl hyprsunset temperature " + root.nightLightTemp + " >/dev/null 2>&1 || true; else PIDS=$(pidof .gammastep-wrapped gammastep 2>/dev/null); [ -n \"$PIDS\" ] && kill -TERM $PIDS 2>/dev/null; gammastep -O " + root.nightLightTemp + " >/dev/null 2>&1 & fi; echo 1 > " + nlStateEnabledPath];
        nlProc.running = true;
    }

    function disableNightLight() {
        nightLight = false;
        nlProc.command = ["sh", "-c", "hyprctl hyprsunset identity >/dev/null 2>&1 || true; PIDS=$(pidof .gammastep-wrapped gammastep 2>/dev/null); [ -n \"$PIDS\" ] && kill -TERM $PIDS 2>/dev/null || true; echo 0 > " + nlStateEnabledPath];
        nlProc.running = true;
    }

    property Timer nlDebounceTimer: Timer {
        interval: 35
        repeat: false
        onTriggered: {
            if (root.nightLight) {
                nlProc.command = ["sh", "-c", "if command -v hyprsunset >/dev/null 2>&1; then pgrep -f '(^|/)hyprsunset' >/dev/null || (setsid hyprsunset --identity </dev/null >/dev/null 2>&1 & sleep 0.15); hyprctl hyprsunset temperature " + root.nightLightTemp + " >/dev/null 2>&1 || true; else PIDS=$(pidof .gammastep-wrapped gammastep 2>/dev/null); [ -n \"$PIDS\" ] && kill -TERM $PIDS 2>/dev/null; gammastep -O " + root.nightLightTemp + " >/dev/null 2>&1 & fi"];
                nlProc.running = true;
            }
        }
    }

    function saveNlTemp() {
        saveNlProc.command = ["sh", "-c", "mkdir -p " + nlCacheDir + "; echo " + nightLightTemp + " > " + nlStateTempPath + " 2>/dev/null || true"];
        saveNlProc.running = true;
    }

    function loadNlState() {
        loadNlProc.command = ["sh", "-c", "cat " + nlStateTempPath + " 2>/dev/null || echo 3800"];
        loadNlProc.running = true;
        checkNlStateProc.command = ["sh", "-c", "cat " + nlStateEnabledPath + " 2>/dev/null || echo 0"];
        checkNlStateProc.running = true;
    }

    function toggleMicMute() {
        micProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"];
        micProc.running = true;
        Qt.callLater(() => refreshMicState());
    }

    function refreshMicState() {
        checkMicProc.command = ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true"];
        checkMicProc.running = true;
        checkNlProc.command = ["sh", "-c", "if [ -f " + nlStateEnabledPath + " ]; then [ \"$(cat " + nlStateEnabledPath + " 2>/dev/null)\" = '1' ] && echo 'RUNNING' || echo 'STOPPED'; elif pidof .gammastep-wrapped gammastep >/dev/null 2>&1; then echo 'RUNNING'; else echo 'STOPPED'; fi"];
        checkNlProc.running = true;
    }

    function triggerScreenshot(mode) {
        MenuService.closeAll();
        let m = mode || "region";
        let script = PathSettings.home + "/.config/hypr/hyprland/scripts/screenshot.sh";
        // Give 250ms for menus to dismiss cleanly
        delayTimer.callback = () => {
            toolProc.command = ["sh", "-c", "if [ -x \"" + script + "\" ]; then \"" + script + "\" " + m + "; else grim -g \"$(slurp)\" - | wl-copy; fi"];
            toolProc.running = true;
        };
        delayTimer.restart();
    }

    function triggerColorPicker() {
        MenuService.closeAll();
        delayTimer.callback = () => {
            toolProc.command = ["sh", "-c", "COLOR=$(hyprpicker -a) && [ -n \"$COLOR\" ] && notify-send -a 'Color Picker' -i 'color-picker' 'Color Copied' \"Hex: $COLOR\""];
            toolProc.running = true;
        };
        delayTimer.restart();
    }

    property Timer delayTimer: Timer {
        id: delayTimer
        interval: 220
        repeat: false
        property var callback: null
        onTriggered: {
            if (callback) callback();
        }
    }

    // Process runners
    property Process toolProc: Process { id: toolProc }
    property Process notifyProc: Process { id: notifyProc }
    property Process nlProc: Process { id: nlProc }
    property Process micProc: Process { id: micProc }
    property Process saveNlProc: Process { id: saveNlProc }
    property Process loadNlProc: Process {
        id: loadNlProc
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim(), 10);
                if (!isNaN(val) && val >= 1500 && val <= 6500) {
                    root.nightLightTemp = val;
                }
            }
        }
    }
    property Process checkNlStateProc: Process {
        id: checkNlStateProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "1") {
                    root.nightLight = true;
                }
            }
        }
    }

    property Process checkMicProc: Process {
        id: checkMicProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.micMuted = text.includes("[MUTED]");
            }
        }
    }

    property Process checkNlProc: Process {
        id: checkNlProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.nightLight = text.trim() === "RUNNING";
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshMicState()
    }

    Component.onCompleted: {
        loadNlState();
    }
}
