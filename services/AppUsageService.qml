pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: service

    property string storagePath: Quickshell.env("HOME") + "/.config/quickshell/app_usage.json"
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
        if (!usageData[appId]) {
            usageData[appId] = { count: 0, totalSeconds: 0, lastFocus: 0 };
        }
        usageData[appId].totalSeconds += Math.round(durationMs / 1000);
        usageData[appId].lastFocus = Date.now();
        save();
    }

    function recordLaunch(appId) {
        if (!usageData[appId]) {
            usageData[appId] = { count: 0, totalSeconds: 0, lastFocus: 0 };
        }
        usageData[appId].count += 1;
        save();
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
            if (event.name === "activewindow") service.trackFocus();
        }
    }
}
