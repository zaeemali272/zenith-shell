import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property alias devices: deviceModel
    property bool powered: false

    function togglePower() {
        // Fire and forget power toggle
        let cmd = powered ? "power off" : "power on";
        let proc = Quickshell.execute(["bluetoothctl", cmd]);
        refresh();
    }

    function action(mode, addr) {
        // mode can be 'connect', 'disconnect', or 'remove'
        Quickshell.execute(["bluetoothctl", mode, addr]);
        refresh();
    }

    function refresh() {
        btCheck.running = true;
    }

    ListModel {
        id: deviceModel
    }

    Process {
        id: btCheck

        // We run a simple bash script to get power status and device list
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo 'POWER:ON' || echo 'POWER:OFF'; bluetoothctl devices"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text)
                    return ;

                const lines = text.trim().split("\n");
                deviceModel.clear(); // Clear before refresh
                lines.forEach((line) => {
                    if (line.includes("POWER:ON")) {
                        powered = true;
                    } else if (line.includes("POWER:OFF")) {
                        powered = false;
                    } else if (line.includes("Device")) {
                        // Format: Device XX:XX:XX:XX:XX:XX Name
                        let parts = line.split(" ");
                        if (parts.length >= 3)
                            // We can refine this later with 'info'

                            deviceModel.append({
                                "address": parts[1],
                                "name": parts.slice(2).join(" "),
                                "connected": false
                            });

                    }
                });
            }
        }

    }

}
