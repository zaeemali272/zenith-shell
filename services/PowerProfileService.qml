import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

Item {
    id: service

    property string currentProfile: "balanced"
    property bool available: false

    function setProfile(profile) {
        if (!available) return;

        let target = profile;
        if (target === "powersave") target = "power-saver";
        else if (target === "turbo") target = "performance";

        setExec.command = ["powerprofilesctl", "set", target];
        setExec.running = false;
        setExec.running = true;
    }

    function update() {
        if (!available) return;
        updateExec.running = false;
        updateExec.running = true;
    }

    Component.onCompleted: {
        checkAvailability.running = true;
    }

    Process {
        id: checkAvailability
        command: ["which", "powerprofilesctl"]
        onExited: (code) => {
            if (code === 0) {
                service.available = true;
                service.update();
            } else {
                console.warn("powerprofilesctl not found. PowerProfileService disabled.");
            }
        }
    }

    Process {
        id: updateExec
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    let prof = text.trim();
                    if (prof === "power-saver") prof = "powersave";
                    service.currentProfile = prof;
                }
            }
        }
    }

    Process {
        id: setExec
        onExited: (code) => {
            service.update();
        }
    }

    Timer {
        interval: Variables.quickSettingsOpen ? Variables.slowInterval : Variables.lazyInterval
        running: service.available
        repeat: true
        onTriggered: service.update()
    }
}
