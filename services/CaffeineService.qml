import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: service

    property bool active: false

    function toggle() {
        if (active) {
            disable();
        } else {
            enable();
        }
    }

    function enable() {
        console.log("Caffeine: Enabling (Stopping hypridle)");
        active = true;
        inhibitProc.command = ["systemctl", "--user", "stop", "hypridle"];
        inhibitProc.running = true;
        notifyProc.command = ["notify-send", "-a", "Caffeine", "-i", "my-caffeine-on-symbolic", "Caffeine Enabled", "Hypridle is now disabled."];
        notifyProc.running = true;
    }

    function disable() {
        console.log("Caffeine: Disabling (Starting hypridle)");
        active = false;
        inhibitProc.command = ["systemctl", "--user", "start", "hypridle"];
        inhibitProc.running = true;
        notifyProc.command = ["notify-send", "-a", "Caffeine", "-i", "my-caffeine-off-symbolic", "Caffeine Disabled", "Hypridle is back on."];
        notifyProc.running = true;
    }

    Process { 
        id: inhibitProc 
        onExited: (code) => console.log("Caffeine: Process exited with code " + code)
    }
    Process { id: notifyProc }

    // Check initial state
    Component.onCompleted: checkState.running = true

    Process {
        id: checkState
        command: ["systemctl", "--user", "is-active", "hypridle"]
        stdout: StdioCollector {
            onStreamFinished: {
                service.active = (text && text.trim() !== "active");
            }
        }
    }
}
