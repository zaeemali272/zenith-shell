import QtQuick
import Quickshell.Io
import Quickshell.Services.Notifications
pragma Singleton

Item {
    id: root

    property alias notifications: historyModel
    // Added property to track the last notification content
    property string lastNotifKey: ""

    signal notificationReceived(var notifData)
    signal osdReceived(string type, real value)

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
                break; // Stop once we found and removed it
            }
        }
    }

    // Timer to reset the duplicate guard so you can receive the same notif later
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

        onNotification: (notif) => {
            // Using corrected icon path

            let syncHint = getSafeHint("x-canonical-private-synchronous");
            let category = getSafeHint("category") || notif.category || "";
            // --- OSD DETECTION ---
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
            // --- DUPLICATE PREVENTION ---
            let currentKey = notif.summary + "|" + notif.body + "|" + notif.appName;
            if (currentKey === root.lastNotifKey) {
                notif.dismiss();
                return ;
            }
            root.lastNotifKey = currentKey;
            duplicateResetTimer.restart();
            // --- ICON PATH CORRECTION ---
            let rawIcon = notif.appIcon || getSafeHint("image-path") || getSafeHint("image_path") || "";
            let finalIcon = "";
            if (rawIcon !== "") {
                if (rawIcon.startsWith("/") || rawIcon.startsWith("file://"))
                    finalIcon = rawIcon.startsWith("file://") ? rawIcon : "file://" + rawIcon;
                else
                    // This allows QML to find themed icons like "kdeconnect" or "firefox"
                    finalIcon = "image://icon/" + rawIcon;
            }
            // --- STANDARD NOTIFICATIONS ---
            let notifData = {
                "id": Date.now() + Math.random(),
                "summary": notif.summary || "",
                "body": notif.body || "",
                "appIcon": finalIcon,
                "appName": notif.appName || "System",
                "originalNotif": notif
            };
            historyModel.insert(0, notifData);
            root.notificationReceived(notifData);
        }

        function getSafeHint(key) {
            let h = notif.hints[key];
            if (!h)
                return "";

            if (typeof h === "object")
                return h.string || (h.value !== undefined ? h.value.toString() : "");

            return h.toString();
        }

    }

}
