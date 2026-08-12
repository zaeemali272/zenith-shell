import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property bool isFullyCharged: BatteryService.isFullyCharged
    readonly property bool isConservative: BatteryService.isConservative
    
    // Hide when fully charged, conservative mode is active, or in fullscreen
    visible: !isFullyCharged && !isConservative && !HyprlandService.isFullscreen
    
    // Ensure visibility is completely tied to this condition
    opacity: visible ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 400 } }

    readonly property int batPercent: Math.max(0, Math.min(100, BatteryService.percentage))
    readonly property string batState: BatteryService.status
    readonly property bool acOnline: BatteryService.acOnline
    readonly property color batFillCol: batPercent <= 15 ? "#ef4444" : Qt.rgba(1, 1, 1, 0.35)
    readonly property color batBorderCol: batPercent <= 15 ? "#ef4444" : Qt.rgba(1, 1, 1, 0.6)

    function batteryIcon(p, state, ac) {
        const isLimitActive = (state === "not charging" || state === "full" || state === "idle") && ac;
        if (isLimitActive) return "";
        if (state === "charging") return "󰂄";
        if (p >= 90) return "󰁹";
        if (p >= 75) return "󰂁";
        if (p >= 60) return "󰁿";
        if (p >= 40) return "󰁽";
        if (p >= 20) return "󰁻";
        return "󰂎";
    }

    function batteryColor(p, state, ac) {
        if (p <= 15) return "#ef4444";
        return "#ffffff";
    }

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: pill.width

    Pill {
        id: pill
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        clip: true
        border.width: 0

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                QuickSettingsService.toggle("battery");
        }
        
        Behavior on color { ColorAnimation { duration: 300 } }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 0

            // Main Battery Capsule Body
            Rectangle {
                id: batCapsule
                width: Theme.scaled(35)
                height: Theme.scaled(14)
                radius: Theme.scaled(3.5)
                color: Qt.rgba(0, 0, 0, 0.5)
                border.color: root.batBorderCol
                border.width: 1.2
                Layout.alignment: Qt.AlignVCenter
                clip: true

                // Battery Level Fill Bar (Translucent Grayish White, Red when Critical)
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 1.2
                    width: Math.max(0, (parent.width - 2.4) * (root.batPercent / 100))
                    radius: Theme.scaled(2)
                    color: root.batFillCol

                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                // Percentage & State Text Centered Directly Inside Battery Capsule Icon (Pure White Text)
                Text {
                    anchors.centerIn: parent
                    text: (root.batState === "charging" ? "⚡" : "") + (root.batPercent >= 0 ? root.batPercent : 0) + "%"
                    color: "#ffffff"
                    font.pixelSize: Theme.scaled(9.5)
                    font.weight: Font.Black
                    font.family: "JetBrains Mono"
                    style: Text.Outline
                    styleColor: "#000000"

                    SequentialAnimation on opacity {
                        running: root.batState === "charging"
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.4; duration: 600 }
                        NumberAnimation { from: 0.4; to: 1.0; duration: 600 }
                    }
                }
            }

            // Battery Terminal Nipple (Right Tip)
            Rectangle {
                width: Theme.scaled(1.8)
                height: Theme.scaled(5)
                radius: Theme.scaled(0.9)
                color: root.batBorderCol
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }
        }
    }
}