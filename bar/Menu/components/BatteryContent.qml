import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 20
    Layout.fillWidth: true

    Text {
        text: "Battery"
        color: "white"
        font.bold: true
        font.pixelSize: 22
    }

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

            // Large Battery Icon with Progress
            Item {
                width: 100; height: 100
                
                Rectangle {
                    anchors.fill: parent
                    radius: 50
                    color: "#2a2a32"
                    
                    // Circular progress ring (simplified as a rounded rectangle fill for now)
                    Text {
                        anchors.centerIn: parent
                        text: BatteryService.acOnline ? "󰂄" : (BatteryService.percentage > 90 ? "󰁹" : (BatteryService.percentage > 50 ? "󰂀" : (BatteryService.percentage > 20 ? "󰁽" : "󰂃")))
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
                        height: 24; width: 80; radius: 12
                        color: BatteryService.acOnline ? "#a6e3a1" : "#313244"
                        visible: BatteryService.acOnline
                        Text { 
                            anchors.centerIn: parent; 
                            text: "Charging"; 
                            color: "black"; 
                            font.bold: true; 
                            font.pixelSize: 11 
                        }
                    }
                }
                
                Text {
                    text: BatteryService.status + (BatteryService.acOnline ? " • Power Source: AC" : " • On Battery")
                    font.pixelSize: 14
                    color: "#a6adc8"
                }
                
                // Progress bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    height: 12
                    radius: 6
                    color: "#313244"
                    
                    Rectangle {
                        width: parent.width * (BatteryService.percentage / 100)
                        height: parent.height
                        radius: 6
                        color: BatteryService.acOnline ? "#a6e3a1" : (BatteryService.percentage > 20 ? Theme.accentColor : "#f38ba8")
                        
                        Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    // Additional info cards
    RowLayout {
        Layout.fillWidth: true
        spacing: 15

        Rectangle {
            Layout.fillWidth: true
            height: 100
            color: "#1e1e2e"
            radius: 18
            border.color: "#313244"
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 5
                Text { text: "󰚥"; font.family: Theme.iconFont; font.pixelSize: 24; color: "#fab387"; Layout.alignment: Qt.AlignHCenter }
                Text { text: "Health: Good"; color: "white"; font.bold: true; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 100
            color: "#1e1e2e"
            radius: 18
            border.color: "#313244"
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 5
                Text { text: "󰥔"; font.family: Theme.iconFont; font.pixelSize: 24; color: "#89b4fa"; Layout.alignment: Qt.AlignHCenter }
                Text { text: "Time left: 4h 20m"; color: "white"; font.bold: true; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
