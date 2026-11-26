import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: service

    property string currentProfile: "balanced"
    property bool available: true
    property bool autoSwitchEnabled: false

    readonly property string powerProfileScript: PathSettings.scriptsDir + "/power_profile.sh"

    Connections {
        target: BatteryService
        function onAcOnlineChanged() {
            if (!service.available || !service.autoSwitchEnabled) return;
            if (BatteryService.updatesReceived < 2) return;

            if (BatteryService.acOnline) {
                service.setProfile("performance");
            } else {
                service.setProfile("balanced");
            }
        }
    }

    function setProfile(profile) {
        let target = profile;
        if (target === "powersave") target = "power-saver";
        else if (target === "turbo") target = "performance";

        // Optimistically update so UI button activates immediately with 0ms delay
        service.currentProfile = profile;
        service.autoSwitchEnabled = false;

        setExec.command = ["bash", service.powerProfileScript, "set", target];
        setExec.running = false;
        setExec.running = true;
    }

    function update() {
        updateExec.running = false;
        updateExec.running = true;
    }

    Component.onCompleted: {
        service.update();
    }

    // ---- Battery conservation / charge limit ----
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
                service.refreshConservative();
            }
        }
    }

    Process {
        id: updateExec
        command: ["bash", service.powerProfileScript, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "") {
                    service.available = true;
                    let prof = text.trim();
                    if (prof === "power-saver") prof = "powersave";
                    if (service.currentProfile !== "turbo" || prof !== "performance") {
                        service.currentProfile = prof;
                    }
                }
            }
        }
        onExited: (code) => {
            if (code !== 0) {
                service.available = false;
            }
        }
    }

    Process {
        id: setExec
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "") console.log("power profile set:", text.trim());
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "") console.warn("power profile set error:", text.trim());
            }
        }
        onExited: (code) => {
            if (code !== 0) {
                console.warn("power profile set failed with code:", code);
            }
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
