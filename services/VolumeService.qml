// services/AudioService.qml
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: service

    property int outputVolume: 0
    property int micVolume: 0
    property bool muted: false
    property bool micMuted: false // <--- ADDED THIS
    property bool micActive: false
    property alias appsModel: appModel

    function update() {
        volExec.running = true;
        appVolExec.running = true;
    }

    Component.onCompleted: update()

    ListModel {
        id: appModel
    }

    Process {
        id: appVolExec

        command: ["pactl", "-f", "json", "list", "sink-inputs"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text)
                    return ;

                try {
                    const data = JSON.parse(text);
                    let currentIds = new Set();
                    for (let i = 0; i < data.length; i++) {
                        let app = data[i];
                        if (!app.volume)
                            continue;

                        let vol = 0;
                        for (let channel in app.volume) {
                            if (app.volume[channel].value_percent) {
                                vol = parseInt(app.volume[channel].value_percent);
                                break;
                            }
                        }
                        let name = app.properties["application.name"] || "Unknown";
                        let id = app.index;
                        currentIds.add(id);
                        let found = false;
                        for (let j = 0; j < appModel.count; j++) {
                            if (appModel.get(j).id === id) {
                                let item = appModel.get(j);
                                if (item.volume !== vol)
                                    appModel.setProperty(j, "volume", vol);

                                if (item.muted !== app.mute)
                                    appModel.setProperty(j, "muted", app.mute);

                                found = true;
                                break;
                            }
                        }
                        if (!found)
                            appModel.append({
                                "id": id,
                                "name": name,
                                "volume": vol,
                                "muted": app.mute,
                                "icon": "\uf2d2"
                            });

                    }
                    for (let j = appModel.count - 1; j >= 0; j--) {
                        if (!currentIds.has(appModel.get(j).id))
                            appModel.remove(j);

                    }
                } catch (e) {
                    console.error("JSON Parse error: " + e.message);
                }
            }
        }

    }

    Process {
        id: volListener

        command: ["sh", "-c", "pw-mon | grep --line-buffered -m 1 'node'"]
        running: true
        onExited: restartDelay.start()
    }

    Timer {
        id: restartDelay

        interval: 700
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
                if (!text)
                    return ;

                const lines = text.trim().split("\n");
                service.micActive = text.includes("MIC_ACTIVE=1");
                for (let l of lines) {
                    if (l.includes("SINK")) {
                        service.muted = l.includes("[MUTED]");
                        let m = l.match(/[0-9]\.[0-9]+/);
                        if (m)
                            service.outputVolume = Math.round(parseFloat(m[0]) * 100);

                    }
                    // --- FIXED SRC LOGIC ---
                    if (l.includes("SRC")) {
                        // Correctly set micMuted if the SRC line contains [MUTED]
                        service.micMuted = l.includes("[MUTED]");
                        let m = l.match(/[0-9]\.[0-9]+/);
                        if (m)
                            service.micVolume = Math.round(parseFloat(m[0]) * 100);

                    }
                }
            }
        }

    }

}
