// services/BatteryService.qml
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: service

    property int percentage: -1
    property string status: "unknown"
    property bool acOnline: false
    property string batPath: ""
    property string acPath: ""

    // Notification State
    property string lastStatus: ""
    property int lastThreshold: 100
    property int updatesReceived: 0

    function update() {
        updateExec.running = true;
    }

    function getIconPath(p, s) {
        const basePath = "/usr/share/icons/OneUI/symbolic/status/";
        let name = "";
        if (s === "charging" || s === "full") {
            if (p >= 100) name = "battery-level-100-charged-symbolic";
            else if (p >= 90) name = "battery-level-90-charging-symbolic";
            else if (p >= 80) name = "battery-level-80-charging-symbolic";
            else if (p >= 70) name = "battery-level-70-charging-symbolic";
            else if (p >= 60) name = "battery-level-60-charging-symbolic";
            else if (p >= 50) name = "battery-level-50-charging-symbolic";
            else if (p >= 40) name = "battery-level-40-charging-symbolic";
            else if (p >= 30) name = "battery-level-30-charging-symbolic";
            else if (p >= 20) name = "battery-level-20-charging-symbolic";
            else if (p >= 10) name = "battery-level-10-charging-symbolic";
            else name = "battery-level-0-charging-symbolic";
        } else {
            if (p >= 100) name = "battery-level-100-symbolic";
            else if (p >= 90) name = "battery-level-90-symbolic";
            else if (p >= 80) name = "battery-level-80-symbolic";
            else if (p >= 70) name = "battery-level-70-symbolic";
            else if (p >= 60) name = "battery-level-60-symbolic";
            else if (p >= 50) name = "battery-level-50-symbolic";
            else if (p >= 40) name = "battery-level-40-symbolic";
            else if (p >= 30) name = "battery-level-30-symbolic";
            else if (p >= 20) name = "battery-level-20-symbolic";
            else if (p >= 10) name = "battery-level-10-symbolic";
            else name = "battery-level-0-symbolic";
        }
        return basePath + name + ".svg";
    }

    function sendNotify(title, msg, urgency) {
        if (updatesReceived < 2 || status === "" || status === "unknown")
            return;

        let iconPath = getIconPath(percentage, status);
        let u = urgency || "normal";
        notifyProc.command = ["notify-send", "-u", u, "-a", "Battery", "-i", iconPath, title, msg];
        notifyProc.running = true;
    }

    onStatusChanged: {
        let s = status.toLowerCase().trim();
        if (updatesReceived < 2) {
            if (s !== "" && s !== "unknown") {
                lastStatus = s;
                updatesReceived++;
            }
            return;
        }

        if (s === lastStatus || s === "unknown" || s === "") return;

        if (s === "charging" || (s === "full" && lastStatus === "discharging") || (s === "not charging" && lastStatus === "discharging")) {
            sendNotify("Power Connected", "Finally, I can breathe again. Thanks for the juice.");
        } else if (s === "discharging") {
            sendNotify("Power Disconnected", "Running Wild. Hope you're near an outlet.");
        }
        lastStatus = s;
    }

    onPercentageChanged: {
        if (updatesReceived < 2) {
            if (percentage > 0) {
                if (percentage <= 1) lastThreshold = 1;
                else if (percentage <= 3) lastThreshold = 3;
                else if (percentage <= 5) lastThreshold = 5;
                else if (percentage <= 10) lastThreshold = 10;
                else if (percentage <= 20) lastThreshold = 20;
                else lastThreshold = 100;
                updatesReceived++;
            }
            return;
        }

        if (status === "charging" || status === "full" || status === "not charging") {
            if (percentage > 20 && lastThreshold !== 100) lastThreshold = 100;
            return;
        }

        if (percentage <= 1 && lastThreshold > 1) {
            sendNotify("Goodbye, Cruel World", "1%? This is it.", "critical");
            lastThreshold = 1;
        } else if (percentage <= 3 && lastThreshold > 3) {
            sendNotify("Panic Mode", "3% left.", "critical");
            lastThreshold = 3;
        } else if (percentage <= 5 && lastThreshold > 5) {
            sendNotify("Critical", "5%. PLUG. ME. IN.", "critical");
            lastThreshold = 5;
        } else if (percentage <= 10 && lastThreshold > 10) {
            sendNotify("Low Battery", "10%. Getting dangerously low.", "critical");
            lastThreshold = 10;
        } else if (percentage <= 20 && lastThreshold > 20) {
            sendNotify("Battery Warning", "20%. Just a heads up, I'm getting hungry.", "normal");
            lastThreshold = 20;
        }
    }

    Component.onCompleted: findPaths.running = true

    Process {
        id: findPaths
        command: ["sh", "-c", "echo BAT=$(ls -d /sys/class/power_supply/BAT* | head -n1); echo AC=$(ls -d /sys/class/power_supply/AC* /sys/class/power_supply/ADP* 2>/dev/null | head -n1)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                lines.forEach((l) => {
                    if (l.startsWith("BAT=")) service.batPath = l.slice(4);
                    if (l.startsWith("AC=")) service.acPath = l.slice(3);
                });
                if (service.batPath && service.acPath) {
                    service.update();
                    pollTimer.running = true;
                }
            }
        }
    }

    Process {
        id: updateExec
        command: ["sh", "-c", `cat ${service.batPath}/capacity ${service.batPath}/status ${service.acPath}/online`]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                const parts = text.trim().split("\n");
                if (parts.length >= 3) {
                    service.percentage = parseInt(parts[0]);
                    service.status = parts[1].toLowerCase().trim();
                    service.acOnline = parts[2] === "1";
                }
            }
        }
    }

    Process { id: notifyProc }

    Timer {
        id: pollTimer
        interval: 2000
        running: false
        repeat: true
        onTriggered: service.update()
    }
}
