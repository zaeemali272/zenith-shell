// services/BatteryService.qml
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: service

    // Core Properties
    property int percentage: -1
    property string status: "unknown"
    property bool acOnline: false
    
    // Technical Detail Properties
    property int cycleCount: 0
    property real voltage: 0.0
    property real energyRate: 0.0

    // Internal State
    property string batPath: ""
    property string acPath: ""
    property string lastStatus: ""
    property int lastThreshold: 100
    property int updatesReceived: 0
    property string timeRemaining: "Calculating..."
    property real energyNow: 0.0
    property real health: 0
    property real temp: 0

    function update() {
        if (service.batPath && service.acPath) {
            updateExec.running = true;
        }
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

        // Triggers for "Conservative/Limit" states as well
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

    function formatTime(seconds) {
        if (seconds <= 0 || isNaN(seconds) || seconds === Infinity) return "N/A";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        return h + "h " + m + "m";
    }


    Process {
        id: updateExec
        command: ["sh", "-c", `
            cat ${service.batPath}/capacity \
                ${service.batPath}/status \
                ${service.acPath}/online \
                ${service.batPath}/cycle_count \
                ${service.batPath}/voltage_now \
                ${service.batPath}/power_now \
                ${service.batPath}/energy_now \
                ${service.batPath}/energy_full \
                ${service.batPath}/energy_full_design
            cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                const parts = text.trim().split("\n");
                
                // We need at least 9 parts from the first cat, 
                // parts[9] will be the temperature from the second cat
                if (parts.length >= 9) {
                    // 1. Core Info
                    service.percentage = parseInt(parts[0]);
                    service.status = parts[1].toLowerCase().trim();
                    service.acOnline = parts[2].trim() === "1";
                    
                    // 2. Tech Details
                    service.cycleCount = Number(parts[3]) || 0;
                    service.voltage = Number(parts[4]) || 0;
                    service.energyRate = Number(parts[5]) || 0;
                    service.energyNow = Number(parts[6]) || 0;
                    
                    // 3. Health Calculation
                    let full = Number(parts[7]) || 1;
                    let design = Number(parts[8]) || 1;
                    service.health = (full / design) * 100;

                    // 4. Temperature (Index 9 from the second cat command)
                    if (parts.length > 9) {
                        service.temp = parseInt(parts[9]) / 1000;
                    }

                    // 5. Time Remaining Calculation
                    if (service.status === "discharging" && service.energyRate > 0) {
                        let secondsLeft = (service.energyNow / service.energyRate) * 3600;
                        service.timeRemaining = service.formatTime(secondsLeft);
                    } else if (service.status === "charging" && service.energyRate > 0) {
                        let energyFull = Number(parts[7]) || 40870000; 
                        let secondsToFull = ((energyFull - service.energyNow) / service.energyRate) * 3600;
                        service.timeRemaining = service.formatTime(secondsToFull) + " to full";
                    } else {
                        service.timeRemaining = "N/A";
                    }
                }
            }
        }
    }

    Process { id: notifyProc }

    Timer {
        id: pollTimer
        interval: 2000 // Increased to 2s to reduce overhead, update() is manual enough
        running: false
        repeat: true
        onTriggered: service.update()
    }
}