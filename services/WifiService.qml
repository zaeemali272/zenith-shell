import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: service

    property var networks: []
    property var knownNetworks: ({})
    readonly property string secretsPath: Quickshell.env("HOME") + "/.config/quickshell/wifi_secrets.json"
    
    property string currentSpeed: "0.0 Mbps"
    property bool isTesting: false

    function refresh() {
        startHardwareScan();
        runMaxSpeedTest();
    }

    function startHardwareScan() {
        scanProcess.running = false;
        scanProcess.running = true;
    }

    function updateNetworkList() {
        listProcess.running = false;
        listProcess.running = true;
    }

    function runMaxSpeedTest() {
        if (isTesting) return;
        isTesting = true;
        speedTestProcess.running = false;
        speedTestProcess.running = true;
    }

    function connect(ssid, password) {
        let storedPass = knownNetworks[ssid] || "";
        let pass = (password && password !== "") ? password : storedPass;
        _pendingConnectSsid = ssid;
        _pendingPassword = pass;
        executor.running = false;
        executor.command = pass !== "" 
            ? ["sh", "-c", 'iwctl station $(ls /sys/class/net | grep ^wl | head -n1) connect "$1" --passphrase "$2"', "sh", ssid, pass]
            : ["sh", "-c", 'iwctl station $(ls /sys/class/net | grep ^wl | head -n1) connect "$1"', "sh", ssid];
        executor.running = true;
    }

    function forgetNetwork(ssid) {
        if (!ssid) return;
        _pendingForgetSsid = ssid;
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
        id: listProcess
        command: ["sh", "-c", "iwctl station $(ls /sys/class/net | grep ^wl | head -n1) get-networks | sed 's/\\x1b\\[[0-9;]*m//g' | awk 'NR>4 {print $0}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n");
                let temp = [];
                for (let line of lines) {
                    let isConnected = line.includes(' > ');
                    let parts = line.replace('>', '').trim().split(/\s\s+/);
                    if (parts.length >= 2)
                        temp.push({
                            "ssid": parts[0].trim(),
                            "security": parts[1].trim().toLowerCase(),
                            "connected": isConnected
                        });
                }
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

    property string _pendingForgetSsid: ""
    property string _pendingConnectSsid: ""
    property string _pendingPassword: ""

    Process {
        id: executor
        onExited: (exitCode) => {
            if (exitCode === 0) {
                let temp = JSON.parse(JSON.stringify(knownNetworks));
                if (_pendingForgetSsid !== "") delete temp[_pendingForgetSsid];
                if (_pendingConnectSsid !== "" && _pendingPassword !== "") temp[_pendingConnectSsid] = _pendingPassword;
                knownNetworks = temp;
                
                let jsonStr = JSON.stringify(knownNetworks);
                saveSecretsProc.command = ["sh", "-c", 'printf "%s" "$1" > "$2"', "sh", jsonStr, secretsPath];
                saveSecretsProc.running = true;
            }
            _pendingForgetSsid = ""; _pendingConnectSsid = ""; _pendingPassword = "";
            service.refresh();
        }
    }

    Process { id: saveSecretsProc }
    
    Process {
        id: initSecrets
        command: ["sh", "-c", `[ ! -f "${secretsPath}" ] && echo "{}" > "${secretsPath}"; cat "${secretsPath}"`]
        stdout: StdioCollector {
            onStreamFinished: {
                try { if (text.trim()) service.knownNetworks = JSON.parse(text); } catch (e) {}
                service.refresh();
            }
        }
    }

    Component.onCompleted: initSecrets.running = true
}