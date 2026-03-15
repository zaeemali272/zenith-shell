import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    // --- PROCESS HANDLING ---
    // --- SCAN & INIT ---

    id: service

    property var networks: []
    property var knownNetworks: ({
    })
    readonly property string secretsPath: Quickshell.env("HOME") + "/.config/quickshell/wifi_secrets.json"
    property string _pendingForgetSsid: ""
    property string _pendingConnectSsid: ""
    property string _pendingPassword: ""

    function scan() {
        listProcess.running = false;
        listProcess.running = true;
    }

    function connect(ssid, password) {
        let storedPass = knownNetworks[ssid] || "";
        let pass = (password && password !== "") ? password : storedPass;
        console.log("DEBUG: [1/4] Connect requested for: " + ssid);
        _pendingConnectSsid = ssid;
        _pendingPassword = pass;
        executor.running = false;
        if (pass !== "")
            // Using positional arguments to handle '$' and spaces safely
            executor.command = ["sh", "-c", 'iwctl station $(ls /sys/class/net | grep ^wl | head -n1) connect "$1" --passphrase "$2"', "sh", ssid, pass];
        else
            executor.command = ["sh", "-c", 'iwctl station $(ls /sys/class/net | grep ^wl | head -n1) connect "$1"', "sh", ssid];
        executor.running = true;
    }

    function forgetNetwork(ssid) {
        if (!ssid)
            return ;

        _pendingForgetSsid = ssid;
        executor.running = false;
        executor.command = ["sh", "-c", 'iwctl known-networks "$1" forget; iwctl station $(ls /sys/class/net | grep ^wl | head -n1) disconnect', "sh", ssid];
        executor.running = true;
    }

    function saveSecrets() {
        let jsonStr = JSON.stringify(knownNetworks);
        console.log("DEBUG: [3/4] saveSecrets writing: " + jsonStr);
        saveSecretsProc.running = false;
        saveSecretsProc.command = ["sh", "-c", 'printf "%s" "$1" > "$2"', "sh", jsonStr, secretsPath];
        saveSecretsProc.running = true;
    }

    Component.onCompleted: initSecrets.running = true

    Process {
        id: executor

        // FIX: In your version, the signal is 'exited', handler is 'onExited'
        onExited: (exitCode) => {
            console.log("DEBUG: [2/4] Connection process finished. Exit Code: " + exitCode);
            // --- FORGET ---
            if (_pendingForgetSsid !== "") {
                let temp = JSON.parse(JSON.stringify(knownNetworks));
                if (temp.hasOwnProperty(_pendingForgetSsid)) {
                    delete temp[_pendingForgetSsid];
                    knownNetworks = temp;
                    saveSecrets();
                }
                _pendingForgetSsid = "";
            }
            // --- CONNECT ---
            if (_pendingConnectSsid !== "") {
                if (exitCode === 0) {
                    console.log("DEBUG: [SUCCESS] Saving to secrets file.");
                    if (_pendingPassword !== "") {
                        let temp = JSON.parse(JSON.stringify(knownNetworks));
                        temp[_pendingConnectSsid] = _pendingPassword;
                        knownNetworks = temp;
                        saveSecrets();
                    }
                } else {
                    console.log("DEBUG: [ERROR] iwctl failed with code " + exitCode);
                }
                _pendingConnectSsid = "";
                _pendingPassword = "";
            }
            service.scan();
        }
    }

    Process {
        id: saveSecretsProc

        onExited: (exitCode) => {
            console.log("DEBUG: [4/4] File write finished. Exit Code: " + exitCode);
        }
    }

    Process {
        id: initSecrets

        command: ["sh", "-c", `[ ! -f "${secretsPath}" ] && echo "{}" > "${secretsPath}"; cat "${secretsPath}"`]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text.trim()) {
                        service.knownNetworks = JSON.parse(text);
                        console.log("DEBUG: [INIT] Loaded secrets for: " + Object.keys(service.knownNetworks).join(", "));
                    }
                } catch (e) {
                    console.log("DEBUG: Init error: " + e);
                }
                service.scan();
            }
        }

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

}
