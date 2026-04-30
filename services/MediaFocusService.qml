import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property var lastPlayerBus: ""
    property var currentPlayerBus: ""
    property bool enabled: true

    function log(msg) {
        console.log("[MediaFocus] " + msg);
    }

    // This process monitors playerctl for playback status changes
    // Added -F to follow/monitor changes in real-time
    Process {
        id: monitor
        command: ["playerctl", "-F", "metadata", "-f", "{{status}} {{instance}}"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                // StdioCollector text contains the full buffer. 
                // We split by newline and take the last line or process all.
                let lines = text.trim().split("\n");
                let lastLine = lines[lines.length - 1];
                if (lastLine) handleLine(lastLine);
            }
        }
        
        // Restart if it crashes
        onExited: {
            log("Monitor process exited. Restarting...");
            running = false;
            restartTimer.start();
        }
    }

    Timer {
        id: restartTimer
        interval: 2000
        onTriggered: monitor.running = true
    }

    function handleLine(line) {
        if (!enabled || !line) return;
        
        let parts = line.split(" ");
        if (parts.length < 2) return;
        
        let status = parts[0];
        let bus = parts[1];

        if (status === "Playing") {
            if (currentPlayerBus !== "" && currentPlayerBus !== bus) {
                log(bus + " started. Pausing " + currentPlayerBus);
                pausePlayer(currentPlayerBus);
                lastPlayerBus = currentPlayerBus;
            }
            currentPlayerBus = bus;
        } else if (status === "Paused" || status === "Stopped") {
            if (currentPlayerBus === bus) {
                if (lastPlayerBus !== "" && lastPlayerBus !== bus) {
                    log(bus + " stopped. Resuming " + lastPlayerBus);
                    resumeTimer.busToResume = lastPlayerBus;
                    resumeTimer.restart();
                }
                currentPlayerBus = "";
            }
        }
    }

    function pausePlayer(bus) {
        pauseExec.command = ["playerctl", "-p", bus, "pause"];
        pauseExec.running = true;
    }

    function resumePlayer(bus) {
        resumeExec.command = ["playerctl", "-p", bus, "play"];
        resumeExec.running = true;
        lastPlayerBus = "";
    }

    Process { id: pauseExec }
    Process { id: resumeExec }

    Timer {
        id: resumeTimer
        interval: 500
        repeat: false
        property string busToResume: ""
        onTriggered: {
            if (busToResume !== "") {
                resumePlayer(busToResume);
            }
        }
    }

    Component.onCompleted: log("Service initialized (Follow mode).")
}
