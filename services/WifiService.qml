import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: service

    property var networks: []
    property var knownNetworks: ({})
    
    // Station Info
    property string currentState: "disconnected"
    property string currentSsid: ""
    property string ipv4Address: ""
    property string rssi: ""
    property string txBitrate: ""
    property string frequency: ""

    signal connectionFailed(string ssid)
    signal connectionSuccess(string ssid)

    property string currentSpeed: "0.0 Mbps"
    property bool isTesting: false

    function refresh() {
        startHardwareScan();
        updateKnownNetworks();
        updateStationInfo();
    }

    function startHardwareScan() {
        scanProcess.running = false;
        scanProcess.running = true;
    }

    function updateNetworkList() {
        listProcess.running = false;
        listProcess.running = true;
    }

    function updateKnownNetworks() {
        knownNetworksProcess.running = false;
        knownNetworksProcess.running = true;
    }

    function updateStationInfo() {
        stationInfoProcess.running = false;
        stationInfoProcess.running = true;
    }

    function runMaxSpeedTest() {
        if (isTesting) return;
        isTesting = true;
        speedTestProcess.running = false;
        speedTestProcess.running = true;
    }

    function connect(ssid, password) {
        _pendingConnectSsid = ssid;
        executor.running = false;
        if (password && password !== "") {
            executor.command = ["sh", "-c", 'iwctl station $(ls /sys/class/net | grep ^wl | head -n1) connect "$1" --passphrase "$2"', "sh", ssid, password];
        } else {
            executor.command = ["sh", "-c", 'iwctl station $(ls /sys/class/net | grep ^wl | head -n1) connect "$1"', "sh", ssid];
        }
        executor.running = true;
    }

    function disconnect() {
        executor.running = false;
        executor.command = ["sh", "-c", 'iwctl station $(ls /sys/class/net | grep ^wl | head -n1) disconnect'];
        executor.running = true;
    }

    function forgetNetwork(ssid) {
        if (!ssid) return;
        executor.running = false;
        executor.command = ["sh", "-c", 'iwctl known-networks "$1" forget; iwctl station $(ls /sys/class/net | grep ^wl | head -n1) disconnect', "sh", ssid];
        executor.running = true;
    }

    // --- Processes ---

    Process {
        id: scanProcess
        command: ["sh", "-c", "iwctl station $(ls /sys/class/net | grep ^wl | head -n1) scan"]
        onExited: (exitCode) => { service.updateNetworkList(); }
    }

    Process {
        id: stationInfoProcess
        command: ["sh", "-c", "iwctl station $(ls /sys/class/net | grep ^wl | head -n1) show | sed 's/\\x1b\\[[0-9;]*m//g'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n");
                let info = {};
                for (let line of lines) {
                    let parts = line.trim().split(/\s{2,}/);
                    if (parts.length >= 2) {
                        info[parts[0].trim()] = parts[1].trim();
                    }
                }
                service.currentState = info["State"] || "disconnected";
                service.currentSsid = info["Connected network"] || "";
                service.ipv4Address = info["IPv4 address"] || "";
                service.rssi = info["AverageRSSI"] || info["RSSI"] || "";
                service.txBitrate = info["TxBitrate"] || "";
                service.frequency = info["Frequency"] || "";
            }
        }
    }

    Process {
        id: knownNetworksProcess
        command: ["sh", "-c", "iwctl known-networks list | sed 's/\\x1b\\[[0-9;]*m//g'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n");
                let temp = {};
                for (let line of lines) {
                    let trimmed = line.trim();
                    if (!trimmed || trimmed.startsWith('Name') || trimmed.startsWith('---') || trimmed.includes('Known Networks')) continue;
                    let parts = trimmed.split(/\s{2,}/);
                    if (parts.length >= 1 && parts[0] !== "") {
                        temp[parts[0].trim()] = true;
                    }
                }
                service.knownNetworks = temp;
            }
        }
    }

    Process {
        id: listProcess
        command: ["sh", "-c", "iwctl station $(ls /sys/class/net | grep ^wl | head -n1) get-networks | sed 's/\\x1b\\[[0-9;]*m//g'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n");
                let temp = [];
                for (let line of lines) {
                    let rawLine = line;
                    let trimmed = line.trim();
                    if (!trimmed || trimmed.startsWith('Network name') || trimmed.startsWith('---') || trimmed.includes('Available networks')) continue;
                    
                    // Column 1 is indicators (starts at 0, usually 4-6 chars wide)
                    let indicatorPart = rawLine.substring(0, 6);
                    let isConnected = indicatorPart.includes('>');
                    
                    let contentPart = rawLine.substring(6).trim();
                    let parts = contentPart.split(/\s{2,}/);
                    
                    if (parts.length >= 2) {
                        let ssid = parts[0].trim();
                        let security = parts[1].trim().toLowerCase();
                        let signalStr = parts[parts.length - 1]; // Last part is usually signal like ****
                        let signal = 0;
                        if (signalStr.includes('****')) signal = 4;
                        else if (signalStr.includes('***')) signal = 3;
                        else if (signalStr.includes('**')) signal = 2;
                        else if (signalStr.includes('*')) signal = 1;

                        temp.push({
                            "ssid": ssid,
                            "security": security,
                            "connected": isConnected || (service.currentSsid === ssid && service.currentState === "connected"),
                            "signal": signal
                        });
                    }
                }
                // Sort: Connected first, then by signal strength, then alphabetically
                temp.sort((a, b) => {
                    if (a.connected !== b.connected) return b.connected ? 1 : -1;
                    if (a.signal !== b.signal) return b.signal - a.signal;
                    return a.ssid.localeCompare(b.ssid);
                });
                service.networks = temp;
            }
        }
    }

    Process {
        id: speedTestProcess
        command: ["sh", "-c", "curl -L -m 15 -w '%{speed_download}' -o /dev/null -s https://speed.cloudflare.com/__down?bytes=10485760"]
        stdout: StdioCollector {
            onStreamFinished: {
                let bytesPerSec = parseFloat(text.trim());
                if (!isNaN(bytesPerSec) && bytesPerSec > 0) {
                    let mbps = (bytesPerSec * 8 / 1000000).toFixed(1);
                    service.currentSpeed = mbps + " Mbps";
                } else {
                    service.currentSpeed = "Check Connection";
                }
                service.isTesting = false;
            }
        }
    }

    property string _pendingConnectSsid: ""

    Process {
        id: executor
        onExited: (exitCode) => {
            if (exitCode === 0) {
                if (_pendingConnectSsid !== "") {
                    service.connectionSuccess(_pendingConnectSsid);
                }
            } else {
                if (_pendingConnectSsid !== "") {
                    service.connectionFailed(_pendingConnectSsid);
                }
            }
            _pendingConnectSsid = "";
            service.refresh();
        }
    }
    
    Component.onCompleted: service.refresh()
}