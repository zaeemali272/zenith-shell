import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 15
    Layout.fillWidth: true

    // Matches the .toLowerCase() and .trim() in your new Service
    readonly property bool isLimitActive: (BatteryService.status === "not charging" || BatteryService.status === "full") && BatteryService.acOnline
    
    // Correcting raw sysfs units: microvolts/microwatts -> standard units (V and W)
    readonly property real displayVoltage: BatteryService.voltage > 1000 ? BatteryService.voltage / 1000000 : BatteryService.voltage
    readonly property real displayWatts: BatteryService.energyRate > 1000 ? BatteryService.energyRate / 1000000 : BatteryService.energyRate

    Text {
        text: "Battery"
        color: "white"
        font.bold: true
        font.pixelSize: 22
    }

    // Main Card
    Rectangle {
        Layout.fillWidth: true
        height: 160
        color: "#1e1e2e"
        radius: 24
        border.color: "#313244"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 30

            Item {
                width: 100; height: 100
                Rectangle {
                    anchors.fill: parent
                    radius: 50
                    color: "#2a2a32"
                    Text {
                        anchors.centerIn: parent
                        text: BatteryService.acOnline ? "󱐋" : (BatteryService.percentage > 90 ? "󰁹" : (BatteryService.percentage > 50 ? "󰂀" : (BatteryService.percentage > 20 ? "󰁽" : "󰂃")))
                        font.family: Theme.iconFont
                        font.pixelSize: 48
                        color: BatteryService.acOnline ? "#a6e3a1" : (BatteryService.percentage > 20 ? Theme.accentColor : "#f38ba8")
                    }
                }
            }

            ColumnLayout {
                spacing: 5
                Layout.fillWidth: true
                
                RowLayout {
                    spacing: 10
                    Text {
                        text: BatteryService.percentage + "%"
                        font.pixelSize: 42
                        font.bold: true
                        color: "white"
                    }
                    
                    Rectangle {
                        height: 26; width: pillText.implicitWidth + 50; radius: 13
                        color: root.isLimitActive ? "#fab387" : (BatteryService.acOnline ? "#a6e3a1" : "#313244")
                        
                        Text { 
                            id: pillText
                            anchors.centerIn: parent; 
                            text: root.isLimitActive ? "Conservative Mode" : (BatteryService.acOnline ? "Plugged In" : "Plugged Out"); 
                            color: "black"; 
                            font.bold: true; 
                            font.pixelSize: 11 
                        }
                    }
                }
                
                Text {
                    text: (root.isLimitActive ? "Conservative" : BatteryService.status) + (BatteryService.acOnline ? " • Power Source: AC" : " • On Battery")
                    font.pixelSize: 14
                    color: "#a6adc8"
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    height: 12; radius: 6; color: "#313244"
                    Rectangle {
                        width: parent.width * (BatteryService.percentage / 100)
                        height: parent.height; radius: 6
                        color: BatteryService.acOnline ? "#a6e3a1" : (BatteryService.percentage > 20 ? Theme.accentColor : "#f38ba8")
                        Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    // Cycles & Time
    RowLayout {
        Layout.fillWidth: true
        spacing: 15

        Rectangle {
            Layout.fillWidth: true; height: 145; color: "#1e1e2e"; radius: 18; border.color: "#313244"
            ColumnLayout {
                anchors.centerIn: parent; spacing: 4
                Text { text: "󱂇"; font.family: Theme.iconFont; font.pixelSize: 40; color: "#cba6f7"; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    // Now using the real cycleCount property from the service
                    text: "Cycles: " + BatteryService.cycleCount
                    color: "white"; font.bold: true; font.pixelSize: 15; Layout.alignment: Qt.AlignHCenter 
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 145; color: "#1e1e2e"; radius: 18; border.color: "#313244"
            ColumnLayout {
                anchors.centerIn: parent; spacing: 4
                Text { text: "󰥔"; font.family: Theme.iconFont; font.pixelSize: 40; color: "#89b4fa"; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    // Forces N/A when limit is active or battery is full
                    text: "Left: " + (root.isLimitActive ? "N/A" : (BatteryService.timeRemaining || "Calculating..."))
                    color: "white"; font.bold: true; font.pixelSize: 15; Layout.alignment: Qt.AlignHCenter 
                }
            }
        }
    }
// Bottom Detailed Grid (Horizontally Aligned & Justified)
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 60 
        color: "#1e1e2e"
        radius: 18
        border.color: "#313244"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 0

            // Helper component-like logic for horizontal pairs
            // Section 1: Voltage
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8
                Text { text: "Voltage:"; color: "#6c7086"; font.pixelSize: 13 }
                Text { text: root.displayVoltage.toFixed(1) + "V"; color: "white"; font.bold: true; font.pixelSize: 16 }
            }

            Item { Layout.fillWidth: true } // Spacer

            // Section 2: Wattage
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8
                Text { text: "Wattage:"; color: "#6c7086"; font.pixelSize: 13 }
                Text { text: root.displayWatts.toFixed(1) + "W"; color: "white"; font.bold: true; font.pixelSize: 16 }
            }

            Item { Layout.fillWidth: true } // Spacer

// Section 3: Health (Calculated from Full / Design Energy)
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8
                Text { text: "Health:"; color: "#6c7086"; font.pixelSize: 13 }
                Text { 
                    // Displays health as a percentage (e.g., 94%)
                    text: BatteryService.health.toFixed(0) + "%" 
                    // Dynamic coloring: Green for healthy, Yellow for worn, Red for critical
                    color: BatteryService.health > 80 ? "#a6e3a1" : (BatteryService.health > 50 ? "#f9e2af" : "#f38ba8")
                    font.bold: true
                    font.pixelSize: 16 
                }
            }

            Item { Layout.fillWidth: true } // Spacer

            // Section 4: Temp (Live sensor data)
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8
                Text { text: "Temp:"; color: "#6c7086"; font.pixelSize: 13 }
                Text { 
                    // Checks if temp is valid, otherwise defaults to a baseline
                    text: (BatteryService.temp > 0 ? BatteryService.temp.toFixed(1) : "35.0") + "°C"
                    // Turns red if the battery gets toastier than 45°C
                    color: BatteryService.temp > 45 ? "#f38ba8" : "white"
                    font.bold: true
                    font.pixelSize: 16 
                }
            }
        }
    }
}