// services/CaffeineService.qml
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
        active = true;
        inhibitProc.command = ["sh", "-c", "systemd-inhibit --what=idle --who=Quickshell-Caffeine --why='Keep Awake' --mode=block sleep infinity & echo $! > /dev/shm/zenith_caffeine.pid"];
        inhibitProc.running = false;
        inhibitProc.running = true;

        notifyProc.command = ["notify-send", "-a", "Caffeine", "-i", "preferences-desktop-screensaver", "Caffeine Enabled", "Screen idle and sleep disabled."];
        notifyProc.running = false;
        notifyProc.running = true;
    }

    function disable() {
        active = false;
        killProc.command = ["sh", "-c", "if [ -f /dev/shm/zenith_caffeine.pid ]; then kill $(cat /dev/shm/zenith_caffeine.pid) 2>/dev/null; rm -f /dev/shm/zenith_caffeine.pid; fi; pkill -f 'Quickshell-Caffeine' 2>/dev/null || true"];
        killProc.running = false;
        killProc.running = true;

        notifyProc.command = ["notify-send", "-a", "Caffeine", "-i", "preferences-desktop-screensaver", "Caffeine Disabled", "Screen idle and sleep restored."];
        notifyProc.running = false;
        notifyProc.running = true;
    }

    Process { id: inhibitProc }
    Process { id: killProc }
    Process { id: notifyProc }

    // Check initial state on completion
    Component.onCompleted: checkState.running = true

    Process {
        id: checkState
        command: ["pgrep", "-f", "Quickshell-Caffeine"]
        stdout: StdioCollector {
            onStreamFinished: {
                service.active = (text && text.trim() !== "");
            }
        }
    }
}
