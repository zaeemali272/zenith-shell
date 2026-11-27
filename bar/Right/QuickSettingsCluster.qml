// bar/Right/QuickSettingsCluster.qml
import ".."
import "../.."
import "../../services"
import "../../Settings"
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: outerContainer.implicitWidth

    readonly property int batPercent: Math.max(0, Math.min(100, BatteryService.percentage))
    readonly property string batState: BatteryService.status
    readonly property bool acOnline: BatteryService.acOnline
    readonly property color batFillCol: batPercent <= 15 ? "#ef4444" : Qt.rgba(1, 1, 1, 0.22)
    readonly property color batBorderCol: batPercent <= 15 ? "#ef4444" : "#ffffff"

    function batteryIcon(p, state, ac) {
        if (state === "charging" || ac) return "󰚥";
        if (p >= 90) return "";
        if (p >= 65) return "";
        if (p >= 40) return "";
        if (p >= 15) return "";
        return "";
    }

    function batteryColor(p, state, ac) {
        if (state === "charging") return Theme.barIconColor;
        if (p <= 15) return Theme.red;
        return Theme.barIconColor;
    }

    // Outer Glass Container (No line spacers, clean rounded pills layout)
    Rectangle {
        id: outerContainer
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: clusterRow.implicitWidth + Theme.scaled(18)
        implicitWidth: width
        radius: height / 2
        color: Theme.pillColor
        border.color: Theme.glassBorder
        border.width: 1
        antialiasing: true

        Behavior on width {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: QuickSettingsService.toggle("main")
        }

        RowLayout {
            id: clusterRow
            anchors.centerIn: parent
            spacing: Theme.scaled(4)

            // ================= MICROPHONE SUB-WIDGET =================
            Item {
                id: micSubBtn
                height: Theme.scaled(28)
                implicitHeight: Theme.scaled(28)
                implicitWidth: micIcon.implicitWidth + Theme.scaled(4)
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
                visible: VolumeService.micActive

                scale: micMouse.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

                Text {
                    id: micIcon
                    anchors.centerIn: parent
                    text: VolumeService.micMuted ? "󰍭" : "󰍬"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.iconSize
                    color: micMouse.containsMouse
                        ? (VolumeService.micMuted ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.65) : Qt.rgba(Theme.barIconColor.r, Theme.barIconColor.g, Theme.barIconColor.b, 0.65))
                        : (VolumeService.micMuted ? Theme.red : (VolumeService.micActive ? "#ff9e3b" : Theme.barIconColor))
                    Layout.alignment: Qt.AlignVCenter
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    SequentialAnimation on opacity {
                        running: VolumeService.micActive && !VolumeService.micMuted
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.35; duration: 600; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.35; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                    }
                }

                MouseArea {
                    id: micMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: (mouse) => {
                        micMuteExec.running = false;
                        micMuteExec.running = true;
                        VolumeService.update();
                    }
                }
            }


            // ================= CAT WIDGET =================
            Item {
                id: catSubBtn
                height: Theme.scaled(28)
                implicitHeight: Theme.scaled(28)
                implicitWidth: Theme.scaled(35)
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter

                scale: catMouse.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

                Image {
                    id: catSprite
                    anchors.centerIn: parent
                    source: "../../assets/cat_f" + Math.floor(frameTimer.frameCount % 4) + ".png"
                    width: Theme.scaled(35)
                    height: Theme.scaled(26)
                    fillMode: Image.PreserveAspectFit
                    opacity: catMouse.containsMouse ? 0.75 : 1.0
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: Theme.catColor
                    }
                }

                Timer {
                    id: frameTimer
                    property int frameCount: 0
                    interval: {
                        switch (PowerProfileService.currentProfile) {
                            case "performance": return 80;
                            case "turbo": return 50;
                            case "powersave": return 220;
                            case "balanced": return 150;
                            default: return 200;
                        }
                    }
                    running: !HyprlandService.isFullscreen
                    repeat: true
                    onTriggered: frameCount++
                }

                MouseArea {
                    id: catMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            QuickSettingsService.toggle("main");
                        } else if (mouse.button === Qt.RightButton) {
                            QuickSettingsService.toggle("powerprofile");
                        }
                    }
                }
            }

            // ================= BATTERY SUB-WIDGET =================
            Item {
                id: batSubBtn
                height: Theme.scaled(28)
                implicitHeight: Theme.scaled(28)
                implicitWidth: batLayout.implicitWidth + Theme.scaled(8)
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
                visible: HardwareService.hasBattery && WidgetSettings.enableBattery
                         && !HyprlandService.isFullscreen

                scale: batMouse.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

                RowLayout {
                    id: batLayout
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)
                    opacity: batMouse.containsMouse ? 0.70 : 1.0
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                    // Horizontal Battery Icon
                    Text {
                        text: root.batteryIcon(root.batPercent, root.batState, root.acOnline)
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(18)
                        color: root.batteryColor(root.batPercent, root.batState, root.acOnline)
                        Layout.alignment: Qt.AlignVCenter

                        SequentialAnimation on opacity {
                            running: root.batState === "charging"
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.4; duration: 500; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.4; to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                        }
                    }

                    // Percentage Text (Shown when battery <= 20%, on mouse hover, or while charging)
                    Text {
                        visible: root.batPercent <= 20 || batMouse.containsMouse || root.batState === "charging"
                        text: (root.batPercent >= 0 ? root.batPercent : 0) + "%"
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.weight: Font.Bold
                        color: root.batteryColor(root.batPercent, root.batState, root.acOnline)
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: batMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) {
                            QuickSettingsService.toggle("main");
                        } else {
                            QuickSettingsService.toggle("battery");
                        }
                    }
                }
            }
        }
    }

    // Audio Process
    Process {
        id: micMuteExec
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }
}
