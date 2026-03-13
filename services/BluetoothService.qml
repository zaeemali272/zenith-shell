import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property alias devices: deviceModel
    property bool powered: false
    property bool scanning: false
    property bool busy: actionExec.running || btCheck.running

    function togglePower() {
        let cmd = powered ? "block" : "unblock";
        console.log("BT_DEBUG: Toggling power with rfkill:", cmd);
        actionExec.command = ["rfkill", cmd, "bluetooth"];
        actionExec.running = true;
    }

    function toggleScan() {
        let cmd = scanning ? "scan off" : "scan on";
        console.log("BT_DEBUG: Toggling scan:", cmd);
        actionExec.command = ["sh", "-c", `echo -e "${cmd}\\nquit" | bluetoothctl` ];
        actionExec.running = true;
        scanning = !scanning;
    }

    function action(mode, addr) {
        console.log("BT_DEBUG: Executing action:", mode, "for", addr);
        if (mode === "pair") {
            // For pairing, we want to pair, trust AND connect for a reliable experience
            actionExec.command = ["sh", "-c", `echo -e "agent on\\ndefault-agent\\npair ${addr}\\ntrust ${addr}\\nconnect ${addr}\\nquit" | bluetoothctl` ];
        } else {
            actionExec.command = ["sh", "-c", `echo -e "agent on\\ndefault-agent\\n${mode} ${addr}\\nquit" | bluetoothctl` ];
        }
        actionExec.running = true;
    }

    function refresh() {
        if (!btCheck.running) {
            btCheck.running = true;
        }
    }

    Timer {
        id: refreshTimer
        interval: 1000
        onTriggered: refresh()
    }

    Process {
        id: actionExec
        onExited: refreshTimer.start()
    }

    ListModel {
        id: deviceModel
    }

    Process {
        id: btCheck

        // We use the piping method to force bluetoothctl to initialize and report data
        command: ["sh", "-c", `
            data=$(echo -e "show\\ndevices\\nquit" | bluetoothctl)
            
            # 1. Check Power
            echo "$data" | grep -q "Powered: yes" && echo "Powered: yes" || echo "Powered: no"
            
            # 2. Process Devices
            echo "$data" | grep "^Device " | while read -r _ addr name; do
                devInfo=$(echo -e "info $addr\\nquit" | bluetoothctl)
                
                # Check Paired status (be very specific with grep)
                echo "$devInfo" | grep -q "^[[:space:]]*Paired: yes" && paired="YES" || paired="NO"
                
                # Always get icon if available
                icon=$(echo "$devInfo" | grep "Icon:" | awk '{print \$2}')
                [ -z "$icon" ] && icon="bluetooth"

                # Check Connected status (be very specific with grep)
                if echo "$devInfo" | grep -q "^[[:space:]]*Connected: yes"; then
                    connected="YES"
                    battery=$(echo "$devInfo" | grep "Battery Percentage" | awk -F '[()]' '{print $2}' | tr -d '[:space:]%' || echo "")
                    [ -z "$battery" ] && battery=$(echo "$devInfo" | grep "Battery Percentage" | awk '{print \$3}' | tr -d '[:space:]%')
                else
                    connected="NO"
                    battery="0"
                fi
                echo "DEV|\$addr|\$connected|\$paired|\${battery:-0}|\$icon|\$name"
            done
        `]
        running: false
        onExited: {
        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;

                const lines = text.trim().split("\n");
                let newDevices = [];
                let isPowered = false;
                
                lines.forEach((line) => {
                    if (line.toLowerCase().includes("powered: yes")) {
                        isPowered = true;
                    } else if (line.startsWith("DEV|")) {
                        let parts = line.split("|");
                        if (parts.length >= 7) {
                            newDevices.push({
                                "address": parts[1],
                                "connected": parts[2] === "YES",
                                "paired": parts[3] === "YES",
                                "battery": parseInt(parts[4]) || 0,
                                "icon": parts[5] || "bluetooth",
                                "name": parts[6]
                            });
                        }
                    }
                });

                powered = isPowered;
                
                newDevices.sort((a, b) => {
                    if (a.connected !== b.connected) return b.connected - a.connected;
                    return a.name.localeCompare(b.name);
                });

                deviceModel.clear();
                newDevices.forEach(d => deviceModel.append(d));
            }
        }
    }

    Component.onCompleted: {
        refresh();
    }

    // Auto refresh every 10 seconds
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: refresh()
    }
}
