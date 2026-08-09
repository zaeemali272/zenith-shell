// bar/Right/QuickSettingsCluster.qml
import ".."
import "../.."
import "../../services"
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

    function batteryIcon(p, state, ac) {
        const isLimitActive = (state === "not charging" || state === "full" || state === "idle") && ac;
        if (isLimitActive) return "";
        if (state === "charging") return Theme.chargingIcon;
        if (p >= Theme.high) return Theme.iconHigh;
        if (p >= Theme.mid) return Theme.iconMid;
        return Theme.iconLow;
    }

    function batteryColor(p, state, ac) {
        if (ac && (state === "not charging" || state === "full")) return Theme.conserveColor;
        if (state === "charging") return Theme.chargingColor;
        if (p >= Theme.low) return Theme.midColor;
        return Theme.criticalColor;
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

            // ================= BATTERY SUB-WIDGET =================
            Item {
                id: batSubBtn
                height: Theme.scaled(28)
                implicitHeight: Theme.scaled(28)
                implicitWidth: batLayout.implicitWidth + Theme.scaled(16)
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
                visible: WidgetSettings.enableBattery && !HyprlandService.isFullscreen

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: batMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                RowLayout {
                    id: batLayout
                    anchors.centerIn: parent
                    spacing: Theme.scaled(6)

                    Text {
                        text: root.batteryIcon(BatteryService.percentage, BatteryService.status, BatteryService.acOnline)
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize
                        color: root.batteryColor(BatteryService.percentage, BatteryService.status, BatteryService.acOnline)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Battery percentage text (Hidden when fully charged or conservative mode)
                    Text {
                        visible: !BatteryService.isFullyCharged && !BatteryService.isConservative
                        text: BatteryService.percentage.toString().padStart(2, '0') + "%"
                        color: root.batteryColor(BatteryService.percentage, BatteryService.status, BatteryService.acOnline)
                        font.pixelSize: Theme.fontSize
                        font.family: "JetBrains Mono"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: batMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: (mouse) => {
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
