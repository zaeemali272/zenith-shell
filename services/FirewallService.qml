pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool enabled: false

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: checkStatus()
    }

    Component.onCompleted: checkStatus()

    function checkStatus() {
        if (statusProc.running) return;
        statusProc.command = ["sudo", "secure-mode", "status"];
        statusProc.running = true;
    }

    function toggle(on) {
        if (toggleProc.running) return;
        let cmd = ["sudo", "secure-mode", on ? "on" : "off"];
        toggleProc.command = cmd;
        toggleProc.running = true;
    }

    Process {
        id: statusProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.includes("Status:")) {
                    root.enabled = text.includes("Status: active");
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("Firewall status check failed:", exitCode, exitStatus);
            }
        }
    }

    Process {
        id: toggleProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("Firewall toggle failed:", exitCode, exitStatus);
            }
            checkStatus();
        }
    }
}
