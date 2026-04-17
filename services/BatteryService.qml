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

    function getIconName(p, s) {
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
        return name;
    }

    function sendNotify(title, msg, urgency) {
        if (updatesReceived < 2 || status === "" || status === "unknown")
            return;

        let iconName = getIconName(percentage, status);
        let u = urgency || "normal";
        notifyProc.command = ["notify-send", "-u", u, "-a", "Battery", "-i", iconName, title, msg];
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
        command: ["sh", "-c", "echo BATS=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null); echo AC=$(ls -d /sys/class/power_supply/AC* /sys/class/power_supply/ADP* /sys/class/power_supply/Mains* 2>/dev/null | head -n1)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                lines.forEach((l) => {
                    if (l.startsWith("BATS=")) service.batPath = l.slice(5);
                    if (l.startsWith("AC=")) service.acPath = l.slice(3);
                });
                if (service.batPath) {
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
            AC="${service.acPath}"
            [ -n "$AC" ] && cat "$AC/online" 2>/dev/null || echo 0
            
            for B in ${service.batPath}; do
                [ ! -d "$B" ] && continue
                cat "$B/capacity" 2>/dev/null || echo 0
                cat "$B/status" 2>/dev/null || echo unknown
                cat "$B/cycle_count" 2>/dev/null || echo 0
                cat "$B/voltage_now" 2>/dev/null || cat "$B/voltage_avg" 2>/dev/null || echo 0
                
                # Rate
                if [ -f "$B/power_now" ]; then cat "$B/power_now"
                elif [ -f "$B/current_now" ]; then cat "$B/current_now"
                else echo 0; fi
                
                # Now
                if [ -f "$B/energy_now" ]; then cat "$B/energy_now"
                elif [ -f "$B/charge_now" ]; then cat "$B/charge_now"
                else echo 0; fi
                
                # Full
                if [ -f "$B/energy_full" ]; then cat "$B/energy_full"
                elif [ -f "$B/charge_full" ]; then cat "$B/charge_full"
                else echo 0; fi
                
                # Design
                if [ -f "$B/energy_full_design" ]; then cat "$B/energy_full_design"
                elif [ -f "$B/charge_full_design" ]; then cat "$B/charge_full_design"
                else echo 0; fi
            done
            
            # Temperature
            cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1 || echo 0
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                const parts = text.trim().split("\n");
                if (parts.length < 2) return;
                
                service.acOnline = parts[0].trim() === "1";
                
                let totalEnergyNow = 0;
                let totalEnergyFull = 0;
                let totalEnergyDesign = 0;
                let totalRate = 0;
                let totalVoltage = 0;
                let totalCycles = 0;
                let mainStatus = "unknown";
                let batCount = 0;

                // Each battery provides 8 lines of data
                for (let i = 1; i < parts.length - 1; i += 8) {
                    if (i + 7 >= parts.length - 1) break;
                    
                    batCount++;
                    let cap = parseInt(parts[i]);
                    let stat = parts[i+1].toLowerCase().trim();
                    let cycles = parseInt(parts[i+2]);
                    let volt = parseInt(parts[i+3]);
                    let rate = Math.abs(parseInt(parts[i+4]));
                    let now = parseInt(parts[i+5]);
                    let full = parseInt(parts[i+6]);
                    let design = parseInt(parts[i+7]);

                    totalEnergyNow += now;
                    totalEnergyFull += full;
                    totalEnergyDesign += design;
                    totalRate += rate;
                    totalVoltage += volt;
                    totalCycles += cycles;

                    if (stat === "charging") mainStatus = "charging";
                    else if (stat === "discharging" && mainStatus !== "charging") mainStatus = "discharging";
                    else if (stat === "full" && mainStatus === "unknown") mainStatus = "full";
                    else if (mainStatus === "unknown") mainStatus = stat;
                }

                if (batCount > 0) {
                    service.percentage = totalEnergyFull > 0 ? Math.round((totalEnergyNow / totalEnergyFull) * 100) : 0;
                    service.status = mainStatus;
                    service.cycleCount = totalCycles;
                    service.voltage = (totalVoltage / batCount) / 1000000;
                    service.energyRate = totalRate;
                    service.energyNow = totalEnergyNow;
                    service.health = totalEnergyDesign > 0 ? (totalEnergyFull / totalEnergyDesign) * 100 : 0;
                    
                    if (service.status === "discharging" && totalRate > 0) {
                        service.timeRemaining = service.formatTime((totalEnergyNow / totalRate) * 3600);
                    } else if (service.status === "charging" && totalRate > 0) {
                        service.timeRemaining = service.formatTime(((totalEnergyFull - totalEnergyNow) / totalRate) * 3600) + " to full";
                    } else {
                        service.timeRemaining = "N/A";
                    }
                }

                // Last line is temp
                if (parts.length > 0) {
                    service.temp = parseInt(parts[parts.length - 1]) / 1000;
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