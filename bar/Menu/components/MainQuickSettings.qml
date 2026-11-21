import "../.."
import "../../../"
import "../../../services"
import "../../../Settings"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: Theme.scaled(14)
    Layout.fillWidth: true

    opacity: 0
    scale: 0.98
    Component.onCompleted: {
        entryAnim.start();
        if (HardwareService.hasBattery) BatteryService.update();
        if (HardwareService.hasBacklight) BrightnessService.update();
    }

    ParallelAnimation {
        id: entryAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; to: 1; duration: 400; easing.type: Theme.elasticEasing }
    }

    // ==========================================
    // 1. TOP HEADER ROW
    // ==========================================
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.scaled(10)

        // Accent bar indicator
        Rectangle {
            width: Theme.scaled(4)
            height: Theme.scaled(20)
            color: Theme.accentColor
            radius: 999
        }

        Text {
            text: "QUICK SETTINGS"
            color: Theme.text
            font.pixelSize: Theme.scaled(12)
            font.weight: Font.Black
            font.letterSpacing: 2
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        // Battery Badge (Clickable -> Battery Submenu)
        Rectangle {
            visible: HardwareService.hasBattery
            height: Theme.scaled(28)
            implicitHeight: Theme.scaled(28)
            implicitWidth: battLayout.implicitWidth + Theme.scaled(24)
            Layout.preferredHeight: Theme.scaled(28)
            Layout.preferredWidth: implicitWidth
            Layout.alignment: Qt.AlignVCenter
            radius: Theme.scaled(14)
            color: battMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
            border.color: (BatteryService.acOnline || battMouse.containsMouse) ? Theme.accentColor : Theme.glassBorder
            border.width: 1
            antialiasing: true
            scale: battMouse.pressed ? 0.95 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: Theme.animInstant } }
            Behavior on color { ColorAnimation { duration: Theme.animInstant } }

            RowLayout {
                id: battLayout
                anchors.centerIn: parent
                spacing: Theme.scaled(5)

                // 1. Plugged-in icon (shown whenever connected to AC power)
                Text {
                    visible: BatteryService.acOnline
                    text: "󰚥"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(13)
                    color: "#ffffff"
                    Layout.alignment: Qt.AlignVCenter
                }

                // 2. Rounded bolt icon (when charging) or battery level icon (when discharging)
                Text {
                    text: BatteryService.acOnline ? (BatteryService.status === "charging" ? "" : "") : (BatteryService.percentage >= 90 ? "󰁹" : (BatteryService.percentage >= 50 ? "󰁿" : (BatteryService.percentage >= 20 ? "󰁻" : "󰂎")))
                    visible: text !== ""
                    font.family: Theme.iconFont
                    font.pixelSize: BatteryService.acOnline ? Theme.scaled(13) : Theme.scaled(14)
                    color: BatteryService.acOnline ? Theme.accentColor : (BatteryService.percentage <= 20 ? Theme.red : Theme.accentColor)
                    Layout.alignment: Qt.AlignVCenter

                    SequentialAnimation on opacity {
                        running: BatteryService.acOnline && BatteryService.status === "charging"
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.45; duration: 750; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.45; to: 1.0; duration: 750; easing.type: Easing.InOutQuad }
                    }
                }

                // 3. Percentage and wattage
                Text {
                    text: {
                        let pct = (BatteryService.percentage >= 0 ? BatteryService.percentage : 0) + "%";
                        if (BatteryService.acOnline && BatteryService.wattage > 0.5 && !BatteryService.isFullyCharged) {
                            return pct + " (" + BatteryService.wattage.toFixed(0) + "W)";
                        }
                        return pct;
                    }
                    font.pixelSize: Theme.scaled(11)
                    font.weight: Font.Bold
                    color: Theme.text
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                id: battMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: QuickSettingsService.open("battery")
            }
        }

        // Settings Button
        Rectangle {
            width: Theme.scaled(28)
            height: Theme.scaled(28)
            radius: Theme.scaled(14)
            color: setMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
            border.color: Theme.glassBorder
            border.width: 1
            antialiasing: true
            scale: setMouse.pressed ? 0.95 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                text: "󰒓"
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(14)
                color: setMouse.containsMouse ? Theme.accentColor : Theme.subtext0
            }

            MouseArea {
                id: setMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    QuickSettingsService.close();
                    CenterState.open("Settings");
                }
            }
        }

        // Power Button
        Rectangle {
            width: Theme.scaled(28)
            height: Theme.scaled(28)
            radius: Theme.scaled(14)
            color: pwrMouse.containsMouse ? Qt.rgba(239/255, 68/255, 68/255, 0.2) : Theme.cardBackground
            border.color: pwrMouse.containsMouse ? Theme.powerRed : Theme.glassBorder
            border.width: 1
            antialiasing: true
            scale: pwrMouse.pressed ? 0.95 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                text: "󰐥"
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(14)
                color: pwrMouse.containsMouse ? Theme.powerRed : Theme.subtext0
            }

            MouseArea {
                id: pwrMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    QuickSettingsService.open("power");
                }
            }
        }
    }

    // ==========================================
    // 2. QUICK TILES GRID (Windows / Android Style)
    // ==========================================
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Theme.scaled(8)
        columnSpacing: Theme.scaled(8)

        // --- TILE 1: WI-FI / NETWORK ---
        Rectangle {
            visible: HardwareService.hasNetworking
            Layout.fillWidth: true
            height: Theme.scaled(58)
            implicitHeight: Theme.scaled(58)
            Layout.preferredHeight: Theme.scaled(58)
            radius: Theme.bubbleRadiusMedium
            color: (!WifiService.isAirplane && WifiService.currentState === "connected")
                   ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.20)
                   : (wifiTileMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
            border.color: (!WifiService.isAirplane && WifiService.currentState === "connected")
                          ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.5)
                          : Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(8)
                spacing: Theme.scaled(8)

                // Left Clickable Toggle Zone
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: Theme.scaled(8)

                        Rectangle {
                            width: Theme.scaled(36)
                            height: Theme.scaled(36)
                            radius: Theme.scaled(10)
                            color: (!WifiService.isAirplane && WifiService.currentState === "connected") ? Theme.accentColor : Qt.rgba(1, 1, 1, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: WifiService.isAirplane ? "󰀞" : (WifiService.currentState === "connected" ? "󰤨" : "󰤮")
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(18)
                                color: (!WifiService.isAirplane && WifiService.currentState === "connected") ? Colors.on_primary : Theme.subtext0
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "Network"
                                font.pixelSize: Theme.scaled(12)
                                font.weight: Font.Bold
                                color: Theme.text
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: WifiService.isAirplane ? "Airplane Mode" : (WifiService.currentSsid ? WifiService.currentSsid : (WifiService.currentState === "connected" ? "Connected" : "Disconnected"))
                                font.pixelSize: Theme.scaled(10)
                                color: Theme.subtext0
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        id: wifiTileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WifiService.toggleAirplane(!WifiService.isAirplane)
                    }
                }

                // Right Chevron -> Open Submenu
                Rectangle {
                    width: Theme.scaled(28)
                    height: Theme.scaled(36)
                    radius: Theme.scaled(8)
                    color: wifiChevronMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(16)
                        color: wifiChevronMouse.containsMouse ? Theme.text : Theme.subtext0
                    }

                    MouseArea {
                        id: wifiChevronMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: QuickSettingsService.open("network")
                    }
                }
            }
        }

        // --- TILE 2: BLUETOOTH ---
        Rectangle {
            visible: HardwareService.hasBluetooth
            Layout.fillWidth: true
            height: Theme.scaled(58)
            implicitHeight: Theme.scaled(58)
            Layout.preferredHeight: Theme.scaled(58)
            radius: Theme.bubbleRadiusMedium
            color: BluetoothService.powered
                   ? Qt.rgba(Theme.bluetoothColor.r, Theme.bluetoothColor.g, Theme.bluetoothColor.b, 0.20)
                   : (btTileMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
            border.color: BluetoothService.powered
                          ? Qt.rgba(Theme.bluetoothColor.r, Theme.bluetoothColor.g, Theme.bluetoothColor.b, 0.5)
                          : Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(8)
                spacing: Theme.scaled(8)

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: Theme.scaled(8)

                        Rectangle {
                            width: Theme.scaled(36)
                            height: Theme.scaled(36)
                            radius: Theme.scaled(10)
                            color: BluetoothService.powered ? Theme.bluetoothColor : Qt.rgba(1, 1, 1, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: BluetoothService.powered ? (BluetoothService.connected ? "󰂱" : "󰂯") : "󰂲"
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(18)
                                color: BluetoothService.powered ? Colors.on_primary : Theme.subtext0
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "Bluetooth"
                                font.pixelSize: Theme.scaled(12)
                                font.weight: Font.Bold
                                color: Theme.text
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: BluetoothService.connected ? (BluetoothService.connectedName || "Connected") : (BluetoothService.powered ? "On" : "Off")
                                font.pixelSize: Theme.scaled(10)
                                color: Theme.subtext0
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        id: btTileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.togglePower()
                    }
                }

                // Right Chevron -> Open Submenu
                Rectangle {
                    width: Theme.scaled(28)
                    height: Theme.scaled(36)
                    radius: Theme.scaled(8)
                    color: btChevronMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(16)
                        color: btChevronMouse.containsMouse ? Theme.text : Theme.subtext0
                    }

                    MouseArea {
                        id: btChevronMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            BluetoothService.refresh();
                            QuickSettingsService.open("bluetooth");
                        }
                    }
                }
            }
        }

        // --- TILE 3: POWER MODE ---
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(58)
            implicitHeight: Theme.scaled(58)
            Layout.preferredHeight: Theme.scaled(58)
            radius: Theme.bubbleRadiusMedium
            color: pwrModeMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
            border.color: Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(8)
                spacing: Theme.scaled(8)

                Rectangle {
                    width: Theme.scaled(36)
                    height: Theme.scaled(36)
                    radius: Theme.scaled(10)
                    color: Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.25)

                    Text {
                        anchors.centerIn: parent
                        text: "󰓅"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(18)
                        color: Theme.mauve
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Power Mode"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Bold
                        color: Theme.text
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: PowerProfileService.currentProfile.toUpperCase()
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.scaled(11)
                        color: Theme.subtext0
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: "󰅂"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(16)
                    color: pwrModeMouse.containsMouse ? Theme.text : Theme.subtext0
                }
            }

            MouseArea {
                id: pwrModeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: QuickSettingsService.open("powerprofile")
            }
        }

        // --- TILE 4: NIGHT LIGHT ---
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(58)
            implicitHeight: Theme.scaled(58)
            Layout.preferredHeight: Theme.scaled(58)
            radius: Theme.bubbleRadiusMedium
            color: PowerToolsService.nightLight
                   ? Qt.rgba(Theme.powerYellow.r, Theme.powerYellow.g, Theme.powerYellow.b, 0.20)
                   : (nlMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
            border.color: PowerToolsService.nightLight
                          ? Qt.rgba(Theme.powerYellow.r, Theme.powerYellow.g, Theme.powerYellow.b, 0.5)
                          : Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(8)
                spacing: Theme.scaled(8)

                Rectangle {
                    width: Theme.scaled(36)
                    height: Theme.scaled(36)
                    radius: Theme.scaled(10)
                    color: PowerToolsService.nightLight ? Theme.powerYellow : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: PowerToolsService.nightLight ? "󰖔" : "󰖙"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(18)
                        color: PowerToolsService.nightLight ? Colors.background : Theme.subtext0
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Night Light"
                        font.pixelSize: Theme.scaled(12)
                        font.weight: Font.Bold
                        color: Theme.text
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: PowerToolsService.nightLight ? "Active (Warm)" : "Off"
                        font.pixelSize: Theme.scaled(10)
                        color: Theme.subtext0
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                id: nlMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: PowerToolsService.toggleNightLight()
            }
        }

        // --- TILE 5: CAFFEINE (KEEP AWAKE) ---
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(58)
            implicitHeight: Theme.scaled(58)
            Layout.preferredHeight: Theme.scaled(58)
            radius: Theme.bubbleRadiusMedium
            color: CaffeineService.active
                   ? Qt.rgba(Theme.peach.r, Theme.peach.g, Theme.peach.b, 0.20)
                   : (caffMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
            border.color: CaffeineService.active
                          ? Qt.rgba(Theme.peach.r, Theme.peach.g, Theme.peach.b, 0.5)
                          : Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(8)
                spacing: Theme.scaled(8)

                Rectangle {
                    width: Theme.scaled(36)
                    height: Theme.scaled(36)
                    radius: Theme.scaled(10)
                    color: CaffeineService.active ? Theme.peach : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: CaffeineService.active ? "󰅶" : "󰛊"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(18)
                        color: CaffeineService.active ? Colors.background : Theme.subtext0
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Caffeine"
                        font.pixelSize: Theme.scaled(12)
                        font.weight: Font.Bold
                        color: Theme.text
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: CaffeineService.active ? "Screen Awake" : "Sleep Enabled"
                        font.pixelSize: Theme.scaled(10)
                        color: Theme.subtext0
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                id: caffMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: CaffeineService.toggle()
            }
        }

        // --- TILE 6: DO NOT DISTURB ---
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(58)
            implicitHeight: Theme.scaled(58)
            Layout.preferredHeight: Theme.scaled(58)
            radius: Theme.bubbleRadiusMedium
            color: PowerToolsService.dnd
                   ? Qt.rgba(Theme.powerRed.r, Theme.powerRed.g, Theme.powerRed.b, 0.20)
                   : (dndMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
            border.color: PowerToolsService.dnd
                          ? Qt.rgba(Theme.powerRed.r, Theme.powerRed.g, Theme.powerRed.b, 0.5)
                          : Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(8)
                spacing: Theme.scaled(8)

                Rectangle {
                    width: Theme.scaled(36)
                    height: Theme.scaled(36)
                    radius: Theme.scaled(10)
                    color: PowerToolsService.dnd ? Theme.powerRed : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: PowerToolsService.dnd ? "󰂛" : "󰂚"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(18)
                        color: PowerToolsService.dnd ? Colors.on_primary : Theme.subtext0
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Do Not Disturb"
                        font.pixelSize: Theme.scaled(12)
                        font.weight: Font.Bold
                        color: Theme.text
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: PowerToolsService.dnd ? "Muted" : "Active"
                        font.pixelSize: Theme.scaled(10)
                        color: Theme.subtext0
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                id: dndMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: PowerToolsService.toggleDnd()
            }
        }
    }

    // ==========================================
    // 2.5 MEDIA PLAYER CARD (Windows 11 / Android Style)
    // ==========================================
    MprisPlayer {
        visible: MediaPlayerService.trackedPlayer !== null
        Layout.fillWidth: true
    }

    // ==========================================
    // 3. SLIDERS SECTION (Windows / Android Style)
    // ==========================================
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.scaled(10)

        // --- VOLUME SLIDER ---
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(44)
            implicitHeight: Theme.scaled(44)
            Layout.preferredHeight: Theme.scaled(44)
            radius: Theme.scaled(12)
            color: Theme.cardBackground
            border.color: Theme.glassBorder
            border.width: 1

            MouseArea {
                anchors.fill: parent
                z: -1
                onWheel: (wheel) => {
                    let delta = wheel.angleDelta.y > 0 ? 5 : -5;
                    let newVol = Math.max(0, Math.min(100, VolumeService.outputVolume + delta));
                    VolumeService.setOutputVolume(newVol);
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(10)
                anchors.rightMargin: Theme.scaled(10)
                spacing: Theme.scaled(10)

                // Speaker Icon (Clickable to Mute/Unmute)
                Rectangle {
                    width: Theme.scaled(28)
                    height: Theme.scaled(28)
                    radius: Theme.scaled(8)
                    color: volIcoMouse.containsMouse ? Theme.cardBackgroundHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: VolumeService.muted ? "󰖁" : (VolumeService.outputVolume >= 60 ? "󰕾" : (VolumeService.outputVolume >= 20 ? "󰖀" : "󰕿"))
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(18)
                        color: VolumeService.muted ? Theme.red : Theme.accentColor
                    }

                    MouseArea {
                        id: volIcoMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: VolumeService.toggleMute()
                    }
                }

                // Interactive Slider Bar
                Item {
                    id: volSliderTrack
                    Layout.fillWidth: true
                    height: Theme.scaled(24)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: Theme.scaled(8)
                        radius: Theme.scaled(4)
                        color: Qt.rgba(1, 1, 1, 0.10)

                        // Filled Portion
                        Rectangle {
                            height: parent.height
                            width: parent.width * (Math.max(0, Math.min(100, VolumeService.outputVolume)) / 100)
                            radius: Theme.scaled(4)
                            color: VolumeService.muted ? Theme.surface2 : Theme.accentColor
                            Behavior on width { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }
                        }
                    }

                    // Floating Handle Knob
                    Rectangle {
                        x: Math.max(0, Math.min(parent.width - width, (parent.width * (Math.max(0, Math.min(100, VolumeService.outputVolume)) / 100)) - (width / 2)))
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.scaled(16)
                        height: Theme.scaled(16)
                        radius: Theme.scaled(8)
                        color: "#ffffff"
                        border.color: VolumeService.muted ? Theme.surface2 : Theme.accentColor
                        border.width: 2
                        scale: volDragArea.pressed ? 1.2 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animInstant } }
                    }

                    MouseArea {
                        id: volDragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        function updateFromMouse(mouseX) {
                            let fraction = Math.max(0, Math.min(1, mouseX / volSliderTrack.width));
                            let vol = Math.round(fraction * 100);
                            VolumeService.setOutputVolume(vol);
                        }

                        onPressed: (mouse) => updateFromMouse(mouse.x)
                        onPositionChanged: (mouse) => { if (pressed) updateFromMouse(mouse.x); }
                        onWheel: (wheel) => {
                            let delta = wheel.angleDelta.y > 0 ? 5 : -5;
                            let newVol = Math.max(0, Math.min(100, VolumeService.outputVolume + delta));
                            VolumeService.setOutputVolume(newVol);
                        }
                    }
                }

                // Volume Readout Text
                Text {
                    text: VolumeService.muted ? "Muted" : (VolumeService.outputVolume + "%")
                    font.pixelSize: Theme.scaled(11)
                    font.family: "JetBrains Mono"
                    font.weight: Font.Bold
                    color: Theme.text
                    Layout.preferredWidth: Theme.scaled(44)
                    horizontalAlignment: Text.AlignRight
                }

                // Submenu Chevron
                Rectangle {
                    width: Theme.scaled(24)
                    height: Theme.scaled(28)
                    radius: Theme.scaled(6)
                    color: volChevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        color: volChevMouse.containsMouse ? Theme.text : Theme.subtext0
                    }

                    MouseArea {
                        id: volChevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: QuickSettingsService.open("volume")
                    }
                }
            }
        }

        // --- BRIGHTNESS SLIDER ---
        Rectangle {
            visible: HardwareService.hasBacklight
            Layout.fillWidth: true
            height: Theme.scaled(44)
            implicitHeight: Theme.scaled(44)
            Layout.preferredHeight: Theme.scaled(44)
            radius: Theme.scaled(12)
            color: Theme.cardBackground
            border.color: Theme.glassBorder
            border.width: 1

            MouseArea {
                anchors.fill: parent
                z: -1
                onWheel: (wheel) => {
                    let delta = wheel.angleDelta.y > 0 ? 5 : -5;
                    let newB = Math.max(1, Math.min(100, BrightnessService.percentage + delta));
                    BrightnessService.setBrightness(newB);
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(10)
                anchors.rightMargin: Theme.scaled(10)
                spacing: Theme.scaled(10)

                // Sun Icon
                Text {
                    text: BrightnessService.percentage >= 60 ? "󰃠" : (BrightnessService.percentage >= 30 ? "󰃟" : "󰃞")
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(18)
                    color: Theme.accentColor
                    Layout.alignment: Qt.AlignVCenter
                }

                // Interactive Slider Bar
                Item {
                    id: brightSliderTrack
                    Layout.fillWidth: true
                    height: Theme.scaled(24)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: Theme.scaled(8)
                        radius: Theme.scaled(4)
                        color: Qt.rgba(1, 1, 1, 0.10)
                        antialiasing: true

                        // Filled Portion
                        Rectangle {
                            height: parent.height
                            width: parent.width * (Math.max(1, Math.min(100, BrightnessService.percentage)) / 100)
                            radius: Theme.scaled(4)
                            color: Theme.accentColor
                            antialiasing: true
                            Behavior on width { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }
                        }
                    }

                    // Floating Handle Knob
                    Rectangle {
                        x: Math.max(0, Math.min(parent.width - width, (parent.width * (Math.max(1, Math.min(100, BrightnessService.percentage)) / 100)) - (width / 2)))
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.scaled(16)
                        height: Theme.scaled(16)
                        radius: Theme.scaled(8)
                        color: "#ffffff"
                        border.color: Theme.accentColor
                        border.width: 2
                        antialiasing: true
                        scale: brightDragArea.pressed ? 1.2 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animInstant } }
                    }

                    MouseArea {
                        id: brightDragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        function updateFromMouse(mouseX) {
                            let fraction = Math.max(0.01, Math.min(1, mouseX / brightSliderTrack.width));
                            let bright = Math.round(fraction * 100);
                            BrightnessService.setBrightness(bright);
                        }

                        onPressed: (mouse) => updateFromMouse(mouse.x)
                        onPositionChanged: (mouse) => { if (pressed) updateFromMouse(mouse.x); }
                        onWheel: (wheel) => {
                            let delta = wheel.angleDelta.y > 0 ? 5 : -5;
                            let newB = Math.max(1, Math.min(100, BrightnessService.percentage + delta));
                            BrightnessService.setBrightness(newB);
                        }
                    }
                }

                // Brightness Readout Text
                Text {
                    text: BrightnessService.percentage + "%"
                    font.pixelSize: Theme.scaled(11)
                    font.family: "JetBrains Mono"
                    font.weight: Font.Bold
                    color: Theme.text
                    Layout.preferredWidth: Theme.scaled(44)
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    // ==========================================
    // 4. SESSION / POWER FOOTER ROW
    // ==========================================
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.scaled(8)

        Repeater {
            model: [
                { id: "lock",    icon: "󰌾", label: "Lock",    cmd: "loginctl lock-session" },
                { id: "sleep",   icon: "󰒲", label: "Sleep",   cmd: "systemctl suspend" },
                { id: "restart", icon: "󰑐", label: "Restart", cmd: "systemctl reboot" },
                { id: "power",   icon: "󰐥", label: "Power",   cmd: "systemctl poweroff" }
            ]

            delegate: Rectangle {
                id: pwrBtn
                Layout.fillWidth: true
                height: Theme.scaled(38)
                implicitHeight: Theme.scaled(38)
                Layout.preferredHeight: Theme.scaled(38)
                radius: Theme.bubbleRadiusSmall
                color: pwrBtnMouse.containsMouse
                       ? (modelData.id === "power" ? Qt.rgba(Theme.powerRed.r, Theme.powerRed.g, Theme.powerRed.b, 0.25) : Theme.cardBackgroundHover)
                       : Theme.cardBackground
                border.color: Theme.glassBorder
                border.width: 1
                scale: pwrBtnMouse.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.scaled(6)

                    Text {
                        text: modelData.icon
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        color: modelData.id === "power" ? Theme.powerRed : (pwrBtnMouse.containsMouse ? Theme.accentColor : Theme.text)
                    }

                    Text {
                        text: modelData.label
                        font.pixelSize: Theme.scaled(11)
                        font.weight: Font.Bold
                        color: Theme.text
                    }
                }

                MouseArea {
                    id: pwrBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        QuickSettingsService.close();
                        sessionProc.command = ["sh", "-c", modelData.cmd];
                        sessionProc.running = true;
                    }
                }
            }
        }
    }

    Process { id: sessionProc }
}
