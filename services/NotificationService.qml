import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../windows" as Win
import "../Settings"

pragma Singleton

Item {
    id: root

    property alias notifications: historyModel
    property string lastNotifKey: ""
    property var liveNotifs: ({})
    property bool _initialized: false

    Timer {
        id: initTimer
        interval: 1500
        running: true
        onTriggered: root._initialized = true
    }

    signal notificationReceived(var notifData)
    signal notificationDismissed(real id)
    signal osdReceived(string type, real value)

    function updateOSDValue(type, value) {
        let percent = Math.max(0, Math.min(150, Math.round(value * 100)));
        if (type === "volume")
            shellExec.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", percent + "%"];
        else if (type === "brightness")
            shellExec.command = ["brightnessctl", "-c", "backlight", "set", Math.max(1, Math.min(100, percent)) + "%"];
        else if (type === "mic")
            shellExec.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", percent + "%"];
        shellExec.running = false;
        shellExec.running = true;
    }

    function clearAll() {
        for (let i = 0; i < historyModel.count; i++) {
            let n = historyModel.get(i);
            if (n && n.originalNotif) {
                try { n.originalNotif.dismiss(); } catch(e) {}
            }
        }
        historyModel.clear();
        root.liveNotifs = ({});
    }

    function removeNotification(notifId) {
        for (let i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).id === notifId) {
                historyModel.remove(i);
                break;
            }
        }
        delete root.liveNotifs[notifId];
        root.notificationDismissed(notifId);
    }

    function dismissNotification(notifId) {
        let n = root.liveNotifs[notifId];
        if (n) {
            try { n.dismiss(); } catch(e) {}
        }
        delete root.liveNotifs[notifId];
        root.notificationDismissed(notifId);
    }

    function performAction(data) {
        if (!data) return;
        let script = PathSettings.scriptsDir + "/notification_action.py";
        let payload = JSON.stringify({
            "appName": data.appName || "",
            "desktopEntry": data.desktopEntry || "",
            "summary": data.summary || "",
            "body": data.body || "",
            "image": data.image || "",
            "icon": data.rawIcon || data.appIcon || "",
            "pid": data.pid || (data.hints ? (data.hints["sender-pid"] || data.hints["pid"]) : 0) || 0,
            "hints": data.hints || ({})
        });
        actionExec.command = ["python3", script, payload];
        actionExec.running = false;
        actionExec.running = true;
        if (Variables.controlCenterOpen) {
            CenterState.close();
        }
    }

    function invokeAction(notifId, actionId, fallbackData) {
        let n = root.liveNotifs[notifId];
        let notifData = fallbackData || null;
        if (!notifData) {
            for (let i = 0; i < historyModel.count; i++) {
                let item = historyModel.get(i);
                if (item && item.id === notifId) {
                    notifData = item;
                    break;
                }
            }
        }
        if (!n && notifData && notifData.originalNotif) {
            n = notifData.originalNotif;
        }

        if (n && n.actions) {
            for (let i = 0; i < n.actions.length; i++) {
                let act = n.actions[i];
                if (act && act.identifier === actionId) {
                    try { act.invoke(); } catch(e) {}
                    break;
                }
            }
        }
        if (n && typeof n.invokeAction === "function") {
            try { n.invokeAction(actionId); } catch(e) {}
        }

        let actLower = (actionId || "").toLowerCase();
        if (actLower === "default" || actLower === "open" || actLower === "view" || actLower.includes("show") || actLower.includes("folder") || (notifData && (notifData.appName === "Screenshot" || notifData.appName === "Recorder"))) {
            if (notifData) performAction(notifData);
            else if (n) performAction({
                "appName": n.appName || "",
                "desktopEntry": n.desktopEntry || "",
                "summary": n.summary || "",
                "body": n.body || "",
                "image": n.image || "",
                "icon": n.appIcon || "",
                "hints": n.hints || ({})
            });
        }

        if (n) {
            try { n.dismiss(); } catch(e) {}
        }
        removeNotification(notifId);
    }

    function invokeDefault(notifId, fallbackData) {
        let n = root.liveNotifs[notifId];
        let notifData = fallbackData || null;
        if (!notifData) {
            for (let i = 0; i < historyModel.count; i++) {
                let item = historyModel.get(i);
                if (item && item.id === notifId) {
                    notifData = item;
                    break;
                }
            }
        }
        if (!n && notifData && notifData.originalNotif) {
            n = notifData.originalNotif;
        }

        if (n) {
            let invoked = false;
            if (n.actions) {
                for (let i = 0; i < n.actions.length; i++) {
                    let act = n.actions[i];
                    if (act && act.identifier === "default") {
                        try { act.invoke(); } catch(e) {}
                        invoked = true;
                        break;
                    }
                }
            }
            if (!invoked && typeof n.invokeAction === "function") {
                try { n.invokeAction("default"); } catch(e) {}
            }
            try { n.dismiss(); } catch(e) {}
        }

        if (notifData) {
            performAction(notifData);
        } else if (n) {
            performAction({
                "appName": n.appName || "",
                "desktopEntry": n.desktopEntry || "",
                "summary": n.summary || "",
                "body": n.body || "",
                "image": n.image || "",
                "icon": n.appIcon || "",
                "hints": n.hints || ({})
            });
        }

        removeNotification(notifId);
    }

    function sendReply(notifId, replyText) {
        let n = root.liveNotifs[notifId];
        if (n && typeof n.sendInlineReply === "function") {
            try { n.sendInlineReply(replyText); } catch(e) {}
        }
        if (n) {
            try { n.dismiss(); } catch(e) {}
        }
        removeNotification(notifId);
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

    Process {
        id: actionExec
    }

    // Dynamic OSD triggers from volume and brightness hotkeys
    Connections {
        target: VolumeService
        function onOutputVolumeChanged() {
            if (root._initialized && !Variables.quickSettingsOpen && !Variables.controlCenterOpen) {
                root.osdReceived("volume", VolumeService.muted ? 0 : (VolumeService.outputVolume / 100));
            }
        }
        function onMutedChanged() {
            if (root._initialized && !Variables.quickSettingsOpen && !Variables.controlCenterOpen) {
                root.osdReceived("volume", VolumeService.muted ? 0 : (VolumeService.outputVolume / 100));
            }
        }
        function onMicMutedChanged() {
            if (root._initialized && !Variables.quickSettingsOpen && !Variables.controlCenterOpen) {
                root.osdReceived("mic", VolumeService.micMuted ? 0 : 1);
            }
        }
    }

    Connections {
        target: BrightnessService
        function onPercentageChanged() {
            if (root._initialized && !Variables.quickSettingsOpen && !Variables.controlCenterOpen) {
                root.osdReceived("brightness", BrightnessService.percentage / 100);
            }
        }
    }

    NotificationServer {
        id: server
        actionsSupported: true
        actionIconsSupported: true
        inlineReplySupported: true
        imageSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        persistenceSupported: true

        onNotification: (notif) => {
            // OSD Filtering
            let syncHint = notif.hints["x-canonical-private-synchronous"] || notif.hints["synchronous"] || "";
            let category = notif.hints["category"] || notif.category || "";
            
            if (syncHint === "volume" || syncHint === "brightness" || syncHint === "mic" ||
                category === "volume" || category === "brightness" || category === "mic") {
                let type = (syncHint === "volume" || category === "volume") ? "volume" :
                           (syncHint === "mic" || category === "mic") ? "mic" : "brightness";
                let text = (notif.summary || "") + " " + (notif.body || "");
                let match = text.match(/(\d+)%/);
                let isMuted = text.toLowerCase().includes("muted") || text.toLowerCase().includes("mute");
                let val = 0;
                if (notif.hints["value"] !== undefined) {
                    val = Number(notif.hints["value"]) / 100;
                } else if (match) {
                    val = parseInt(match[1]) / 100;
                } else if (isMuted) {
                    val = 0;
                }
                root.osdReceived(type, val);
                try { notif.dismiss(); } catch(e) {}
                return;
            }

            // Duplicate Filtering
            let isBattery = (notif.appName === "Battery");
            let isCaffeine = (notif.appName === "Caffeine");
            if (!isBattery && !isCaffeine) {
                let currentKey = notif.summary + "|" + notif.body + "|" + notif.appName;
                for (let i = 0; i < historyModel.count; i++) {
                    let item = historyModel.get(i);
                    if (item.summary === notif.summary && item.body === notif.body && item.appName === notif.appName) {
                        try { notif.dismiss(); } catch(e) {}
                        return;
                    }
                }
                root.lastNotifKey = currentKey;
                duplicateResetTimer.restart();
            }

            // Dynamic Icon Candidate Resolution via IconsFetcher
            let rawIcon = notif.appIcon || "";
            let rawImg = notif.image || "";
            if (!rawImg && notif.hints) {
                rawImg = notif.hints["image-path"] || notif.hints["image_path"] || notif.hints["image-data"] || "";
            }

            let candidates = [];
            if (rawImg !== "") {
                candidates.push(rawImg.startsWith("file://") || rawImg.startsWith("/") ? (rawImg.startsWith("file://") ? rawImg : "file://" + rawImg) : rawImg);
            }

            let fetcherCandidates = Win.IconsFetcher.getIconCandidates(notif.appName || "", notif.desktopEntry || "", rawIcon);
            for (let cand of fetcherCandidates) {
                candidates.push(cand);
            }

            let validCandidates = candidates.filter((v, i, a) => v && v !== "" && a.indexOf(v) === i);

            // Extract Actions (excluding default action)
            let actionsList = [];
            if (notif.actions) {
                for (let i = 0; i < notif.actions.length; i++) {
                    let act = notif.actions[i];
                    if (act && act.identifier && act.identifier !== "default") {
                        actionsList.push({
                            "identifier": act.identifier,
                            "text": act.text || act.identifier
                        });
                    }
                }
            }

            let notifId = notif.id ? notif.id : (Date.now() + Math.random());
            let now = new Date();
            let timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

            let notifData = {
                "id": notifId,
                "summary": notif.summary || "",
                "body": notif.body || "",
                "appIcon": validCandidates.length > 0 ? validCandidates[0] : "",
                "iconCandidates": validCandidates,
                "rawIcon": rawIcon,
                "image": rawImg,
                "appName": notif.appName || "System",
                "desktopEntry": notif.desktopEntry || "",
                "urgency": notif.urgency !== undefined ? notif.urgency : 1,
                "timeStr": timeStr,
                "hasInlineReply": Boolean(notif.hasInlineReply),
                "inlineReplyPlaceholder": notif.inlineReplyPlaceholder || "Reply...",
                "actions": actionsList,
                "hints": notif.hints || ({}),
                "pid": (notif.hints && (notif.hints["sender-pid"] || notif.hints["pid"])) || 0,
                "originalNotif": notif
            };

            root.liveNotifs[notifId] = notif;

            if (!isBattery && !isCaffeine) {
                historyModel.insert(0, notifData);
            }
            if (!PowerToolsService.dnd) {
                root.notificationReceived(notifData);
            }
        }
    }
}
