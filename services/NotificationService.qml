import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
pragma Singleton

Item {
    id: root

    property alias notifications: historyModel
    property string lastNotifKey: ""

    signal notificationReceived(var notifData)
    signal notificationDismissed(real id)
    signal osdReceived(string type, real value)

    // Helper to format icon names into various possible system paths
    function getHardcodedPath(iconName) {
        if (!iconName) return "";
        if (iconName.startsWith("file://") || iconName.startsWith("image://"))
            return iconName;
            
        if (iconName.startsWith("/"))
            return "file://" + iconName;

        // If it's a battery icon, we know where they are
        if (iconName.startsWith("battery-")) {
            return "file:///usr/share/icons/OneUI/symbolic/status/" + iconName + ".svg";
        }

        return iconName;
    }

    function updateOSDValue(type, value) {
        let percent = Math.round(value * 100);
        if (type === "volume")
            shellExec.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", percent + "%"];
        else if (type === "brightness")
            shellExec.command = ["brightnessctl", "set", percent + "%"];
        shellExec.running = false;
        shellExec.running = true;
    }

    function clearAll() {
        for (let i = 0; i < historyModel.count; i++) {
            let n = historyModel.get(i);
            if (n.originalNotif)
                n.originalNotif.dismiss();
        }
        historyModel.clear();
    }

    function removeNotification(notifId) {
        for (let i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).id === notifId) {
                historyModel.remove(i);
                break;
            }
        }
        root.notificationDismissed(notifId);
    }

    function dismissNotification(notifId) {
        root.notificationDismissed(notifId);
    }

    Timer {
        id: duplicateResetTimer
        interval: 5000
        onTriggered: root.lastNotifKey = ""
    }

    ListModel {
        id: historyModel
    }

    Process {
        id: shellExec
    }

    NotificationServer {
        id: server
        imageSupported: true

        onNotification: (notif) => {
            // OSD Filtering
            let syncHint = notif.hints["x-canonical-private-synchronous"] || "";
            let category = notif.hints["category"] || notif.category || "";
            
            if (syncHint === "volume" || syncHint === "brightness" || category === "volume" || category === "brightness") {
                let type = (syncHint === "volume" || category === "volume") ? "volume" : "brightness";
                let text = (notif.summary || "") + " " + (notif.body || "");
                let match = text.match(/(\d+)%/);
                let isMuted = text.toLowerCase().includes("muted") || text.toLowerCase().includes("mute");
                if (match || isMuted) {
                    let val = isMuted ? 0 : (parseInt(match[1]) / 100);
                    root.osdReceived(type, val);
                    notif.dismiss();
                    return ;
                }
            }

            // Duplicate Filtering
            let isBattery = (notif.appName === "Battery");
            let isCaffeine = (notif.appName === "Caffeine");
            if (!isBattery && !isCaffeine) {
                let currentKey = notif.summary + "|" + notif.body + "|" + notif.appName;
                for (let i = 0; i < historyModel.count; i++) {
                    let item = historyModel.get(i);
                    if (item.summary === notif.summary && item.body === notif.body && item.appName === notif.appName) {
                        notif.dismiss();
                        return ;
                    }
                }
                root.lastNotifKey = currentKey;
                duplicateResetTimer.restart();
            }

            // Icon Resolution via Unified IconsFetcher Pipeline
            let finalIcon = "";
            let rawIcon = notif.appIcon || "";
            
            // If appIcon is empty but image is an image://icon URL, extract the name
            if (rawIcon === "" && notif.image && notif.image.startsWith("image://icon/")) {
                rawIcon = notif.image.substring(13);
            }

            // Priority 1: Raw image or direct file path payload
            if (notif.image && notif.image !== "") {
                if (notif.image.startsWith("/") || notif.image.startsWith("file://")) {
                    finalIcon = notif.image.startsWith("file://") ? notif.image : "file://" + notif.image;
                } else {
                    finalIcon = notif.image;
                }
            } 
            // Priority 2: Try explicit hardcoded mappings first (like status/battery icons)
            else if (rawIcon !== "") {
                let hardPath = root.getHardcodedPath(rawIcon);
                if (hardPath !== rawIcon) {
                    finalIcon = hardPath;
                }
            }

            // Priority 3: Fallback seamlessly to IconsFetcher mechanism
            if (finalIcon === "") {
                let lookupName = rawIcon !== "" ? rawIcon : (notif.appName || "dialog-information").toLowerCase().replace(/\s+/g, '-');
                finalIcon = IconsFetcher.getValidIcon(notif.appName || "", notif.desktopEntry || "", lookupName);
            }

            let notifData = {
                "id": Date.now() + Math.random(),
                "summary": notif.summary || "",
                "body": notif.body || "",
                "appIcon": finalIcon,
                "rawIcon": rawIcon,
                "appName": notif.appName || "System",
                "desktopEntry": notif.desktopEntry || "",
                "originalNotif": notif
            };

            if (!isBattery && !isCaffeine) {
                historyModel.insert(0, notifData);
            }
            root.notificationReceived(notifData);
        }
    }
}