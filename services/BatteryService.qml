// services/BatteryService.qml
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: service

    property int percentage: -1
    property string status: "unknown"
    property bool acOnline: false
    property string batPath: ""
    property string acPath: ""

    function update() {
        updateExec.running = true;
    }

    Component.onCompleted: findPaths.running = true

    Process {
        id: findPaths

        command: ["sh", "-c", "echo BAT=$(ls -d /sys/class/power_supply/BAT* | head -n1); echo AC=$(ls -d /sys/class/power_supply/AC* /sys/class/power_supply/ADP* 2>/dev/null | head -n1)"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                lines.forEach((l) => {
                    if (l.startsWith("BAT="))
                        service.batPath = l.slice(4);

                    if (l.startsWith("AC="))
                        service.acPath = l.slice(3);

                });
                if (service.batPath && service.acPath) {
                    service.update(); // Initial fetch
                    batWatcher.running = true;
                }
            }
        }

    }

    // This fetches the actual data
    Process {
        id: updateExec

        command: ["sh", "-c", `cat ${service.batPath}/capacity ${service.batPath}/status ${service.acPath}/online`]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text)
                    return ;

                const parts = text.trim().split("\n");
                if (parts.length >= 3) {
                    service.percentage = parseInt(parts[0]);
                    service.status = parts[1].toLowerCase().trim();
                    service.acOnline = parts[2] === "1";
                }
            }
        }

    }

    // THE RULE: Waits for one event, exits, updates, then restarts via a small timer
    Process {
        id: batWatcher

        command: ["sh", "-c", `inotifywait -q -e modify,attrib ${service.batPath}/status ${service.batPath}/capacity ${service.acPath}/online`]
        running: false
        onExited: {
            service.update();
            safetyTimer.start(); // Don't restart instantly to prevent CPU spikes
        }
    }

    Timer {
        id: safetyTimer

        interval: 100 // 100ms is imperceptible but prevents a 0ms busy loop
        onTriggered: batWatcher.running = true
    }

}
