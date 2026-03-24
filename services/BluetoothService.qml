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
    property bool scanning: false
    property bool busy: actionExec.running || btCheck.running

    function refresh() {
        if (!btCheck.running)
            btCheck.running = true;
    }

    // --- Actions ---
    function togglePower() {
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
    Process {
        id: btWatcher
        // Monitor property changes and interface changes (connection events) continuously
        command: ["dbus-monitor", "--system", "sender='org.bluez'"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (!btWatcher.running) btWatcher.running = true;
            }
            onTextChanged: {
                // Throttle updates: only refresh if not already busy/queued
                // We listen for any output from dbus-monitor on bluez sender
                if (!refreshTimer.running) {
                    refreshTimer.start();
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 2000 // 2s throttle window
        onTriggered: refresh()
    }

    // --- Data Collection ---
    Process {
        id: btCheck
        command: ["sh", "-c", `
            # Fetch status
            bluetoothctl show | grep -i -q "Powered: yes" && echo "POWER|ON" || echo "POWER|OFF"

            # Fetch devices and connection status
            bluetoothctl devices | while read -r _ addr name; do
                info=$(bluetoothctl info "$addr")
                c="NO"; p="NO"
                echo "$info" | grep -i -q "Connected: yes" && c="YES"
                echo "$info" | grep -i -q "Paired: yes" && p="YES"
                echo "DEV|$addr|$c|$p|bluetooth|$name"
            done
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;

                const lines = text.trim().split("\n");
                let newDevices = [];
                let isPowered = false;
                let anyConnected = false;
                
                for (let line of lines) {
                    if (line === "POWER|ON") {
                        isPowered = true;
                    } else if (line.startsWith("DEV|")) {
                        let parts = line.split("|");
                        if (parts.length >= 6) {
                            let isDevConnected = (parts[2] === "YES");
                            if (isDevConnected) anyConnected = true;
                            
                            newDevices.push({
                                "address": parts[1],
                                "connected": isDevConnected,
                                "paired": parts[3] === "YES",
                                "icon": parts[4],
                                "name": parts[5]
                            });
                        }
                    }
                }
                
                root.powered = isPowered;
                root.connected = anyConnected;
                
                deviceModel.clear();
                newDevices.sort((a, b) => b.connected - a.connected);
                for (let d of newDevices) deviceModel.append(d);
            }
        }
    }
}
