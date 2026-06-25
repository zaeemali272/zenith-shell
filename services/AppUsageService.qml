import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../Settings"

pragma Singleton

Item {
    id: service

    property string storagePath: PathSettings.configDir + "/quickshell/app_usage.json"
    property var usageData: ({})
    property string activeAppId: ""
    property var lastFocusTime: Date.now()

    Component.onCompleted: {
        load();
        trackFocus();
    }

    // Declarative Loader
    Process {
        id: loadProc
        command: ["cat", storagePath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text) usageData = JSON.parse(text);
                } catch(e) { usageData = {}; }
            }
        }
        onRunningChanged: if (running) {}
    }

    function load() {
        loadProc.running = true;
    }

    function trackFocus() {
        let win = Hyprland.activeWindow;
        let appId = (win && win.class) ? win.class : "";
        
        if (!usageData) usageData = {};
        
        if (appId !== activeAppId) {
            if (activeAppId !== "") {
                updateUsage(activeAppId, Date.now() - lastFocusTime);
            }
            activeAppId = appId;
            lastFocusTime = Date.now();
        }
    }

    function updateUsage(appId, durationMs) {
        if (!appId) return;
        let data = JSON.parse(JSON.stringify(usageData));
        if (!data[appId]) {
            data[appId] = { count: 0, totalSeconds: 0, lastFocus: 0 };
        }
        data[appId].totalSeconds += Math.round(durationMs / 1000);
        data[appId].lastFocus = Date.now();
        usageData = data;
        save();
    }

    function recordLaunch(appId) {
        if (!appId) return;
        let data = JSON.parse(JSON.stringify(usageData));
        if (!data[appId]) {
            data[appId] = { count: 0, totalSeconds: 0, lastFocus: 0 };
        }
        data[appId].count += 1;
        usageData = data;
        save();
    }

    // Periodic update for active app
    Timer {
        interval: 10000 // Update every 10 seconds
        running: true
        repeat: true
        onTriggered: {
            if (activeAppId !== "") {
                let now = Date.now();
                updateUsage(activeAppId, now - lastFocusTime);
                lastFocusTime = now;
            }
        }
    }

    function getScore(appId) {
        if (!usageData) return 0;
        let data = usageData[appId];
        if (!data) return 0;
        return (data.count * 10) + (data.totalSeconds / 60); 
    }

    Process {
        id: saveProc
        command: ["sh", "-c", ""]
    }

    function save() {
        let dataStr = JSON.stringify(usageData).replace(/'/g, "'\\''");
        saveProc.command = ["sh", "-c", "mkdir -p $(dirname " + storagePath + ") && echo '" + dataStr + "' > " + storagePath];
        saveProc.running = true;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow") {
                service.trackFocus();
            }
        }
    }
}
