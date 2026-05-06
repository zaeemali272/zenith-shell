import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.scaled(15)
    Layout.fillWidth: true

    // Matches the .toLowerCase() and .trim() in your new Service
    readonly property bool isLimitActive: (BatteryService.status === "not charging" || BatteryService.status === "full") && BatteryService.acOnline
    
    // Correcting raw sysfs units: microvolts/microwatts -> standard units (V and W)
    readonly property real displayVoltage: BatteryService.voltage > 1000 ? BatteryService.voltage / 1000000 : BatteryService.voltage
    readonly property real displayWatts: BatteryService.energyRate > 1000 ? BatteryService.energyRate / 1000000 : BatteryService.energyRate

    Text {
        text: "Battery"
        color: Theme.text
        font.bold: true
        font.pixelSize: Theme.scaled(22)
    }

    // Main Card
    Rectangle {
        Layout.fillWidth: true
        height: Theme.scaled(160)
        color: Theme.surface0
        radius: Theme.scaled(24)
        border.color: Theme.surface1
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(25)
            spacing: Theme.scaled(30)

            Item {
                width: Theme.scaled(100); height: Theme.scaled(100)
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.scaled(50)
                    color: Theme.mantle
                    Text {
                        anchors.centerIn: parent
                        text: BatteryService.acOnline ? "󱐋" : (BatteryService.percentage > 90 ? "󰁹" : (BatteryService.percentage > 50 ? "󰂀" : (BatteryService.percentage > 20 ? "󰁽" : "󰂃")))
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(48)
                        color: BatteryService.acOnline ? Theme.powerGreen : (BatteryService.percentage > 20 ? Theme.accentColor : Theme.powerRed)
                    }
                }
            }

            ColumnLayout {
                spacing: Theme.scaled(5)
                Layout.fillWidth: true
                
                RowLayout {
                    spacing: Theme.scaled(10)
                    Text {
                        text: BatteryService.percentage + "%"
                        font.pixelSize: Theme.scaled(42)
                        font.bold: true
                        color: Theme.text
                    }
                    
                    Rectangle {
                        height: Theme.scaled(26); width: pillText.implicitWidth + Theme.scaled(50); radius: Theme.scaled(13)
                        color: root.isLimitActive ? Theme.powerYellow : (BatteryService.acOnline ? Theme.powerGreen : Theme.surface1)
                        
                        Text { 
                            id: pillText
                            anchors.centerIn: parent; 
                            text: root.isLimitActive ? "Conservative Mode" : (BatteryService.acOnline ? "Plugged In" : "Plugged Out"); 
                            color: Colors.background; 
                            font.bold: true; 
                            font.pixelSize: Theme.scaled(11) 
                        }
                    }
                }
                
                Text {
                    text: (root.isLimitActive ? "Conservative" : BatteryService.status) + (BatteryService.acOnline ? " • Power Source: AC" : " • On Battery")
                    font.pixelSize: Theme.scaled(14)
                    color: Theme.subtext0
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.scaled(10)
                    height: Theme.scaled(12); radius: Theme.scaled(6); color: Theme.surface1
                    Rectangle {
                        width: parent.width * (BatteryService.percentage / 100)
                        height: parent.height; radius: Theme.scaled(6)
                        color: BatteryService.acOnline ? Theme.powerGreen : (BatteryService.percentage > 20 ? Theme.accentColor : Theme.powerRed)
                        Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    // Cycles & Time
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.scaled(15)

        Rectangle {
            Layout.fillWidth: true; height: Theme.scaled(145); color: Theme.surface0; radius: Theme.scaled(18); border.color: Theme.surface1
            ColumnLayout {
                anchors.centerIn: parent; spacing: Theme.scaled(4)
                Text { text: "󱂇"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(40); color: Theme.mauve; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    // Now using the real cycleCount property from the service
                    text: "Cycles: " + BatteryService.cycleCount
                    color: Theme.text; font.bold: true; font.pixelSize: Theme.scaled(15); Layout.alignment: Qt.AlignHCenter 
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: Theme.scaled(145); color: Theme.surface0; radius: Theme.scaled(18); border.color: Theme.surface1
            ColumnLayout {
                anchors.centerIn: parent; spacing: Theme.scaled(4)
                Text { text: "󰥔"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(40); color: Theme.blue; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    // Forces N/A when limit is active or battery is full
                    text: "Left: " + (root.isLimitActive ? "N/A" : (BatteryService.timeRemaining || "Calculating..."))
                    color: Theme.text; font.bold: true; font.pixelSize: Theme.scaled(15); Layout.alignment: Qt.AlignHCenter 
                }
            }
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