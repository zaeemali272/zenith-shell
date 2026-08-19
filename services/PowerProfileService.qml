import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

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

    // ---- Battery conservation / charge limit ----
    //
    // PowerProfileContent has always had a card bound to conservativeSupported,
    // conservativeActive, conservativeLabel and toggleConservativeMode(). None
    // of them existed here, so the bindings evaluated to undefined: the card
    // stayed hidden and the toggle did nothing at all.
    property bool conservativeSupported: false
    property bool conservativeActive: false
    property string conservativeLabel: ""
    property string conservativeError: ""

    readonly property string conservationScript: PathSettings.scriptsDir + "/battery_conservation.sh"

    function refreshConservative() {
        consStatus.running = false;
        consStatus.running = true;
    }

    function toggleConservativeMode() {
        consToggle.command = ["bash", service.conservationScript, "toggle"];
        consToggle.running = false;
        consToggle.running = true;
    }

    property Process _consStatus: Process {
        id: consStatus
        running: true
        command: ["bash", service.conservationScript, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var r = JSON.parse(String(text).trim() || "{}");
                    service.conservativeSupported = !!r.supported;
                    service.conservativeActive = !!r.active;
                    service.conservativeLabel = r.label || "Battery Care";
                } catch (e) { service.conservativeSupported = false; }
            }
        }
    }

    property Process _consToggle: Process {
        id: consToggle
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var r = JSON.parse(String(text).trim() || "{}");
                    service.conservativeError = r.ok ? "" : (r.error || "failed");
                } catch (e) { service.conservativeError = "failed"; }
                // Re-read rather than assuming the write landed: it can be
                // refused by permissions, and the card must not claim a state
                // the hardware is not in.
                service.refreshConservative();
            }
        }
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
        interval: Variables.slowInterval
        running: service.available && Variables.quickSettingsOpen
        repeat: true
        onTriggered: service.update()
    }
}
