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
    readonly property bool isRefreshing: stateProc.running

    signal connectionFailed(string ssid)
    signal connectionSuccess(string ssid)

    readonly property string helperScript: PathSettings.scriptsDir + "/wifi_nm.py"

    // A full scan passes --rescan yes to nmcli, which takes ~5 seconds because
    // it drives an actual hardware rescan. A cheap status read is ~70ms.
    //
    // Restarting the process mid-flight (what this used to do unconditionally)
    // threw away an in-progress 5 second scan and started another, so a burst
    // of refresh requests could keep cancelling each other and the list would
    // never actually arrive. Let whatever is already running finish instead.
    function refresh(fullScan) {
        if (stateProc.running) return;

        let doScan = (fullScan !== undefined) ? fullScan : (Variables.quickSettingsOpen || Variables.controlCenterOpen);
        _requestScanned = doScan;
        stateProc.command = ["python3", helperScript, doScan ? "json" : "status"];
        stateProc.running = true;
    }

    // Force a full rescan even if a cheap status read is in flight -- used
    // when the user explicitly opens the panel or hits the refresh button,
    // where waiting on an unrelated poll would feel broken.
    function rescan() {
        stateProc.running = false;
        _requestScanned = true;
        stateProc.command = ["python3", helperScript, "json"];
        stateProc.running = true;
    }

    // True when the reply currently being awaited came from a request that
    // actually scanned. The helper always emits a `networks` key, but in
    // status mode it emits an empty list because it never looked -- and an
    // empty JS array is truthy, so the old check happily assigned it and
    // wiped every network off the panel. Visible symptom: the list appeared
    // when the 5 second scan landed, then vanished on the next cheap poll.
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
                    // Only a real scan can authoritatively say what is on the
                    // air. A status read reports networks: [] purely because
                    // it did not scan, which must not be mistaken for "no
                    // networks in range".
                    if (service._requestScanned && Array.isArray(data.networks)) {
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

    // Instant NetworkManager Event Monitor
    Process {
        id: nmMonitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            // Cheap status read only. This used to pass
            // Variables.quickSettingsOpen, so while the panel was open every
            // single nmcli event kicked off a full 5 second hardware rescan --
            // and because scanning itself changes NetworkManager state, those
            // scans re-triggered each other. The radio ended up scanning
            // essentially non-stop and the cheap polls were permanently
            // starved behind the guard. Full rescans are driven deliberately
            // instead: on panel open, on the refresh button, and every 20s.
            onRead: (data) => service.refresh(false)
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
