import "../../.."
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.scaled(28)
    Layout.fillWidth: true

    // --- Header ---
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "PERFORMANCE MODES"
            color: Theme.mauve // Mauve header to distinguish from system monitor
            font.pixelSize: Theme.scaled(14)
            font.letterSpacing: 2
            font.weight: Font.Black
            opacity: 0.8
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface1; opacity: 0.4; Layout.leftMargin: Theme.scaled(10) }
    }

    GridLayout {
        columns: 2
        Layout.fillWidth: true
        rowSpacing: Theme.scaled(15)
        columnSpacing: Theme.scaled(15)

        Repeater {
            model: [
                { id: "performance", icon: "󰀦", color: Theme.powerRed, label: "Performance" },
                { id: "balanced",    icon: "󰏤", color: Theme.blue, label: "Balanced" },
                { id: "powersave",   icon: "󰍛", color: Theme.powerGreen, label: "Power Save" },
                { id: "turbo",       icon: "󰞃", color: Theme.powerYellow, label: "Turbo" }
            ]

            delegate: Rectangle {
                id: profileCard
                Layout.fillWidth: true
                height: Theme.scaled(80)
                color: Theme.menuBackground // Deep navy base
                radius: Theme.scaled(20)
                border.width: 1
                // Border lights up when active
                border.color: PowerProfileService.currentProfile === modelData.id ? modelData.color : Theme.surface1
                
                clip: true // Critical for the liquid fill rounding

                // --- Liquid Fill Logic ---
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    
                    // If active, height is 100%, else 0%
                    height: PowerProfileService.currentProfile === modelData.id ? parent.height : 0
                    radius: Theme.scaled(20)
                    color: modelData.color
                    opacity: 0.15 // Subtle highlight fill

                    Behavior on height { 
                        NumberAnimation { duration: 400; easing.type: Easing.OutCubic } 
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: PowerProfileService.setProfile(modelData.id)
                    onPressed: profileCard.scale = 0.97
                    onReleased: profileCard.scale = 1.0
                }
                
                Behavior on scale { NumberAnimation { duration: 100 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.scaled(15)
                    spacing: Theme.scaled(12)

                    // Icon Circle
                    Rectangle {
                        width: Theme.scaled(40); height: Theme.scaled(40); radius: Theme.scaled(20)
                        color: PowerProfileService.currentProfile === modelData.id ? Qt.alpha(modelData.color, 0.2) : Theme.mantle
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(20)
                            color: PowerProfileService.currentProfile === modelData.id ? modelData.color : Theme.surface2
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    ColumnLayout {
                        spacing: Theme.scaled(2)
                        Text {
                            text: modelData.label
                            font.pixelSize: Theme.scaled(14)
                            font.weight: Font.Black
                            color: PowerProfileService.currentProfile === modelData.id ? Theme.text : Theme.text
                        }
                        Text {
                            text: PowerProfileService.currentProfile === modelData.id ? "ACTIVE" : "SELECT"
                            font.pixelSize: Theme.scaled(9)
                            font.weight: Font.Bold
                            font.letterSpacing: 1
                            color: PowerProfileService.currentProfile === modelData.id ? modelData.color : Theme.surface2
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}