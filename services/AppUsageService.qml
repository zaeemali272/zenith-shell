pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: service

    property string storagePath: Quickshell.env("HOME") + "/.config/quickshell/app_usage.json"
    property var usageData: ({}) // appId -> { count: N, totalSeconds: N, lastFocus: timestamp }
    property string activeAppId: ""
    property var lastFocusTime: Date.now()

    Component.onCompleted: {
        load();
        trackFocus();
    }

    function load() {
        let text = Quickshell.Io.readFile(storagePath);
        if (text) {
            try { usageData = JSON.parse(text); } catch(e) { usageData = {}; }
        }
    }

    function trackFocus() {
        // Track the currently focused app
        let win = Hyprland.activeWindow;
        let appId = win ? win.class : "";
        
        if (appId !== activeAppId) {
            // Update time for the previous app
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

        let countScore = data.count || 0;
        let totalSeconds = data.totalSeconds || 0;

        // Priority Score: 50% frequency, 50% active duration
        return (countScore * 10) + (totalSeconds / 60); 
    }

    function save() {
        let dataStr = JSON.stringify(usageData);
        Quickshell.Io.writeFile(storagePath, dataStr);
    }

    // Monitor focus changes efficiently
    Connections {
        target: Hyprland
        function onActiveWindowChanged() { service.trackFocus(); }
    }
}
