// services/VolumeService.qml
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: service

    property int outputVolume: 0
    property int micVolume: 0
    property bool muted: false
    property bool micMuted: false 
    property bool micActive: false
    property bool btActive: false
    readonly property alias appsModel: appModel

    function update() {
        updateTimer.restart();
    }

    function _performUpdate() {
        volExec.running = false;
        volExec.running = true;
        appVolExec.running = false;
        appVolExec.running = true;
    }

    Timer {
        id: updateTimer
        interval: 200
        onTriggered: _performUpdate()
    }

    Component.onCompleted: _performUpdate()

    ListModel {
        id: appModel
    }

    Process {
        id: appVolExec
        command: ["pactl", "-f", "json", "list", "sink-inputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    const data = JSON.parse(text);
                    if (!Array.isArray(data)) {
                        if (data && typeof data === "object") {
                            processData([data]);
                        }
                        return;
                    }
                    processData(data);
                } catch (e) {}
            }
        }
    }

    function processData(data) {
        let currentIds = new Set();
        for (let i = 0; i < data.length; i++) {
            let app = data[i];
            if (!app || typeof app !== "object" || !app.volume) continue;
            
            let vol = 0;
            for (let channel in app.volume) {
                if (app.volume[channel].value_percent) {
                    vol = parseInt(app.volume[channel].value_percent);
                    break;
                }
            }
            
            let name = "Unknown";
            if (app.properties) {
                name = app.properties["application.name"] || app.properties["media.name"] || "Unknown App";
            }
            
            let appId = app.index;
            if (appId === undefined) continue;
            
            currentIds.add(appId);
            let found = false;
            for (let j = 0; j < appModel.count; j++) {
                let item = appModel.get(j);
                if (item && item.appId === appId) {
                    if (item.volume !== vol) appModel.setProperty(j, "volume", vol);
                    if (item.muted !== app.mute) appModel.setProperty(j, "muted", app.mute);
                    found = true;
                    break;
                }
            }
            
            if (!found) {
                appModel.append({
                    "appId": appId,
                    "name": name,
                    "volume": vol,
                    "muted": app.mute,
                    "icon": "\uf2d2"
                });
            }
        }
        
        for (let j = appModel.count - 1; j >= 0; j--) {
            let item = appModel.get(j);
            if (item && !currentIds.has(item.appId)) {
                appModel.remove(j);
            }
        }
    }

    Process {
        id: volListener
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                if (data.includes("change") && (data.includes("sink") || data.includes("source") || data.includes("sink-input"))) {
                    service.update();
                }
            }
        }
        onExited: restartDelay.start()
    }

    Timer {
        id: restartDelay
        interval: 10000
        onTriggered: {
            service.update();
            volListener.running = true;
        }
    }

    Process {
        id: volExec
        command: ["sh", "-c", "echo \"SINK=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)\"; echo \"SRC=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)\"; pw-link -i | grep -q ':input_' && echo 'MIC_ACTIVE=1' || echo 'MIC_ACTIVE=0'; wpctl status | grep -A 5 \"Default Configured Devices:\" | grep -q \"bluez\" && echo \"BT_ACTIVE=1\" || echo \"BT_ACTIVE=0\""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                const lines = text.trim().split("\n");
                service.micActive = text.includes("MIC_ACTIVE=1");
                service.btActive = text.includes("BT_ACTIVE=1");
                for (let l of lines) {
                    if (l.includes("SINK")) {
                        service.muted = l.includes("[MUTED]");
                        let m = l.match(/[0-9]\.[0-9]+/);
                        if (m) service.outputVolume = Math.round(parseFloat(m[0]) * 100);
                    }
                    if (l.includes("SRC")) {
                        service.micMuted = l.includes("[MUTED]");
                        let m = l.match(/[0-9]\.[0-9]+/);
                        if (m) service.micVolume = Math.round(parseFloat(m[0]) * 100);
                    }
                }
            }
        }
    }
}
