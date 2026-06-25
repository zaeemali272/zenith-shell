pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

Item {
    id: root

    property bool enabled: FirewallSettings.enabled

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: checkStatus()
    }

    Component.onCompleted: {
        // Apply persisted state on startup
        toggle(FirewallSettings.enabled);
    }

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
        enabled = on;
        FirewallSettings.enabled = on;
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
            }
        }
    }

    Process {
        id: toggleProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
            }
            checkStatus();
        }
    }
}
