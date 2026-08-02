import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: service

    property var networks: []
    property var knownNetworks: ({})

    // Station & Connection Info
    property string currentState: "disconnected"
    property string currentSsid: ""
    property string ipv4Address: ""
    property string rssi: ""
    property string txBitrate: ""
    property string frequency: ""
    property bool isAirplane: false

    // Speeds & Speed Test
    property string currentSpeed: "0.0 Mbps"
    property bool isTesting: false
    property bool isUserTyping: false

    signal connectionFailed(string ssid)
    signal connectionSuccess(string ssid)

    readonly property string helperScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/wifi_nm.py"

    function refresh(fullScan) {
        let doScan = (fullScan !== undefined) ? fullScan : Variables.quickSettingsOpen;
        stateProc.command = ["python3", helperScript, doScan ? "json" : "status"];
        if (!stateProc.running) {
            stateProc.running = true;
        }
    }

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
        if (password && password !== "") {
            actionProc.command = ["python3", helperScript, "connect", ssid, password];
        } else {
            actionProc.command = ["python3", helperScript, "connect", ssid];
        }
        actionProc.running = true;
    }

    function disconnect() {
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
        command: ["python3", helperScript, "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    let data = JSON.parse(text);
                    if (data.isAirplane !== undefined) service.isAirplane = data.isAirplane;
                    if (data.currentState !== undefined) service.currentState = data.currentState;
                    if (data.currentSsid !== undefined) service.currentSsid = data.currentSsid;
                    if (data.ipv4Address !== undefined) service.ipv4Address = data.ipv4Address;
                    if (data.knownDict) service.knownNetworks = data.knownDict;
                    if (data.networks && Array.isArray(data.networks)) {
                        service.networks = data.networks;
                    }
                } catch (e) {
                    console.log("WifiService JSON parse error:", e);
                }
            }
        }
    }

    property string _pendingConnectSsid: ""

    Process {
        id: actionProc
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

    Component.onCompleted: service.refresh()

    // Adaptive Recurring Task Scheduler Timer
    Timer {
        id: statusPollTimer
        interval: Variables.quickSettingsOpen ? Variables.mediumInterval : Variables.slowInterval
        running: !service.isUserTyping
        repeat: true
        onTriggered: service.refresh(Variables.quickSettingsOpen)
    }
}
