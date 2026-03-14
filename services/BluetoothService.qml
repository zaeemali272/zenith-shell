// services/BluetoothService.qml
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property alias devices: deviceModel
    property bool powered: false
    property bool connected: false
    property int percentage: 0
    property bool scanning: false
    property bool busy: actionExec.running || btCheck.running

    function refresh() {
        if (!btCheck.running)
            btCheck.running = true;

    }

    // --- Actions ---
    function togglePower() {
        // rfkill is faster than bluetoothctl for power toggling
        actionExec.command = ["rfkill", powered ? "block" : "unblock", "bluetooth"];
        actionExec.running = true;
    }

    function toggleScan() {
        let cmd = scanning ? "scan off" : "scan on";
        actionExec.command = ["sh", "-c", `echo -e "${cmd}\\nquit" | bluetoothctl`];
        actionExec.running = true;
        scanning = !scanning;
    }

    function action(mode, addr) {
        actionExec.command = ["sh", "-c", `echo -e "agent on\\ndefault-agent\\n${mode} ${addr}\\nquit" | bluetoothctl`];
        actionExec.running = true;
    }

    Component.onCompleted: {
        refresh();
        btWatcher.running = true;
    }

    ListModel {
        id: deviceModel
    }

    Process {
        id: actionExec

        onExited: refresh()
    }

    // --- Rule-Based Watcher ---
    // Instead of polling, we wait for DBus signals from bluez.
    // 'line' is a standard utility that blocks until a full line is received.
    Process {
        id: btWatcher

        command: ["sh", "-c", "dbus-monitor --system \"type='signal',sender='org.bluez'\" | line"]
        running: false
        onExited: {
            refresh();
            safetyTimer.start();
        }
    }

    Timer {
        id: safetyTimer

        interval: 1000 // 1s cooldown gives the device time to update its battery level
        onTriggered: btWatcher.running = true
    }

    // --- Data Collection ---
    Process {
        id: btCheck

        command: ["sh", "-c", `
            SCRIPT_PATH="/home/zaeem/Documents/Linux/Dots/zenith-shell/services/bt_battery.py"

            # Fetch status and devices in one go to minimize bluetoothctl calls
            data=$(echo -e "show\\ndevices\\nquit" | bluetoothctl)

            echo "$data" | grep -q "Powered: yes" && echo "POWER|ON" || echo "POWER|OFF"

            echo "$data" | grep "^Device " | while read -r _ addr name; do
                devInfo=$(echo -e "info $addr\\nquit" | bluetoothctl)

                connected="NO"
                paired="NO"
                battery="0"

                if echo "$devInfo" | grep -q "Connected: yes"; then
                    connected="YES"
                    # Only call python if connected. Use --compact for clean number.
                    battery=$(python3 "$SCRIPT_PATH" "$addr" --compact 2>/dev/null || echo "0")
                fi

                echo "$devInfo" | grep -q "Paired: yes" && paired="YES"
                echo "DEV|\$addr|\$connected|\$paired|\$battery|bluetooth|\$name"
            done
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text)
                    return ;

                const lines = text.trim().split("\n");
                let newDevices = [];
                let isPowered = false;
                let anyConnected = false;
                let maxBattery = 0;
                for (let line of lines) {
                    if (line === "POWER|ON") {
                        isPowered = true;
                    } else if (line.startsWith("DEV|")) {
                        let parts = line.split("|");
                        if (parts.length >= 7) {
                            let isDevConnected = (parts[2] === "YES");
                            let batVal = parseInt(parts[4]) || 0;
                            if (isDevConnected) {
                                anyConnected = true;
                                // If multiple devices are connected, show the highest battery
                                if (batVal > maxBattery)
                                    maxBattery = batVal;

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
                root.powered = isPowered;
                root.connected = anyConnected;
                root.percentage = maxBattery;
                deviceModel.clear();
                // Sort connected devices to the top
                newDevices.sort((a, b) => {
                    return b.connected - a.connected;
                });
                for (let d of newDevices) deviceModel.append(d)
            }
        }

    }

}
