// bar/Right/QuickSettingsCluster.qml
import ".."
import "../.."
import "../../services"
import "../../Settings"
import QtQuick
import QtQuick.Layouts
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

    // Helper functions matching original widgets
    function volumeIcon(v, m) {
        if (m) return Theme.volMute;
        if (v >= 70) return Theme.volHigh;
        if (v >= 30) return Theme.volMid;
        return Theme.volLow;
    }

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

    // Outer Glass Container (No line spacers, clean rounded pills layout)
    Rectangle {
        id: outerContainer
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: clusterRow.implicitWidth + Theme.scaled(12)
        implicitWidth: width
        radius: height / 2
        color: Theme.pillColor
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
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
                implicitWidth: micLayout.implicitWidth + Theme.scaled(12)
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
                visible: VolumeService.micActive

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: micMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                RowLayout {
                    id: micLayout
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)

                    Text {
                        text: VolumeService.micMuted ? "\uf131" : "\uf130"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize
                        color: VolumeService.micMuted ? Theme.red : Theme.accentColor
                        Layout.alignment: Qt.AlignVCenter
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

            // ================= VOLUME SUB-WIDGET =================
            Item {
                id: volSubBtn
                height: Theme.scaled(28)
                implicitHeight: Theme.scaled(28)
                implicitWidth: volLayout.implicitWidth + Theme.scaled(14)
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter

                property bool showVolText: false

                Timer {
                    id: volTextTimer
                    interval: 3000
                    onTriggered: volSubBtn.showVolText = false
                }

                Connections {
                    target: VolumeService
                    function onOutputVolumeChanged() {
                        volSubBtn.showVolText = true;
                        volTextTimer.restart();
                    }
                    function onMutedChanged() {
                        volSubBtn.showVolText = true;
                        volTextTimer.restart();
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: volMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                RowLayout {
                    id: volLayout
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)

                    // Speaker Icon
                    Text {
                        text: root.volumeIcon(VolumeService.outputVolume, VolumeService.muted)
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize
                        color: VolumeService.btActive ? Theme.bluetoothColor : Theme.fontColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Percentage Text (Visible ONLY when volume changes or mouse hovers, hides after 3s)
                    Text {
                        visible: volSubBtn.showVolText || volMouse.containsMouse
                        text: VolumeService.muted ? "Muted" : VolumeService.outputVolume + "%"
                        font.pixelSize: Theme.fontSize
                        font.family: "JetBrains Mono"
                        color: VolumeService.btActive ? Theme.bluetoothColor : Theme.fontColor
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: volMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            muteExec.running = false;
                            muteExec.running = true;
                        } else if (mouse.button === Qt.LeftButton) {
                            QuickSettingsService.toggle("volume");
                        }
                    }

                    onWheel: (wheel) => {
                        if (wheel.angleDelta.y > 0) {
                            volUp.running = false;
                            volUp.running = true;
                        } else {
                            volDown.running = false;
                            volDown.running = true;
                        }
                        VolumeService.update();
                        volSubBtn.showVolText = true;
                        volTextTimer.restart();
                    }
                }
            }

            // ================= BLUETOOTH SUB-WIDGET =================
            Item {
                id: btSubBtn
                height: Theme.scaled(28)
                implicitHeight: Theme.scaled(28)
                implicitWidth: btLayout.implicitWidth + Theme.scaled(14)
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
                visible: BluetoothService.powered

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: btMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                RowLayout {
                    id: btLayout
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)

                    Text {
                        text: BluetoothService.powered ? Theme.btIcon : "󰂲"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize
                        color: BluetoothService.connected ? Theme.bluetoothColor : (BluetoothService.powered ? Theme.fontColor : Theme.inactiveTextColor)
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: btMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: (mouse) => {
                        BluetoothService.refresh();
                        QuickSettingsService.toggle("bluetooth");
                    }
                }
            }

            // ================= REDESIGNED VIBRANT BATTERY SUB-WIDGET =================
            Item {
                id: batSubBtn
                height: Theme.scaled(28)
                implicitHeight: Theme.scaled(28)
                implicitWidth: batLayout.implicitWidth + Theme.scaled(18)
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
                visible: WidgetSettings.enableBattery && !HyprlandService.isFullscreen

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: batMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                    border.width: 0

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                RowLayout {
                    id: batLayout
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

                MouseArea {
                    id: batMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        QuickSettingsService.toggle("battery");
                    }
                }
            }

            // ================= POWER SUB-WIDGET =================
            Item {
                id: pwrSubBtn
                height: Theme.scaled(28)
                implicitHeight: Theme.scaled(28)
                implicitWidth: Theme.scaled(28)
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: pwrMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: pwrMouse.containsMouse ? Theme.powerRed : Theme.fontColor
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.iconSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: pwrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            QuickSettingsService.toggle("power");
                        } else if (mouse.button === Qt.RightButton) {
                            powerExec.running = false;
                            powerExec.running = true;
                        }
                    }
                }
            }
        }
    }

    // Audio & Power Processes
    Process {
        id: micMuteExec
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }

    Process {
        id: muteExec
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }

    Process {
        id: volUp
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]
    }

    Process {
        id: volDown
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
    }

    Process {
        id: powerExec
        command: ["wlogout"]
    }
}
