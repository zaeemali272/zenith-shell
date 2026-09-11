// The inside of the lock card: weather + media on the left, the clock /
// profile / password column in the middle, system resources on the right.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../.."
import "../../services"
import "../../Settings"

RowLayout {
    id: root

    required property var surface
    readonly property var player: MediaPlayerService.trackedPlayer
    readonly property real centerScale: surface.centerScale
    readonly property int centerWidth: surface.centerWidth
    readonly property int panelRadius: Theme.scaled(20)
    readonly property color panelColor: Qt.alpha(Colors.surface_container, 0.9)

    spacing: Theme.scaled(28)

    // ---- Left: weather, media ------------------------------------------
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.scaled(12)

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: weatherRow.implicitHeight + Theme.scaled(28)
            radius: root.panelRadius
            color: root.panelColor
            visible: WidgetSettings.enableWeather

            RowLayout {
                id: weatherRow
                anchors.fill: parent
                anchors.margins: Theme.scaled(14)
                spacing: Theme.scaled(14)

                Text {
                    text: WeatherService.getIcon(WeatherService.weatherCode)
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(38)
                    color: Colors.primary
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Text { text: WeatherService.tempC + "°C"; color: Theme.text; font.pixelSize: Theme.scaled(24); font.weight: Font.Bold }
                    Text { text: WeatherService.weatherDesc + " · " + WeatherService.areaName; color: Theme.subtext0; font.pixelSize: Theme.scaled(12); elide: Text.ElideRight; Layout.fillWidth: true }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: root.panelRadius
            color: root.panelColor
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(16)
                spacing: Theme.scaled(12)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.scaled(16)
                    color: Qt.alpha(Colors.surface_container_high, 0.8)
                    clip: true

                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.player ? String(root.player.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !art.visible
                        text: "󰎆"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(64)
                        color: Colors.on_surface_variant
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.player ? MediaPlayerService.formatMediaTitle(String(root.player.trackTitle || "Media"), root.player.identity) : "Nothing playing"
                    color: Theme.text
                    font.pixelSize: Theme.scaled(14)
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.player ? String(root.player.trackArtist || "") : ""
                    visible: text !== ""
                    color: Theme.subtext0
                    font.pixelSize: Theme.scaled(12)
                    elide: Text.ElideRight
                }
            }
        }
    }

    // ---- Center ----------------------------------------------------------
    ColumnLayout {
        Layout.preferredWidth: root.centerWidth
        Layout.fillWidth: false
        Layout.fillHeight: true
        spacing: Theme.scaled(16)

        // Big two-tone clock: hours in primary, minutes in secondary, the
        // AM/PM chip tucked under the minutes.
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.scaled(12)
            spacing: Theme.scaled(6)

            readonly property int digitSize: Math.round((ClockSettings.use24Hour ? 148 : 132) * root.centerScale)

            Text {
                Layout.alignment: Qt.AlignTop
                text: Qt.formatDateTime(clock.date, ClockSettings.use24Hour ? "HH" : "hh")
                color: Colors.primary
                font.pixelSize: parent.digitSize
                font.weight: Font.Black
                font.letterSpacing: -4
            }
            ColumnLayout {
                spacing: 0
                Text {
                    id: minutesText
                    text: Qt.formatDateTime(clock.date, "mm")
                    color: Colors.secondary
                    font.pixelSize: parent.parent.digitSize
                    font.weight: Font.Black
                    font.letterSpacing: -4
                }
                Rectangle {
                    visible: !ClockSettings.use24Hour
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: -Theme.scaled(14)
                    implicitWidth: minutesText.implicitWidth - Theme.scaled(8)
                    implicitHeight: ampm.implicitHeight + Theme.scaled(10)
                    radius: Theme.scaled(12)
                    color: Qt.alpha(Colors.surface_container_high, 0.9)
                    Text { id: ampm; anchors.centerIn: parent; text: Qt.formatDateTime(clock.date, "AP"); color: Theme.text; font.pixelSize: Theme.scaled(18); font.weight: Font.Bold; font.letterSpacing: 2 }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "dddd • d MMM").toUpperCase()
            color: Theme.text
            font.pixelSize: Theme.scaled(15)
            font.weight: Font.DemiBold
            font.letterSpacing: 2
        }

        // Profile picture
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.scaled(28) * root.centerScale
            Layout.bottomMargin: Theme.scaled(16) * root.centerScale
            readonly property int size: Math.round(root.centerWidth * 0.55)
            implicitWidth: size
            implicitHeight: size

            Rectangle {
                id: pfpMask
                anchors.fill: parent
                radius: width / 2
                color: Qt.alpha(Colors.surface_container_highest, 0.9)
                layer.enabled: true
                visible: false
            }
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Qt.alpha(Colors.surface_container_highest, 0.9)
                border.color: Qt.alpha(Colors.primary, 0.5)
                border.width: 2
            }
            Text {
                anchors.centerIn: parent
                visible: pfp.status !== Image.Ready
                text: "󰀄"
                font.family: Theme.iconFont
                font.pixelSize: parent.size / 2
                color: Colors.on_surface_variant
            }
            // ~/.face when present, else the picture shipped in the repo.
            // Checked once rather than letting Image fail over, so a missing
            // ~/.face is not a logged error on every lock.
            id: pfpBox
            property bool hasFace: false
            Process {
                running: true
                command: ["test", "-f", PathSettings.home + "/.face"]
                onExited: (code) => pfpBox.hasFace = (code === 0)
            }

            Image {
                id: pfp
                anchors.fill: parent
                anchors.margins: 3
                source: {
                    const custom = IdleSettings.profilePicture;
                    if (custom !== "") return custom.startsWith("file://") ? custom : "file://" + custom;
                    if (pfpBox.hasFace) return "file://" + PathSettings.home + "/.face";
                    return "file://" + PathSettings.shellDir + "/profilePicture";
                }
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: pfpMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
            }
        }

        // Password pill
        Rectangle {
            id: field
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.round(root.centerWidth * 0.85)
            implicitHeight: Theme.scaled(48)
            radius: height / 2
            color: Qt.alpha(Colors.surface_container_high, 0.95)
            border.width: 2
            border.color: {
                if (LockService.state === LockService.State.Failed || LockService.state === LockService.State.MaxTries) return Colors.error;
                if (LockService.authenticating) return Colors.primary;
                return "transparent";
            }
            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            // A failed attempt shakes the field.
            transform: Translate { id: shake }
            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 10; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: -6; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 6; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
            }
            Connections { target: LockService; function onFlash() { shakeAnim.restart(); } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(16)
                anchors.rightMargin: Theme.scaled(8)
                spacing: Theme.scaled(10)

                Text {
                    text: LockService.authenticating ? "󰔟" : "󰌾"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(18)
                    color: Colors.on_surface_variant
                    RotationAnimation on rotation { running: LockService.authenticating; from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
                }

                // Dots, one per typed character
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: LockService.buffer.length === 0
                        text: "Enter password"
                        color: Colors.on_surface_variant
                        font.pixelSize: Theme.scaled(14)
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.scaled(5)
                        Repeater {
                            model: Math.min(LockService.buffer.length, 32)
                            Rectangle {
                                width: Theme.scaled(9); height: width; radius: width / 2
                                color: Theme.text
                                scale: 0
                                Component.onCompleted: scale = 1
                                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }
                            }
                        }
                    }
                }

                Rectangle {
                    implicitWidth: Theme.scaled(34); implicitHeight: Theme.scaled(34)
                    radius: width / 2
                    color: LockService.buffer.length > 0 ? Colors.primary : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰌑"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(16)
                        color: LockService.buffer.length > 0 ? Colors.on_primary : Colors.on_surface_variant
                    }
                    MouseArea { anchors.fill: parent; onClicked: LockService.submit() }
                }
            }
        }

        // State message
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: {
                if (LockService.message !== "") return LockService.message;
                switch (LockService.state) {
                case LockService.State.Failed: return "Incorrect password";
                case LockService.State.Error: return "Authentication error";
                case LockService.State.MaxTries: return "Too many attempts";
                }
                return LockService.authenticating ? "Checking…" : (CaffeineService.active ? "Caffeine is on" : "");
            }
            color: (LockService.state === LockService.State.None) ? Colors.on_surface_variant : Colors.error
            font.pixelSize: Theme.scaled(12)
            opacity: text === "" ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }

        Item { Layout.fillHeight: true }

        SystemClock { id: clock; precision: SystemClock.Minutes }
    }

    // ---- Right: resources, battery ---------------------------------------
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.scaled(12)

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: resCol.implicitHeight + Theme.scaled(32)
            radius: root.panelRadius
            color: root.panelColor

            ColumnLayout {
                id: resCol
                anchors.fill: parent
                anchors.margins: Theme.scaled(16)
                spacing: Theme.scaled(12)

                Repeater {
                    model: [
                        { icon: "", label: "CPU", value: ResourceService.cpu, unit: "%", col: Theme.cpuColor },
                        { icon: "", label: "Memory", value: ResourceService.mem, unit: "%", col: Theme.memColor },
                        { icon: "", label: "Temp", value: ResourceService.temp, unit: "°C", col: Theme.tempColor },
                        { icon: "󰋊", label: "Disk", value: ResourceService.fs, unit: "%", col: Colors.secondary }
                    ]
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Theme.scaled(4)
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: modelData.icon; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: modelData.col }
                            Text { text: modelData.label; color: Theme.subtext0; font.pixelSize: Theme.scaled(12); Layout.fillWidth: true }
                            Text { text: modelData.value + modelData.unit; color: Theme.text; font.pixelSize: Theme.scaled(12); font.weight: Font.Bold }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Theme.scaled(6)
                            radius: height / 2
                            color: Qt.alpha(Colors.surface_container_highest, 0.9)
                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, modelData.value / 100))
                                height: parent.height
                                radius: height / 2
                                color: modelData.col
                                Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: batRow.implicitHeight + Theme.scaled(28)
            radius: root.panelRadius
            color: root.panelColor
            visible: HardwareService.hasBattery

            RowLayout {
                id: batRow
                anchors.fill: parent
                anchors.margins: Theme.scaled(14)
                spacing: Theme.scaled(14)
                Text {
                    text: Theme.batteryIcon(BatteryService.percentage, BatteryService.status === "charging")
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(30)
                    color: Theme.batteryColorFor(BatteryService.percentage, BatteryService.status === "charging")
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Text { text: Math.max(0, BatteryService.percentage) + "%"; color: Theme.text; font.pixelSize: Theme.scaled(22); font.weight: Font.Bold }
                    Text { text: BatteryService.acOnline ? "Plugged in" : BatteryService.timeRemaining; color: Theme.subtext0; font.pixelSize: Theme.scaled(12) }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: root.panelRadius
            color: root.panelColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(16)
                spacing: Theme.scaled(6)
                RowLayout {
                    spacing: Theme.scaled(8)
                    Text { text: "󰂚"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(16); color: Colors.primary }
                    Text { text: "NOTIFICATIONS"; color: Theme.subtext0; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; font.letterSpacing: 1 }
                    Item { Layout.fillWidth: true }
                    Text { text: NotificationService.notifications.count; color: Colors.primary; font.pixelSize: Theme.scaled(12); font.weight: Font.Bold }
                }
                Repeater {
                    model: Math.min(NotificationService.notifications.count, 4)
                    RowLayout {
                        required property int index
                        readonly property var n: NotificationService.notifications.get(index)
                        Layout.fillWidth: true
                        spacing: Theme.scaled(8)
                        Text { text: n.appName; color: Colors.primary; font.pixelSize: Theme.scaled(11); font.weight: Font.Bold }
                        Text { text: n.summary; color: Theme.text; font.pixelSize: Theme.scaled(11); elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
                Text {
                    visible: NotificationService.notifications.count === 0
                    text: "All caught up"
                    color: Colors.on_surface_variant
                    font.pixelSize: Theme.scaled(12)
                }
                Item { Layout.fillHeight: true }
            }
        }
    }
}
