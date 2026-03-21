import ".."
import QtQuick
import Quickshell.Io
import Quickshell.Services.Notifications
pragma Singleton

Item {
    id: root

    property alias notifications: historyModel
    property string lastNotifKey: ""

    signal notificationReceived(var notifData)
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
    }

    Timer {
        id: duplicateResetTimer

        interval: 3000
        onTriggered: root.lastNotifKey = ""
    }

    ListModel {
        id: historyModel
    }

    Process {
        id: shellExec
    }

    NotificationServer {
        // Secondary fallback if Priority 3/4 fails (Checkerboard prevention)

        id: server

        function getSafeHint(notif, key) {
            let h = notif.hints[key];
            if (!h)
                return "";

            if (typeof h === "object")
                return h.string || (h.value !== undefined ? h.value.toString() : "");

            return h.toString();
        }

        onNotification: (notif) => {
            let syncHint = getSafeHint(notif, "x-canonical-private-synchronous");
            let category = getSafeHint(notif, "category") || notif.category || "";
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
            let currentKey = notif.summary + "|" + notif.body + "|" + notif.appName;
            // Check the entire history for duplicates
            for (let i = 0; i < historyModel.count; i++) {
                let item = historyModel.get(i);
                if (item.summary === notif.summary && item.body === notif.body && item.appName === notif.appName) {
                    // Duplicate found anywhere in history, discard the new one
                    notif.dismiss();
                    return ;
                }
            }
            root.lastNotifKey = currentKey;
            duplicateResetTimer.restart();
            // --- IMPROVED ICON LOGIC ---
            let finalIcon = "";
            let imageHint = notif.hints["image-data"] || notif.hints["image_data"] || notif.hints["icon_data"];
            let rawIcon = notif.appIcon || getSafeHint(notif, "image-path") || getSafeHint(notif, "image_path") || "";
            if (imageHint) {
                finalIcon = "image://notification/" + notif.id;
            } else if (rawIcon !== "") {
                if (rawIcon.startsWith("/") || rawIcon.startsWith("file://"))
                    finalIcon = rawIcon.startsWith("file://") ? rawIcon : "file://" + rawIcon;
                else
                    // Try the themed icon first
                    finalIcon = "image://icon/" + rawIcon;
            }
            // If finalIcon is still empty, or to ensure we have a "safe" string for the model:
            if (finalIcon === "") {
                let fallback = (notif.appName || "dialog-information").toLowerCase().replace(/\s+/g, '-');
                finalIcon = "image://icon/" + fallback;
            }
            let notifData = {
                "id": Date.now() + Math.random(),
                "summary": notif.summary || "",
                "body": notif.body || "",
                "appIcon": finalIcon,
                "rawIcon": rawIcon,
                "appName": notif.appName || "System",
                "originalNotif": notif
            };
            historyModel.insert(0, notifData);
            root.notificationReceived(notifData);
        }
    }

}
