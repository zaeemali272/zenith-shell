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
        if (!iconName || iconName.startsWith("/") || iconName.startsWith("image://"))
            return "";

        // List of base paths to check if themed lookup fails
        // We prioritize OneUI since you know they are there
        const bases = ["/usr/share/icons/OneUI/24/actions/", "/usr/share/icons/OneUI/symbolic/actions/", "/usr/share/icons/Adwaita/symbolic/actions/"];
        // This is a bit "hacky" but works when the theme index is broken
        // Note: QML Image can take raw paths.
        return iconName;
    }

    function updateOSDValue(type, value) {
        let percent = Math.round(value * 100);
        if (type === "volume")
            shellExec.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", percent + "%"];
        else if (type === "brightness")
            shellExec.command = ["brightnessctl", "set", percent + "%"];
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
            let currentKey = notif.summary + "|" + notif.body + "|" + notif.appName;
            if (notif.appName !== "Battery") {
                for (let i = 0; i < historyModel.count; i++) {
                    let item = historyModel.get(i);
                    if (item.summary === notif.summary && item.body === notif.body && item.appName === notif.appName) {
                        notif.dismiss();
                        return ;
                    }
                }
            }
            root.lastNotifKey = currentKey;
            duplicateResetTimer.restart();

            // Icon Resolution
            let finalIcon = "";
            let rawIcon = notif.appIcon || "";
            
            // If appIcon is empty but image is an image://icon URL, extract the name
            if (rawIcon === "" && notif.image && notif.image.startsWith("image://icon/")) {
                rawIcon = notif.image.substring(13);
            }

            // Priority 1: Raw image or direct path from Quickshell (notif.image)
            if (notif.image && notif.image !== "") {
                finalIcon = notif.image;
            } 
            // Priority 2: Themed icon name (notif.appIcon)
            else if (notif.appIcon && notif.appIcon !== "") {
                if (notif.appIcon.startsWith("/") || notif.appIcon.startsWith("file://")) {
                    finalIcon = notif.appIcon.startsWith("file://") ? notif.appIcon : "file://" + notif.appIcon;
                } else {
                    finalIcon = Quickshell.iconPath(notif.appIcon);
                }
            }
            
            // Priority 3: Fallback based on app name
            if (finalIcon === "") {
                let fallback = (notif.appName || "dialog-information").toLowerCase().replace(/\s+/g, '-');
                finalIcon = Quickshell.iconPath(fallback);
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
            historyModel.insert(0, notifData);
            root.notificationReceived(notifData);
        }
    }

}
