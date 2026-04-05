import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property int batPercent: BatteryService.percentage
    readonly property string batState: BatteryService.status
    readonly property bool acOnline: BatteryService.acOnline

    function batteryIcon(p, state, ac) {
        // Updated to handle 'full' and 'not charging' for Conservative Mode
        const isLimitActive = (state === "not charging" || state === "full" || state === "idle") && ac;
        
        if (isLimitActive)
            return ""; // Plug icon for Conservative Mode

        if (state === "charging")
            return Theme.chargingIcon;

        if (p >= Theme.high)
            return Theme.iconHigh;

        if (p >= Theme.mid)
            return Theme.iconMid;

        return Theme.iconLow;
    }

    function batteryColor(p, state, ac) {
        // Matches Conservative Mode logic
        if (ac && (state === "not charging" || state === "full"))
            return Theme.conserveColor;

        if (state === "charging")
            return Theme.chargingColor;

        if (p >= Theme.low)
            return Theme.midColor;

        return Theme.criticalColor;
    }

    implicitHeight: Theme.pillHeight
    implicitWidth: pill.width

    Pill {
        id: pill
        implicitHeight: Theme.pillHeight
        width: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        clip: true

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Theme.pillGap

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
                    text: batPercent.toString().padStart(2, '0') + "%"
                    color: root.batteryColor(batPercent, batState, acOnline)
                    font.pixelSize: Theme.fontSize
                    font.family: "JetBrains Mono"
                    Layout.preferredWidth: 35
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            QuickSettingsService.open("battery", root.mapToItem(null, 0, 0, root.width, root.height), false);
        }
        onExited: QuickSettingsService.startHideTimer();
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                QuickSettingsService.toggle("battery", root.mapToItem(null, 0, 0, root.width, root.height));
        }
    }
}