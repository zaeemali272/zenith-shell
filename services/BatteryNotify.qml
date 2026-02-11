import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: notifyService

    property string lastStatus: ""
    property int lastThreshold: 100
    property int updatesReceived: 0 // New counter guard

    function sendNotify(title, msg, urgency) {
        // Only allow if we've received at least 2 updates and have a valid previous status
        if (updatesReceived < 2 || lastStatus === "" || lastStatus === "unknown")
            return ;

        let u = urgency || "normal";
        notifyProc.command = ["notify-send", "-u", u, "-a", "Battery", title, msg];
        notifyProc.running = true;
    }

    Connections {
        function onStatusChanged() {
            let s = BatteryService.status.toLowerCase().trim();
            // Increment update counter
            if (updatesReceived < 2) {
                if (s !== "" && s !== "unknown") {
                    lastStatus = s;
                    updatesReceived++;
                }
                return ;
            }
            if (s === lastStatus || s === "unknown" || s === "")
                return ;

            if (s === "charging")
                sendNotify("Power!", "Finally, I can breathe again. Thanks for the juice.");
            else if (s === "discharging")
                sendNotify("Running Wild", "Oh, so we're doing this now? Hope you're near an outlet.");
            lastStatus = s;
        }

        function onPercentageChanged() {
            let p = BatteryService.percentage;
            let s = BatteryService.status.toLowerCase().trim();
            // Setup logic for the first few seconds
            if (updatesReceived < 2) {
                if (p > 0) {
                    if (p <= 1)
                        lastThreshold = 1;
                    else if (p <= 3)
                        lastThreshold = 3;
                    else if (p <= 5)
                        lastThreshold = 5;
                    else if (p <= 10)
                        lastThreshold = 10;
                    else if (p <= 20)
                        lastThreshold = 20;
                    else
                        lastThreshold = 100;
                    updatesReceived++;
                }
                return ;
            }
            if (s === "charging" || s === "full") {
                if (p > 20 && lastThreshold !== 100)
                    lastThreshold = 100;

                return ;
            }
            // Notification triggers
            if (p <= 1 && lastThreshold > 1) {
                sendNotify("Goodbye, Cruel World", "1%? This is it.", "critical");
                lastThreshold = 1;
            } else if (p <= 3 && lastThreshold > 3) {
                sendNotify("Panic Mode", "3% left.", "critical");
                lastThreshold = 3;
            } else if (p <= 5 && lastThreshold > 5) {
                sendNotify("Critical", "5%. PLUG. ME. IN.", "critical");
                lastThreshold = 5;
            } else if (p <= 10 && lastThreshold > 10) {
                sendNotify("Low Battery", "10%. Are we trying to see how fast I can die?", "critical");
                lastThreshold = 10;
            } else if (p <= 20 && lastThreshold > 20) {
                sendNotify("Battery Warning", "20%. Just a heads up, I'm getting hungry.", "normal");
                lastThreshold = 20;
            }
        }

        target: BatteryService
    }

    Process {
        id: notifyProc
    }

}
