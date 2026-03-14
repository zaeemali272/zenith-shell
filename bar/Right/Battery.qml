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
    // Service Bindings
    readonly property int batPercent: BatteryService.percentage
    readonly property string batState: BatteryService.status
    readonly property bool acOnline: BatteryService.acOnline

    // Helper functions moved inside root
    function batteryIcon(p, state, ac) {
        const isNotCharging = state.includes("not charging") || state.includes("idle") || state.includes("unknown") || state.includes("pending");
        if (ac && isNotCharging)
            return "";

        if (state === "charging")
            return Theme.chargingIcon;

        if (p >= Theme.high)
            return Theme.iconHigh;

        if (p >= Theme.mid)
            return Theme.iconMid;

        return Theme.iconLow;
    }

    function batteryColor(p, state, ac) {
        if (ac && state !== "charging")
            return Theme.conserveColor;

        if (state === "charging")
            return Theme.chargingColor;

        if (p >= Theme.low)
            return Theme.midColor;

        return Theme.criticalColor;
    }

    // Width and Height logic to prevent zero-size hitbox
    implicitHeight: Theme.pillHeight
    implicitWidth: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding

    Pill {
        id: pill

        anchors.fill: parent
        onClicked: {
            console.log("Battery/BT Pill Clicked");
            if (menuRef) {
                // Set the anchorItem to THIS widget so the popup knows where to appear
                if (menuRef.anchorItem !== undefined)
                    menuRef.anchorItem = root;

                // Toggle Logic
                if (menuRef.active !== undefined)
                    menuRef.active = !menuRef.active;
                else
                    menuRef.visible = !menuRef.visible;
            }
        }

        RowLayout {
            id: content

            anchors.centerIn: parent
            spacing: Theme.pillGap

            // Bluetooth Section
            RowLayout {
                // Only show if the service says we are connected AND we have a valid percentage
                visible: BluetoothService.connected && BluetoothService.percentage > 0
                spacing: 4

                Text {
                    text: "󰂯"
                    font.family: Theme.iconFont
                    color: Theme.bluetoothColor
                }

                Text {
                    // Explicitly bind to the singleton property
                    text: BluetoothService.percentage + "%"
                    color: Theme.bluetoothColor
                    font.pixelSize: Theme.fontSize
                }

            }

            // Separator line
            Text {
                // Show separator only if BOTH bluetooth and laptop battery are active
                visible: (BluetoothService.connected && BluetoothService.percentage > 0) && (batPercent >= 0)
                text: "|"
                color: Theme.inactiveTextColor
            }

            // Laptop Battery Section
            RowLayout {
                visible: batPercent >= 0
                spacing: 4

                Text {
                    text: root.batteryIcon(batPercent, batState, acOnline)
                    font.family: Theme.iconFont
                    color: root.batteryColor(batPercent, batState, acOnline)
                }

                Text {
                    text: batPercent + "%"
                    color: root.batteryColor(batPercent, batState, acOnline)
                    font.pixelSize: Theme.fontSize
                }

            }

        }

    }

}
