import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.scaled(14)
    Layout.fillWidth: true
    implicitHeight: mainCard.implicitHeight + infoGrid.implicitHeight + bottomGrid.implicitHeight + (root.spacing * 2)

    Component.onCompleted: {
        BatteryService.update();
    }
    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        onTriggered: BatteryService.update()
    }

    readonly property bool isLimitActive: (BatteryService.status === "not charging" || BatteryService.status === "full") && BatteryService.acOnline
    readonly property real displayVoltage: BatteryService.voltage > 1000 ? BatteryService.voltage / 1000000 : BatteryService.voltage
    readonly property real displayWatts: BatteryService.energyRate > 1000 ? BatteryService.energyRate / 1000000 : BatteryService.energyRate

    // Main Card
    Rectangle {
        id: mainCard
        Layout.fillWidth: true
        height: Theme.scaled(130)
        implicitHeight: Theme.scaled(130)
        Layout.preferredHeight: Theme.scaled(130)
        color: Theme.cardBackground
        radius: Theme.bubbleRadiusMedium
        border.color: Theme.glassBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(18)
            spacing: Theme.scaled(20)

            Rectangle {
                width: Theme.scaled(72); height: Theme.scaled(72); radius: Theme.scaled(36)
                color: "transparent"
                border.width: 0
                antialiasing: true
                Text {
                    anchors.centerIn: parent
                    text: BatteryService.acOnline ? "󰚥" : "󰁹"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(36)
                    color: (BatteryService.acOnline && BatteryService.status !== "charging") ? "#ffffff" : Theme.accentColor
                }
            }

            ColumnLayout {
                spacing: Theme.scaled(4); Layout.fillWidth: true
                RowLayout {
                    spacing: Theme.scaled(12)
                    Text { text: BatteryService.percentage + "%"; font.pixelSize: Theme.scaled(34); font.weight: Font.Black; color: Theme.text }
                    Rectangle {
                        height: Theme.scaled(22); width: pillText.implicitWidth + Theme.scaled(20); radius: Theme.scaled(11)
                        color: BatteryService.acOnline ? Theme.accentColor : Theme.menuDarkHover
                        border.width: 0
                        antialiasing: true
                        Text { id: pillText; anchors.centerIn: parent; text: BatteryService.acOnline ? (BatteryService.status === "charging" ? "CHARGING" : "PLUGGED") : "DISCHARGING"; color: BatteryService.acOnline ? Colors.on_primary : Theme.text; font.weight: Font.Black; font.pixelSize: Theme.scaled(9) }
                    }
                }
                Text { text: (root.isLimitActive ? "Conservative" : BatteryService.status).toUpperCase(); font.pixelSize: Theme.scaled(10); font.weight: Font.Black; color: Theme.subtext0 }
                
                Rectangle {
                    Layout.fillWidth: true; Layout.topMargin: Theme.scaled(6); height: Theme.scaled(6); radius: Theme.scaled(3); color: Qt.rgba(1,1,1,0.08)
                    Rectangle {
                        width: parent.width * (BatteryService.percentage / 100); height: parent.height; radius: Theme.scaled(3)
                        color: BatteryService.acOnline ? Theme.accentColor : (BatteryService.percentage <= 20 ? Theme.red : Theme.accentColor)
                        Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    // Info Grid
    RowLayout {
        id: infoGrid
        Layout.fillWidth: true
        spacing: Theme.scaled(12)
        implicitHeight: Theme.scaled(80)
        Layout.preferredHeight: Theme.scaled(80)
        StatCard { label: "CYCLES"; value: BatteryService.cycleCount; icon: "󱂇"; accent: Theme.mauve }
        StatCard { label: "REMAINING"; value: root.isLimitActive ? "N/A" : (BatteryService.timeRemaining || "..."); icon: "󰥔"; accent: Theme.accentColor }
    }

    component StatCard: Rectangle {
        property string label; property var value; property string icon; property color accent
        Layout.fillWidth: true
        height: Theme.scaled(80)
        implicitHeight: Theme.scaled(80)
        Layout.preferredHeight: Theme.scaled(80)
        color: Theme.cardBackground
        radius: Theme.bubbleRadiusMedium
        border.color: Theme.glassBorder
        border.width: 1
        ColumnLayout {
            anchors.centerIn: parent; spacing: Theme.scaled(4)
            Text { text: icon; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(24); color: accent; Layout.alignment: Qt.AlignHCenter }
            Text { text: value; color: Theme.text; font.weight: Font.Black; font.pixelSize: Theme.scaled(13); Layout.alignment: Qt.AlignHCenter }
            Text { text: label; color: Theme.subtext0; font.pixelSize: Theme.scaled(8); font.weight: Font.Black; Layout.alignment: Qt.AlignHCenter }
        }
    }

    // Bottom Detailed Grid
    Rectangle {
        id: bottomGrid
        Layout.fillWidth: true
        height: Theme.scaled(56)
        implicitHeight: Theme.scaled(56)
        Layout.preferredHeight: Theme.scaled(56) 
        color: Theme.cardBackground
        radius: Theme.bubbleRadiusMedium
        border.color: Theme.glassBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.scaled(20)
            anchors.rightMargin: Theme.scaled(20)
            spacing: 0

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(8)
                Text { text: "Voltage:"; color: Theme.subtext1; font.pixelSize: Theme.scaled(13) }
                Text { text: root.displayVoltage.toFixed(1) + "V"; color: Theme.text; font.bold: true; font.pixelSize: Theme.scaled(16) }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(8)
                Text { text: "Wattage:"; color: Theme.subtext1; font.pixelSize: Theme.scaled(13) }
                Text { text: root.displayWatts.toFixed(1) + "W"; color: Theme.text; font.bold: true; font.pixelSize: Theme.scaled(16) }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(8)
                Text { text: "Health:"; color: Theme.subtext1; font.pixelSize: Theme.scaled(13) }
                Text { 
                    text: BatteryService.health.toFixed(0) + "%" 
                    color: BatteryService.health > 80 ? Theme.powerGreen : (BatteryService.health > 50 ? Theme.powerYellow : Theme.powerRed)
                    font.bold: true
                    font.pixelSize: Theme.scaled(16) 
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(8)
                Text { text: "Temp:"; color: Theme.subtext1; font.pixelSize: Theme.scaled(13) }
                Text { 
                    text: (BatteryService.temp > 0 ? BatteryService.temp.toFixed(1) : "35.0") + "°C"
                    color: BatteryService.temp > 45 ? Theme.powerRed : Theme.text
                    font.bold: true
                    font.pixelSize: Theme.scaled(16) 
                }
            }
        }
    }

    // Helper text
    Text {
        Layout.fillWidth: true
        text: "Battery telemetry monitored via upower and kernel sysfs. Toggle conservation mode to limit charging for battery longevity."
        color: Theme.subtext0
        font.pixelSize: Theme.scaled(10)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        Layout.alignment: Qt.AlignHCenter
    }
}