import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.scaled(25)
    Layout.fillWidth: true

    opacity: 0
    scale: 0.98
    Component.onCompleted: {
        entryAnim.start();
    }
    ParallelAnimation {
        id: entryAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; to: 1; duration: 500; easing.type: Theme.elasticEasing }
    }

    // Matches the .toLowerCase() and .trim() in your new Service
    readonly property bool isLimitActive: (BatteryService.status === "not charging" || BatteryService.status === "full") && BatteryService.acOnline
    
    // Correcting raw sysfs units: microvolts/microwatts -> standard units (V and W)
    readonly property real displayVoltage: BatteryService.voltage > 1000 ? BatteryService.voltage / 1000000 : BatteryService.voltage
    readonly property real displayWatts: BatteryService.energyRate > 1000 ? BatteryService.energyRate / 1000000 : BatteryService.energyRate

    Text {
        text: "ENERGY STATION"
        color: Theme.blue
        font.pixelSize: 10
        font.weight: Font.Black
        font.letterSpacing: 2
        Layout.leftMargin: Theme.scaled(5)
    }

    // Main Card
    Rectangle {
        Layout.fillWidth: true
        height: Theme.scaled(140)
        color: Qt.rgba(0,0,0,0.2)
        radius: Theme.scaled(24)
        border.color: Theme.glassBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(20)
            spacing: Theme.scaled(25)

            Rectangle {
                width: Theme.scaled(80); height: Theme.scaled(80); radius: 40
                color: Qt.rgba(1,1,1,0.05)
                Text {
                    anchors.centerIn: parent
                    text: BatteryService.acOnline ? "󱐋" : "󰁹"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(32)
                    color: BatteryService.acOnline ? Theme.powerGreen : Theme.blue
                }
            }

            ColumnLayout {
                spacing: 5; Layout.fillWidth: true
                RowLayout {
                    spacing: 15
                    Text { text: BatteryService.percentage + "%"; font.pixelSize: Theme.scaled(38); font.weight: Font.Black; color: Theme.text }
                    Rectangle {
                        height: 22; width: pillText.implicitWidth + 30; radius: 11
                        color: BatteryService.acOnline ? Theme.powerGreen : Theme.surface1
                        Text { id: pillText; anchors.centerIn: parent; text: BatteryService.acOnline ? "PLUGGED" : "DISCHARGING"; color: Colors.background; font.weight: Font.Black; font.pixelSize: 9 }
                    }
                }
                Text { text: (root.isLimitActive ? "Conservative" : BatteryService.status).toUpperCase(); font.pixelSize: 10; font.weight: Font.Black; color: Theme.subtext1 }
                
                Rectangle {
                    Layout.fillWidth: true; Layout.topMargin: 10; height: 8; radius: 4; color: Qt.rgba(1,1,1,0.1)
                    Rectangle {
                        width: parent.width * (BatteryService.percentage / 100); height: parent.height; radius: 4
                        color: BatteryService.acOnline ? Theme.powerGreen : Theme.blue
                        Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    // Info Grid
    RowLayout {
        Layout.fillWidth: true; spacing: 15
        StatCard { label: "CYCLES"; value: BatteryService.cycleCount; icon: "󱂇"; accent: Theme.mauve }
        StatCard { label: "REMAINING"; value: root.isLimitActive ? "N/A" : (BatteryService.timeRemaining || "..."); icon: "󰥔"; accent: Theme.blue }
    }

    component StatCard: Rectangle {
        property string label; property var value; property string icon; property color accent
        Layout.fillWidth: true; height: 90; color: Qt.rgba(1,1,1,0.03); radius: 20; border.color: Theme.glassBorder
        ColumnLayout {
            anchors.centerIn: parent; spacing: 5
            Text { text: icon; font.family: Theme.iconFont; font.pixelSize: 24; color: accent; Layout.alignment: Qt.AlignHCenter }
            Text { text: value; color: Theme.text; font.weight: Font.Black; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
            Text { text: label; color: Theme.subtext1; font.pixelSize: 8; font.weight: Font.Black; Layout.alignment: Qt.AlignHCenter }
        }
    }
// Bottom Detailed Grid (Horizontally Aligned & Justified)
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.scaled(60) 
        color: Theme.surface0
        radius: Theme.scaled(18)
        border.color: Theme.surface1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.scaled(20)
            anchors.rightMargin: Theme.scaled(20)
            spacing: 0

            // Helper component-like logic for horizontal pairs
            // Section 1: Voltage
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(8)
                Text { text: "Voltage:"; color: Theme.subtext1; font.pixelSize: Theme.scaled(13) }
                Text { text: root.displayVoltage.toFixed(1) + "V"; color: Theme.text; font.bold: true; font.pixelSize: Theme.scaled(16) }
            }

            Item { Layout.fillWidth: true } // Spacer

            // Section 2: Wattage
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(8)
                Text { text: "Wattage:"; color: Theme.subtext1; font.pixelSize: Theme.scaled(13) }
                Text { text: root.displayWatts.toFixed(1) + "W"; color: Theme.text; font.bold: true; font.pixelSize: Theme.scaled(16) }
            }

            Item { Layout.fillWidth: true } // Spacer

// Section 3: Health (Calculated from Full / Design Energy)
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(8)
                Text { text: "Health:"; color: Theme.subtext1; font.pixelSize: Theme.scaled(13) }
                Text { 
                    // Displays health as a percentage (e.g., 94%)
                    text: BatteryService.health.toFixed(0) + "%" 
                    // Dynamic coloring: Green for healthy, Yellow for worn, Red for critical
                    color: BatteryService.health > 80 ? Theme.powerGreen : (BatteryService.health > 50 ? Theme.powerYellow : Theme.powerRed)
                    font.bold: true
                    font.pixelSize: Theme.scaled(16) 
                }
            }

            Item { Layout.fillWidth: true } // Spacer

            // Section 4: Temp (Live sensor data)
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.scaled(8)
                Text { text: "Temp:"; color: Theme.subtext1; font.pixelSize: Theme.scaled(13) }
                Text { 
                    // Checks if temp is valid, otherwise defaults to a baseline
                    text: (BatteryService.temp > 0 ? BatteryService.temp.toFixed(1) : "35.0") + "°C"
                    // Turns red if the battery gets toastier than 45°C
                    color: BatteryService.temp > 45 ? Theme.powerRed : Theme.text
                    font.bold: true
                    font.pixelSize: Theme.scaled(16) 
                }
            }
        }
    }
}