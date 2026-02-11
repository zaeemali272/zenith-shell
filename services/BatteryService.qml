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
    property string model: "System Battery"
    property string timeToEmpty: "Calculating..."
    // Cache the paths once on startup so we don't 'ls' every time
    property string batPath: ""
    property string acPath: ""

    function update() {
        if (batPath === "")
            return ;

        updateExec.running = true;
    }

    Component.onCompleted: {
        // Find paths once
        findPaths.running = true;
    }

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
                service.update();
                batListener.running = true;
            }
        }

    }

    // SPEED FIX: Watch both status and capacity for instant reaction
    Process {
        id: batListener

        // We watch for 'attrib' changes (status) and 'modify' (capacity)
        command: ["sh", "-c", `inotifywait -e modify,attrib ${service.batPath}/status ${service.batPath}/capacity ${service.acPath}/online 2>/dev/null || sleep 2`]
        running: false
        onExited: {
            service.update();
            restartTimer.start();
        }
    }

    Timer {
        id: restartTimer

        interval: 300 // Dropped from 1000 to 100 for "instant" feel
        onTriggered: batListener.running = true
    }

    Process {
        id: updateExec

        command: ["sh", "-c", `echo PERCENT=$(cat ${service.batPath}/capacity); echo STATE=$(cat ${service.batPath}/status); echo AC=$(cat ${service.acPath}/online)`]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text)
                    return ;

                const lines = text.trim().split("\n");
                lines.forEach((l) => {
                    if (l.startsWith("PERCENT="))
                        service.percentage = parseInt(l.slice(8));
                    else if (l.startsWith("STATE="))
                        service.status = l.slice(6).toLowerCase().trim();
                    else if (l.startsWith("AC="))
                        service.acOnline = l.slice(3) === "1";
                });
            }
        }

    }

}
