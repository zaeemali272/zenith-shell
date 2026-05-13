pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // --- State Variables ---
    property var devices: []
    property int deviceCount: devices.length
    property bool powered: false
    property bool connected: false
    property bool scanning: false
    property bool serviceActive: true
    property string state: "Idle" // Idle, Scanning, Connecting, Disconnecting, Powering
    
    property bool busy: actionExec.running || powerExec.running || scanExec.running || 
                       statusCheck.running || deviceRefresh.running || rfkillCheck.running || 
                       serviceCheck.running || infoExec.running || oneShotScan.running
    
    property bool _actionInProgress: false

    // Primary connected device info
    property string connectedName: ""
    property string connectedAddress: ""
    property int connectedBattery: -1
    property string connectedIcon: "bluetooth"

    function log(msg) {
        console.log("[Bluetooth] " + msg);
    }

    function refresh() {
        log("Manual refresh triggered");
        serviceCheck.running = false;
        serviceCheck.running = true;
        rfkillCheck.running = false;
        rfkillCheck.running = true;
        statusCheck.running = false;
        statusCheck.running = true;
        
        deviceRefresh.running = false;
        deviceRefresh.running = true;

        if (powered) {
            startScan();
        }
    }

    Process {
        id: serviceCheck
        command: ["systemctl", "is-active", "bluetooth.service"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.serviceActive = (text && text.trim() === "active");
                if (!root.serviceActive) {
                    root.state = "Service Error";
                }
            }
        }
    }

    function restartService() {
        log("Restarting service...");
        root.state = "Restarting Service";
        actionExec.command = ["pkexec", "systemctl", "restart", "bluetooth"];
        actionExec.running = true;
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
                
                if (root.state === "Idle" || root.state === "Scanning") {
                    root.state = isScanning ? "Scanning" : "Idle";
                }
            }
        }
    }

    Process {
        id: deviceRefresh
        command: ["sh", "-c", "bluetoothctl devices; echo '---'; bluetoothctl paired-devices; echo '---'; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                
                let parts = text.split("---");
                let allDevicesRaw = parts[0].trim().split("\n");
                let pairedDevicesRaw = parts.length > 1 ? parts[1].trim().split("\n") : [];
                let connectedDevicesRaw = parts.length > 2 ? parts[2].trim().split("\n") : [];

                let pairedAddresses = pairedDevicesRaw.map(l => {
                    let parts = l.trim().split(" ");
                    return parts.length > 1 ? parts[1] : "";
                }).filter(a => a);

                let connectedAddresses = connectedDevicesRaw.map(l => {
                    let parts = l.trim().split(" ");
                    return parts.length > 1 ? parts[1] : "";
                }).filter(a => a);

                let newDevices = [];
                let seen = {};

                for (let line of allDevicesRaw) {
                    let p = line.trim().split(" ");
                    if (p.length < 2) continue;
                    let addr = p[1];
                    if (!addr || seen[addr]) continue;
                    
                    let rawName = p.length > 2 ? p.slice(2).join(" ") : addr;
                    let isAddressFormat = rawName.match(/^[0-9A-Fa-f]{2}([:-][0-9A-Fa-f]{2}){5}$/);
                    let hasRealName = p.length > 2 && !isAddressFormat;
                    
                    let isPaired = pairedAddresses.indexOf(addr) !== -1;
                    let isConnected = connectedAddresses.indexOf(addr) !== -1;
                    
                    seen[addr] = true;
                    newDevices.push({
                        "address": addr,
                        "name": rawName,
                        "hasName": hasRealName,
                        "paired": isPaired,
                        "connected": isConnected,
                        "icon": "bluetooth",
                        "battery": -1
                    });
                }

                updateModel(newDevices);
                
                if (connectedAddresses.length > 0) {
                    fetchDetailedInfo(connectedAddresses[0]);
                } else {
                    root.connectedName = "";
                    root.connectedAddress = "";
                    root.connectedBattery = -1;
                }
            }
        }
    }

    function fetchDetailedInfo(addr) {
        infoExec.command = ["bluetoothctl", "info", addr];
        infoExec.running = true;
    }

    Process {
        id: infoExec
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let lines = text.split("\n");
                let name = "";
                let addr = "";
                let battery = -1;
                let icon = "bluetooth";
                let connected = false;

                for (let line of lines) {
                    let l = line.trim();
                    if (l.startsWith("Device ")) addr = l.split(" ")[1];
                    else if (l.startsWith("Name: ")) name = l.substring(6);
                    else if (l.startsWith("Icon: ")) icon = l.substring(6);
                    else if (l.startsWith("Connected: yes")) connected = true;
                    else if (l.includes("Battery Percentage:")) {
                        let bMatch = l.match(/\((\d+)\)/) || l.match(/:\s+(\d+)/);
                        if (bMatch) battery = parseInt(bMatch[1]);
                    }
                }

                if (connected) {
                    root.connectedName = name;
                    root.connectedAddress = addr;
                    root.connectedBattery = battery;
                    root.connectedIcon = icon;
                    
                    // Update the array element
                    let updated = root.devices.map(d => {
                        if (d.address === addr) {
                            return Object.assign({}, d, { battery: battery, icon: icon, connected: true });
                        }
                        return d;
                    });
                    root.devices = updated;
                }
            }
        }
    }

    function updateModel(newDevices) {
        newDevices.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return a.name.localeCompare(b.name);
        });
        root.devices = newDevices;
    }

    function togglePower() {
        let newState = !powered;
        root.state = newState ? "Powering On" : "Powering Off";
        _actionInProgress = true;
        powerExec.command = ["sh", "-c", `echo -e "power ${newState ? "on" : "off"}\\nquit" | bluetoothctl`];
        powerExec.running = true;
    }

    function toggleScan() {
        let target = !scanning;
        root.state = target ? "Starting Scan" : "Stopping Scan";
        scanExec.command = ["sh", "-c", `echo -e "scan ${target ? "on" : "off"}\\nquit" | bluetoothctl`];
        scanExec.running = true;
    }

    function startScan() {
        if (!powered || scanning) return;
        root.state = "Starting Scan";
        scanExec.command = ["sh", "-c", "echo -e 'scan on\\nquit' | bluetoothctl"];
        scanExec.running = true;
    }

    function stopScan() {
        if (!scanning) return;
        root.state = "Stopping Scan";
        scanExec.command = ["sh", "-c", "echo -e 'scan off\\nquit' | bluetoothctl"];
        scanExec.running = true;
    }

    function action(mode, addr) {
        root.state = mode.charAt(0).toUpperCase() + mode.slice(1) + "ing...";

        let cmd = "";
        if (mode === "connect") {
             cmd = `(bluetoothctl trust ${addr} && (bluetoothctl pair ${addr} || true) && bluetoothctl connect ${addr}) || bluetoothctl connect ${addr}`;
        } else if (mode === "pair") {
             cmd = `bluetoothctl trust ${addr} && (bluetoothctl pair ${addr} || true)`;
        } else if (mode === "disconnect") {
             cmd = `bluetoothctl disconnect ${addr}`;
        } else if (mode === "remove") {
             cmd = `bluetoothctl remove ${addr}`;
        }

        actionExec.command = ["sh", "-c", cmd];
        actionExec.running = true;
    }


    Process { id: oneShotScan; command: ["sh", "-c", "bluetoothctl --timeout 10 scan on & bluetoothctl --timeout 10 discoverable on; wait"] }
    Process { id: powerExec; onExited: { _actionInProgress = false; root.state = "Idle"; refresh(); } }
    Process { id: scanExec; onExited: { root.state = "Idle"; refresh(); } }
    Process { id: actionExec; onExited: { root.state = "Idle"; refresh(); } }

    Timer {
        id: scanUpdateTimer
        interval: 2000
        repeat: true
        running: oneShotScan.running || scanExec.running
        onTriggered: {
            deviceRefresh.running = false;
            deviceRefresh.running = true;
        }
    }

    Timer {
        id: healthCheckTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: serviceCheck.running = true
    }

    Component.onCompleted: refresh()
}
