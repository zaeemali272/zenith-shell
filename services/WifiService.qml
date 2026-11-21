import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: service

    property var networks: []
    property var knownNetworks: ({})
    property var knownPasswords: ({})

    // Station & Connection Info
    property string currentState: "disconnected"
    property string currentSsid: ""
    property string currentPassword: ""
    property string ipv4Address: ""
    property string rssi: ""
    property string txBitrate: ""
    property string frequency: ""
    property bool isAirplane: false

    // Speeds & Speed Test
    property string currentSpeed: "0.0 Mbps"
    property bool isTesting: false
    property bool isUserTyping: false
    readonly property bool isRefreshing: stateProc.running
    readonly property bool isConnecting: actionProc.running && _pendingConnectSsid !== ""
    readonly property string connectingSsid: _pendingConnectSsid

    signal connectionFailed(string ssid)
    signal connectionSuccess(string ssid)

    readonly property string helperScript: PathSettings.scriptsDir + "/wifi_nm.py"
    property bool _pendingRefresh: false

    function updateNetworksConnectedState(ssid, isConnected) {
        if (!service.networks || service.networks.length === 0) return;
        let modified = false;
        let list = [];
        for (let i = 0; i < service.networks.length; i++) {
            let item = Object.assign({}, service.networks[i]);
            let shouldBeConnected = (isConnected && item.ssid === ssid);
            if (item.connected !== shouldBeConnected) {
                item.connected = shouldBeConnected;
                modified = true;
            }
            list.push(item);
        }
        if (modified) {
            list.sort((a, b) => {
                if (a.connected !== b.connected) return a.connected ? -1 : 1;
                let aKnown = Boolean(a.isKnown);
                let bKnown = Boolean(b.isKnown);
                if (aKnown !== bKnown) return aKnown ? -1 : 1;
                return (b.signalPct || 0) - (a.signalPct || 0);
            });
            service.networks = list;
        }
    }

    // A full scan passes --rescan yes to nmcli, which takes ~5 seconds because
    // it drives an actual hardware rescan. A cheap status/cached read is ~14ms.
    function refresh(fullScan) {
        if (stateProc.running) {
            _pendingRefresh = true;
            return;
        }

        let doScan = (fullScan !== undefined) ? fullScan : false;
        _requestScanned = doScan;
        stateProc.command = ["python3", helperScript, doScan ? "json" : "cached"];
        stateProc.running = true;
    }

    function cancelScan() {
        if (stateProc.running) {
            stateProc.running = false;
        }
    }

    // What NetworkManager already knows, without touching the radio.
    // Instant ~14ms query that returns the cached network list with connected status.
    function listCached() {
        if (stateProc.running) {
            _pendingRefresh = true;
            return;
        }
        _requestScanned = true;
        stateProc.command = ["python3", helperScript, "cached"];
        stateProc.running = true;
    }

    // Force a full rescan even if a cheap read is in flight -- used
    // when the user explicitly hits the refresh button.
    function rescan() {
        stateProc.running = false;
        _requestScanned = true;
        stateProc.command = ["python3", helperScript, "json"];
        stateProc.running = true;
    }

    property bool _requestScanned: false

    function toggleAirplane(block) {
        actionProc.command = ["python3", helperScript, "airplane", block ? "off" : "on"];
        actionProc.running = true;
    }

    function runMaxSpeedTest() {
        if (isTesting) return;
        isTesting = true;
        speedTestProcess.running = false;
        speedTestProcess.running = true;
    }

    function connect(ssid, password) {
        _pendingConnectSsid = ssid;
        currentState = "connecting";
        currentSsid = ssid;
        updateNetworksConnectedState(ssid, false);
        if (password && password !== "") {
            actionProc.command = ["python3", helperScript, "connect", ssid, password];
        } else {
            actionProc.command = ["python3", helperScript, "connect", ssid];
        }
        actionProc.running = true;
    }

    function disconnect() {
        let prev = currentSsid;
        currentState = "disconnected";
        currentSsid = "";
        updateNetworksConnectedState(prev, false);
        actionProc.command = ["python3", helperScript, "disconnect"];
        actionProc.running = true;
    }

    function forgetNetwork(ssid) {
        if (!ssid) return;
        actionProc.command = ["python3", helperScript, "forget", ssid];
        actionProc.running = true;
    }

    // --- Processes ---

    Process {
        id: stateProc
        command: ["python3", helperScript, "cached"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    let data = JSON.parse(text);
                    if (data.isAirplane !== undefined) service.isAirplane = data.isAirplane;
                    if (data.currentState !== undefined) service.currentState = data.currentState;
                    if (data.currentSsid !== undefined) service.currentSsid = data.currentSsid;
                    if (data.currentPassword !== undefined) service.currentPassword = data.currentPassword;
                    if (data.ipv4Address !== undefined) service.ipv4Address = data.ipv4Address;
                    if (data.knownDict) service.knownNetworks = data.knownDict;
                    if (data.knownPasswords) service.knownPasswords = data.knownPasswords;

                    if (Array.isArray(data.networks) && data.networks.length > 0) {
                        if (!service.isUserTyping) {
                            service.networks = data.networks;
                        } else {
                            service.updateNetworksConnectedState(service.currentSsid, service.currentState === "connected");
                        }
                    } else {
                        service.updateNetworksConnectedState(service.currentSsid, service.currentState === "connected");
                    }
                } catch (e) {
                    console.log("WifiService JSON parse error:", e);
                }
            }
        }
        onExited: {
            if (service._pendingRefresh) {
                service._pendingRefresh = false;
                service.listCached();
            }
        }
    }

    property string _pendingConnectSsid: ""

    Process {
        id: actionProc
        onExited: (exitCode) => {
            if (exitCode === 0) {
                if (_pendingConnectSsid !== "") {
                    service.currentState = "connected";
                    service.currentSsid = _pendingConnectSsid;
                    service.updateNetworksConnectedState(_pendingConnectSsid, true);
                    service.connectionSuccess(_pendingConnectSsid);
                }
            } else {
                if (_pendingConnectSsid !== "") {
                    service.currentState = "disconnected";
                    service.currentSsid = "";
                    service.updateNetworksConnectedState(_pendingConnectSsid, false);
                    service.connectionFailed(_pendingConnectSsid);
                }
            }
            _pendingConnectSsid = "";
            service.listCached();
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

    // Instant NetworkManager Event Monitor
    Process {
        id: nmMonitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: (data) => service.listCached()
        }
        onExited: restartNmMon.start()
    }

    Timer {
        id: restartNmMon
        interval: 3000
        onTriggered: nmMonitor.running = true
    }

    Timer {
        id: wifiStartupTimer
        interval: 600
        running: true
        repeat: false
        onTriggered: service.refresh()
    }
}
