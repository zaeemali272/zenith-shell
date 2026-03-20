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
    readonly property int batPercent: BatteryService.percentage
    readonly property string batState: BatteryService.status
    readonly property bool acOnline: BatteryService.acOnline

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

    implicitHeight: Theme.pillHeight
    // Track the animated width
    implicitWidth: pill.width

    Pill {
        id: pill

        implicitHeight: Theme.pillHeight
        // Calculate target width dynamically
        width: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        clip: true
        onClicked: {
            if (menuRef) {
                if (menuRef.anchorItem !== undefined)
                    menuRef.anchorItem = root;

                menuRef.active = !menuRef.active;
            }
        }

        RowLayout {
            id: content

            anchors.centerIn: parent
            spacing: Theme.pillGap

            // Bluetooth Section
            RowLayout {
                visible: BluetoothService.connected && BluetoothService.percentage > 0
                spacing: 4

                Text {
                    text: "󰂯"
                    font.family: Theme.iconFont
                    color: Theme.bluetoothColor
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: BluetoothService.percentage.toString().padStart(2, '0') + "%"
                    color: Theme.bluetoothColor
                    font.pixelSize: Theme.fontSize
                    // --- STABILITY FIX ---
                    font.family: "JetBrains Mono"
                    Layout.preferredWidth: 35
                    horizontalAlignment: Text.AlignHCenter
                }

            }

            // Separator
            Text {
                visible: (BluetoothService.connected && BluetoothService.percentage > 0) && (batPercent >= 0)
                text: "|"
                color: Theme.inactiveTextColor
                opacity: parent.visible ? 1 : 0
            }

            // Laptop Battery Section
            RowLayout {
                visible: batPercent >= 0
                spacing: 4

                Text {
                    text: root.batteryIcon(batPercent, batState, acOnline)
                    font.family: Theme.iconFont
                    color: root.batteryColor(batPercent, batState, acOnline)
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    // Padding to 2 digits (e.g., 05%)
                    text: batPercent.toString().padStart(2, '0') + "%"
                    color: root.batteryColor(batPercent, batState, acOnline)
                    font.pixelSize: Theme.fontSize
                    // --- STABILITY FIX ---
                    font.family: "JetBrains Mono"
                    Layout.preferredWidth: 35
                    horizontalAlignment: Text.AlignHCenter
                }

            }

        }

        // --- SMOOTH EXPANSION ---
        Behavior on width {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }

        }

    }

}
