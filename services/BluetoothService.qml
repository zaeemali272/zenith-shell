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

    function startScan() {
        if (!scanning) {
            actionExec.command = ["sh", "-c", `echo -e "scan on\\nquit" | bluetoothctl`];
            actionExec.running = true;
            scanning = true;
        }
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
        command: ["dbus-monitor", "--system", "sender='org.bluez'"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (!btWatcher.running) btWatcher.running = true;
            }
            onTextChanged: {
                if (!refreshTimer.running) {
                    refreshTimer.start();
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 1000 
        onTriggered: refresh()
    }

    // --- Data Collection ---
    Process {
        id: btCheck
        command: ["busctl", "call", "org.bluez", "/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects", "--json=short"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;

                try {
                    const response = JSON.parse(text);
                    if (!response.data || response.data.length === 0) return;
                    
                    const objects = response.data[0];
                    let newDevices = [];
                    let isPowered = false;
                    let anyConnected = false;
                    let isScanning = false;

                    for (const path in objects) {
                        const interfaces = objects[path];
                        
                        // Check for Adapter (to get power and scanning status)
                        if (interfaces["org.bluez.Adapter1"]) {
                            const adapter = interfaces["org.bluez.Adapter1"];
                            if (adapter.Powered && adapter.Powered.data) isPowered = true;
                            if (adapter.Discovering && adapter.Discovering.data) isScanning = true;
                        }

                        // Check for Device
                        if (interfaces["org.bluez.Device1"]) {
                            const device = interfaces["org.bluez.Device1"];
                            const isDevConnected = (device.Connected && device.Connected.data === true);
                            if (isDevConnected) anyConnected = true;
                            
                            newDevices.push({
                                "address": device.Address ? device.Address.data : "",
                                "connected": isDevConnected,
                                "paired": (device.Paired && device.Paired.data === true),
                                "icon": device.Icon ? device.Icon.data : "bluetooth",
                                "name": device.Name ? device.Name.data : (device.Alias ? device.Alias.data : (device.Address ? device.Address.data : "Unknown Device"))
                            });
                        }
                    }

                    root.powered = isPowered;
                    root.connected = anyConnected;
                    root.scanning = isScanning;

                    // Sort newDevices
                    newDevices.sort((a, b) => {
                        if (a.connected !== b.connected) return b.connected ? -1 : 1;
                        if (a.paired !== b.paired) return b.paired ? -1 : 1;
                        return a.name.localeCompare(b.name);
                    });

                    // Incremental update to avoid flicker
                    let i = 0;
                    while (i < newDevices.length) {
                        const nd = newDevices[i];
                        if (i < deviceModel.count) {
                            const ed = deviceModel.get(i);
                            // Only update if something changed
                            if (ed.address !== nd.address || ed.connected !== nd.connected || ed.paired !== nd.paired || ed.name !== nd.name || ed.icon !== nd.icon) {
                                deviceModel.set(i, nd);
                            }
                        } else {
                            deviceModel.append(nd);
                        }
                        i++;
                    }
                    
                    // Remove extra items
                    while (deviceModel.count > newDevices.length) {
                        deviceModel.remove(deviceModel.count - 1);
                    }

                } catch (e) {
                    console.error("Error parsing bluetooth objects: " + e);
                }
            }
        }
    }
}
