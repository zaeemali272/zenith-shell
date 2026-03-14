import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property alias devices: deviceModel
    property bool powered: false
    property bool connected: false
    property int percentage: 0 // <--- Battery.qml reads this
    property bool scanning: false
    property bool busy: actionExec.running || btCheck.running

    // ... (Keep togglePower, toggleScan, and action functions as they are) ...
    function togglePower() {
        let cmd = powered ? "block" : "unblock";
        actionExec.command = ["rfkill", cmd, "bluetooth"];
        actionExec.running = true;
    }

    function toggleScan() {
        let cmd = scanning ? "scan off" : "scan on";
        actionExec.command = ["sh", "-c", `echo -e "${cmd}\\nquit" | bluetoothctl`];
        actionExec.running = true;
        scanning = !scanning;
    }

    function action(mode, addr) {
        if (mode === "pair")
            actionExec.command = ["sh", "-c", `echo -e "agent on\\ndefault-agent\\npair ${addr}\\ntrust ${addr}\\nconnect ${addr}\\nquit" | bluetoothctl`];
        else
            actionExec.command = ["sh", "-c", `echo -e "agent on\\ndefault-agent\\n${mode} ${addr}\\nquit" | bluetoothctl`];
        actionExec.running = true;
    }

    function refresh() {
        if (!btCheck.running) btCheck.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: actionExec
        onExited: refreshTimer.start()
    }

    Timer { id: refreshTimer; interval: 1000; onTriggered: refresh() }
    ListModel { id: deviceModel }

    Process {
        id: btCheck
        command: ["sh", "-c", `
            SCRIPT_PATH="/home/zaeem/Documents/Linux/Dots/zenith-shell/services/bt_battery.py"
            data=$(echo -e "show\\ndevices\\nquit" | bluetoothctl)

            echo "$data" | grep -q "Powered: yes" && echo "Powered: yes" || echo "Powered: no"

            echo "$data" | grep "^Device " | while read -r _ addr name; do
                devInfo=$(echo -e "info $addr\\nquit" | bluetoothctl)
                
                if echo "$devInfo" | grep -q "^[[:space:]]*Connected: yes"; then
                    connected="YES"
                    # Run script and get the number
                    battery=$(python3 "$SCRIPT_PATH" "$addr" 2>/dev/null | grep -o '[0-9]\\+%' | tr -d '%' | head -n 1)
                else
                    connected="NO"
                    battery="0"
                fi
                
                paired="NO"
                echo "$devInfo" | grep -q "^[[:space:]]*Paired: yes" && paired="YES"

                echo "DEV|\$addr|\$connected|\$paired|\${battery:-0}|bluetooth|\$name"
            done
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;

                const lines = text.trim().split("\n");
                let newDevices = [];
                let isPowered = false;
                let anyConnected = false;
                let maxBattery = 0;

                for (let line of lines) {
                    if (line.toLowerCase().includes("powered: yes")) {
                        isPowered = true;
                    } else if (line.startsWith("DEV|")) {
                        let parts = line.split("|");
                        if (parts.length >= 7) {
                            let isDevConnected = (parts[2] === "YES");
                            let batVal = parseInt(parts[4]) || 0;

                            if (isDevConnected) {
                                anyConnected = true;
                                // Crucial: Update maxBattery for the bar to see
                                if (batVal > 0) maxBattery = batVal;
                            }

                            newDevices.push({
                                "address": parts[1],
                                "connected": isDevConnected,
                                "paired": parts[3] === "YES",
                                "battery": batVal,
                                "icon": parts[5],
                                "name": parts[6]
                            });
                        }
                    }
                }

                // Apply values to the Singleton root
                root.powered = isPowered;
                root.connected = anyConnected;
                root.percentage = maxBattery; // This updates Battery.qml

                deviceModel.clear();
                newDevices.sort((a, b) => b.connected - a.connected);
                for (let d of newDevices) deviceModel.append(d);
            }
        }
    }

    Timer { interval: 10000; running: true; repeat: true; onTriggered: refresh() }
}