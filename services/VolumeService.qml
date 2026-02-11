import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: service

    property int outputVolume: 0
    property int micVolume: 0
    property bool muted: false
    property bool btActive: false
    property bool micActive: false

    function update() {
        volExec.running = true;
    }

    Component.onCompleted: update()

    Process {
        id: volListener

        command: ["sh", "-c", "pw-mon | grep --line-buffered -m 1 'node'"]
        running: true
        onExited: restartDelay.start()
    }

    Timer {
        id: restartDelay

        interval: 500
        onTriggered: {
            service.update();
            volListener.running = true;
        }
    }

    Process {
        id: volExec

        // We merged everything into one command string
        command: ["sh", "-c", "echo \"SINK=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)\"; echo \"SRC=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)\"; wpctl inspect @DEFAULT_AUDIO_SINK@ | grep 'node.name'; pw-link -i | grep -q ':input_' && echo 'MIC_ACTIVE=1' || echo 'MIC_ACTIVE=0'"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text)
                    return ;

                const lines = text.trim().split("\n");
                // Bluetooth check
                service.btActive = text.toLowerCase().includes("bluez") || text.toLowerCase().includes("bluetooth");
                // Mic Active check (looking for our echo)
                service.micActive = text.includes("MIC_ACTIVE=1");
                // Volume and Mute parsing
                for (let l of lines) {
                    if (l.includes("SINK")) {
                        service.muted = l.includes("[MUTED]");
                        let m = l.match(/[0-9]\.[0-9]+/);
                        if (m)
                            service.outputVolume = Math.round(parseFloat(m[0]) * 100);

                    }
                    if (l.includes("SRC")) {
                        let m = l.match(/[0-9]\.[0-9]+/);
                        if (m)
                            service.micVolume = Math.round(parseFloat(m[0]) * 100);

                    }
                }
            }
        }

    }

}
