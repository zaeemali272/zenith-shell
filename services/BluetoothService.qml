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
    property bool busy: actionExec.running || powerExec.running || scanExec.running || statusCheck.running || deviceRefresh.running || rfkillCheck.running || serviceCheck.running || serviceRestart.running
    property bool _actionInProgress: false

    function log(msg) {
        console.log("[Bluetooth] " + msg);
    }

    function refresh() {
        if (_actionInProgress) return;
        
        // Always check service and status
        serviceCheck.running = false;
        serviceCheck.running = true;
        rfkillCheck.running = false;
        rfkillCheck.running = true;
        statusCheck.running = false;
        statusCheck.running = true;
        
        // Only refresh device list if menu is open or it's a scheduled full refresh
        if (QuickSettingsService.qsVisible && QuickSettingsService.activeTab === "bluetooth") {
            deviceRefresh.running = false;
            deviceRefresh.running = true;
        }
    }

    Process {
        id: serviceCheck
        command: ["systemctl", "is-active", "bluetooth.service"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "active") {
                    log("Service not active (" + text.trim() + "), attempting restart...");
                    serviceRestart.running = true;
                }
            }
        }
    }

    Process {
        id: serviceRestart
        command: ["systemctl", "restart", "bluetooth.service"]
        onExited: (code) => {
            log("Service restart attempted, exit code: " + code);
            Qt.callLater(() => { refresh(); }, 2000);
        }
    }

    Process {
        id: rfkillCheck
        command: ["sh", "-c", "rfkill list bluetooth | grep -i 'soft blocked: yes'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "") {
                    if (root.powered) root.powered = false;
                }
            }
        }
    }

    Process {
        id: statusCheck
        command: ["sh", "-c", "bluetoothctl show | grep -E 'Powered:|Discovering:'; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.split("\n");
                let isPowered = false;
                let isScanning = false;
                let hasConnected = false;

                for (let line of lines) {
                    if (line.includes("Powered: yes")) isPowered = true;
                    if (line.includes("Discovering: yes")) isScanning = true;
                    if (line.startsWith("Device ")) hasConnected = true;
                }

                root.powered = isPowered;
                root.scanning = isScanning;
                root.connected = hasConnected;
            }
        }
    }

    Process {
        id: deviceRefresh
        command: ["sh", "-c", "bluetoothctl devices | cut -d ' ' -f 2 | xargs -I {} bluetoothctl info {}"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                
                let devicesRaw = text.split("Device ");
                let newDevices = [];

                for (let raw of devicesRaw) {
                    if (!raw || raw.trim() === "") continue;
                    
                    let lines = raw.split("\n");
                    let address = lines[0].split(" ")[0].trim();
                    let name = "Unknown Device";
                    let paired = false;
                    let connected = false;
                    let icon = "bluetooth";

                    for (let line of lines) {
                        let l = line.trim();
                        if (l.startsWith("Name: ")) name = l.substring(6);
                        else if (l.startsWith("Alias: ") && name === "Unknown Device") name = l.substring(7);
                        else if (l.startsWith("Paired: yes")) paired = true;
                        else if (l.startsWith("Connected: yes")) connected = true;
                        else if (l.startsWith("Icon: ")) icon = l.substring(6);
                    }

                    if (address && address.length > 10) {
                        newDevices.push({
                            "address": address,
                            "name": name,
                            "paired": paired,
                            "connected": connected,
                            "icon": icon
                        });
                    }
                }

                newDevices.sort((a, b) => {
                    if (a.connected !== b.connected) return b.connected ? -1 : 1;
                    if (a.paired !== b.paired) return b.paired ? -1 : 1;
                    return a.name.localeCompare(b.name);
                });

                for (let i = 0; i < newDevices.length; i++) {
                    if (i < deviceModel.count) deviceModel.set(i, newDevices[i]);
                    else deviceModel.append(newDevices[i]);
                }
                while (deviceModel.count > newDevices.length) deviceModel.remove(deviceModel.count - 1);
            }
        }
    }

    function togglePower() {
        let newState = !powered;
        _actionInProgress = true;
        powered = newState;
        
        if (newState) {
            powerExec.command = ["sh", "-c", "rfkill unblock bluetooth && bluetoothctl power on"];
        } else {
            powerExec.command = ["bluetoothctl", "power", "off"];
        }
        powerExec.running = true;
        Qt.callLater(() => { _actionInProgress = false; refresh(); }, 1500);
    }

    function toggleScan() {
        let target = !scanning;
        scanExec.command = ["bluetoothctl", "scan", target ? "on" : "off"];
        scanExec.running = true;
        Qt.callLater(() => { refresh(); }, 1500);
    }

    function startScan() {
        if (!powered || scanning) return;
        scanExec.command = ["bluetoothctl", "scan", "on"];
        scanExec.running = true;
        Qt.callLater(() => { refresh(); }, 1500);
    }

    function stopScan() {
        if (!scanning) return;
        scanExec.command = ["bluetoothctl", "scan", "off"];
        scanExec.running = true;
        Qt.callLater(() => { refresh(); }, 1500);
    }

    onPoweredChanged: {
        if (powered) {
            log("Bluetooth powered on, starting scan...");
            startScan();
        }
    }

    onConnectedChanged: {
        if (!connected && powered) {
            log("Device disconnected, restarting scan...");
            startScan();
        }
    }

    function action(mode, addr) {
        actionExec.command = ["sh", "-c", `echo -e "agent on\\ndefault-agent\\n${mode} ${addr}\\nquit" | bluetoothctl`];
        actionExec.running = true;
        Qt.callLater(() => { refresh(); }, 2000);
    }

    Component.onCompleted: refresh()

    ListModel { id: deviceModel }

    Process { id: powerExec }
    Process { id: scanExec }
    Process { id: actionExec }

    Process {
        id: btWatcher
        command: ["dbus-monitor", "--system", "sender='org.bluez',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                // Throttle reactive refreshes
                if (line.includes("PropertiesChanged") && !refreshTimer.running) {
                    refreshTimer.start();
                }
            }
        }
    }

    Timer { id: refreshTimer; interval: 10000; onTriggered: refresh() }
    Timer { id: pollingTimer; interval: 600000; repeat: true; running: true; onTriggered: refresh() }

    Timer {
        id: healthCheckTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            if (!btWatcher.running) {
                log("btWatcher died, restarting...");
                btWatcher.running = true;
            }
            serviceCheck.running = true;
        }
    }
}
