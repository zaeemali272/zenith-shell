// bar/Right/Battery.qml
import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

MouseArea {
    id: root

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

    implicitHeight: Theme.pillHeight
    implicitWidth: pill.implicitWidth
    Component.onCompleted: btExec.running = true

    Pill {
        id: pill

        anchors.fill: parent
        implicitWidth: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding

        RowLayout {
            id: content

            anchors.centerIn: parent
            spacing: Theme.pillGap

            // Bluetooth Logic
            RowLayout {
                visible: btPresent
                spacing: 4

                Text {
                    text: Theme.iconMid
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
                visible: btPresent && batPercent >= 0
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

    // Keep your Bluetooth process here as it was
    Process {
        id: btExec

        command: ["sh", "-c", "MAC=$(bluetoothctl devices Connected | awk '{print $2}' | head -n1); [ -n \"$MAC\" ] || exit 0; RAW=$(bluetoothctl info \"$MAC\" | grep 'Battery Percentage' | awk -F '[()]' '{print $2}' | tr -d '[:space:]%'); [ -z \"$RAW\" ] && RAW=$(bluetoothctl info \"$MAC\" | grep 'Battery Percentage' | awk '{print $3}' | tr -d '[:space:]%'); echo \"BT=$RAW\""]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || !text.includes("BT=")) {
                    btPresent = false;
                    return ;
                }
                let rawVal = text.split("BT=")[1].trim();
                let val = rawVal.startsWith("0x") ? parseInt(rawVal, 16) : parseInt(rawVal, 10);
                if (!isNaN(val) && val >= 0) {
                    btPercent = val;
                    btPresent = true;
                } else {
                    btPresent = false;
                }
            }
        }

    }

}
