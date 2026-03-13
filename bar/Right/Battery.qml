// bar/Right/Battery.qml
import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var menuRef
    // Bindings to the Service
    readonly property int batPercent: BatteryService.percentage
    readonly property string batState: BatteryService.status
    readonly property bool acOnline: BatteryService.acOnline
    property bool btPresent: false
    property int btPercent: 0

    function batteryIcon(p, state, ac) {
        const isNotCharging = state.includes("not charging") || state.includes("idle") || state.includes("unknown") || state.includes("pending");
        if (ac && isNotCharging)
            return "";

        if (state === "charging")
            return Theme.chargingIcon;

        if (state === "full" || state === "fully-charged")
            return Theme.iconHigh;

        if (p >= Theme.high)
            return Theme.iconHigh;

        if (p >= Theme.mid)
            return Theme.iconMid;

        if (p >= Theme.low)
            return Theme.iconLow;

        return Theme.iconCritical;
    }

    function batteryColor(p, state, ac) {
        if (ac && state !== "charging" && state !== "full")
            return Theme.conserveColor;

        if (state === "charging")
            return Theme.chargingColor;

        if (p >= Theme.low)
            return Theme.midColor;

        return Theme.criticalColor;
    }

    // TRIGGER: Runs every time your laptop battery level changes.
    // This replaces the timer with a zero-load event listener.
    onBatPercentChanged: btExec.running = true
    
    Timer {
        id: btTimer
        interval: 15000 // Refresh every 15 seconds
        running: true
        repeat: true
        onTriggered: btExec.running = true
    }

    // --- HITBOX FIX ---
    // We base the size on the inner layout to ensure it's not 0px wide.
    implicitHeight: Theme.pillHeight
    implicitWidth: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
    Component.onCompleted: btExec.running = true
    onClicked: {
        console.log("Battery clicked! menuRef exists:", !!menuRef);
        if (menuRef) {
            menuRef.active = !menuRef.active;
            // Also refresh on manual click
            btExec.running = true;
        }
    }

    Pill {
        id: pill

        anchors.fill: parent
        onClicked: {
            console.log("Battery clicked! menuRef exists:", !!menuRef);
            if (menuRef) {
                // For Loaders, we toggle 'active'
                if (menuRef.active !== undefined) {
                    menuRef.active = !menuRef.active;
                } else {
                    // For direct instances, toggle 'visible'
                    menuRef.visible = !menuRef.visible;
                }
                // Refresh on manual click
                btExec.running = true;
            }
        }

        RowLayout {
            id: content

            anchors.centerIn: parent
            spacing: Theme.pillGap

            // Bluetooth Logic
            RowLayout {
                // Modified visibility to ensure it only shows when data is valid
                visible: btPresent
                spacing: 4

                Text {
                    text: Theme.btIcon || "󰂯"
                    font.family: Theme.iconFont
                    color: Theme.bluetoothColor
                }

                Text {
                    text: btPercent + "%"
                    color: Theme.bluetoothColor
                    font.pixelSize: Theme.fontSize
                }

            }

            Text {
                visible: (btPresent && btPercent > 0) && batPercent >= 0
                text: "|"
                color: Theme.inactiveTextColor
            }

            // Laptop Logic
            RowLayout {
                visible: batPercent >= 0
                spacing: 4

                Text {
                    text: batteryIcon(batPercent, batState, acOnline)
                    font.family: Theme.iconFont
                    color: batteryColor(batPercent, batState, acOnline)
                }

                Text {
                    text: batPercent + "%"
                    color: batteryColor(batPercent, batState, acOnline)
                    font.pixelSize: Theme.fontSize
                }

            }

        }

    }

    Process {
        id: btExec

        // Refined shell command for better parsing
        command: ["sh", "-c", "MAC=$(bluetoothctl devices Connected | awk '{print $2}' | head -n1); [ -n \"$MAC\" ] || { echo 'BT=0'; exit 0; }; RAW=$(bluetoothctl info \"$MAC\" | grep 'Battery Percentage' | awk -F '[()]' '{print $2}' | tr -d '[:space:]%'); [ -z \"$RAW\" ] && RAW=$(bluetoothctl info \"$MAC\" | grep 'Battery Percentage' | awk '{print $3}' | tr -d '[:space:]%'); echo \"BT=${RAW:-0}\""]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || !text.includes("BT=")) {
                    btPresent = false;
                    return ;
                }
                // Handle multi-line output if bluetoothctl is verbose
                let cleanText = text.trim().split('\n').pop();
                let rawVal = cleanText.split("BT=")[1];
                let val = parseInt(rawVal, 10);
                if (!isNaN(val) && val > 0) {
                    btPercent = val;
                    btPresent = true;
                } else {
                    btPresent = false;
                }
            }
        }

    }

}
