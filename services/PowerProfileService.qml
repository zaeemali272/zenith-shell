import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: service

    readonly property string home: Quickshell.env("HOME")
    readonly property string daemonPath: home + "/.local/bin/power-profile-daemon.sh"
    readonly property string stateFile: home + "/.cache/power-profile-state"
    
    property string currentProfile: "balanced"
    property bool available: false

    function setProfile(profile) {
        if (!available) return;
        setExec.command = [daemonPath, profile];
        setExec.running = true;
    }

    function update() {
        if (!available) return;
        updateExec.running = true;
    }

    Component.onCompleted: checkAvailability.running = true

    Process {
        id: checkAvailability
        command: ["ls", daemonPath]
        onExited: (code) => {
            if (code === 0) {
                service.available = true;
                service.update();
                // Ensure state file exists before watching
                ensureStateFile.running = true;
            } else {
                console.warn("power-profile-daemon.sh not found. PowerProfileService disabled.");
            }
        }
    }

    Process {
        id: ensureStateFile
        command: ["touch", service.stateFile]
        onExited: watcher.running = true
    }

    Process {
        id: updateExec
        command: [daemonPath, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) service.currentProfile = text.trim();
            }
        }
    }

    Process {
        id: setExec
        onExited: service.update()
    }

    // Reactive watcher: waits for one change, then restarts
    Process {
        id: watcher
        command: ["sh", "-c", "inotifywait -q -e close_write " + service.stateFile]
        running: false
        onExited: {
            service.update();
            restartTimer.start();
        }
    }

    Timer {
        id: restartTimer
        interval: 100
        onTriggered: watcher.running = true
    }

    // Fallback sync
    Timer {
        interval: 300000 // 5 minutes
        running: service.available
        repeat: true
        onTriggered: service.update()
    }
}
