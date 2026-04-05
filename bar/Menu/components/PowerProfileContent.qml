import "../../.."
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 28
    Layout.fillWidth: true

    // --- Header ---
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "PERFORMANCE MODES"
            color: "#cba6f7" // Mauve header to distinguish from system monitor
            font.pixelSize: 14
            font.letterSpacing: 2
            font.weight: Font.Black
            opacity: 0.8
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: "#313244"; opacity: 0.4; Layout.leftMargin: 10 }
    }

    GridLayout {
        columns: 2
        Layout.fillWidth: true
        rowSpacing: 15
        columnSpacing: 15

        Repeater {
            model: [
                { id: "performance", icon: "󰀦", color: "#f38ba8", label: "Performance" },
                { id: "balanced",    icon: "󰏤", color: "#89b4fa", label: "Balanced" },
                { id: "powersave",   icon: "󰍛", color: "#a6e3a1", label: "Power Save" },
                { id: "turbo",       icon: "󰞃", color: "#f9e2af", label: "Turbo" }
            ]

            delegate: Rectangle {
                id: profileCard
                Layout.fillWidth: true
                height: 80
                color: "#11111b" // Deep navy base
                radius: 20
                border.width: 1
                // Border lights up when active
                border.color: PowerProfileService.currentProfile === modelData.id ? modelData.color : "#313244"
                
                clip: true // Critical for the liquid fill rounding

                // --- Liquid Fill Logic ---
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    
                    // If active, height is 100%, else 0%
                    height: PowerProfileService.currentProfile === modelData.id ? parent.height : 0
                    radius: 20
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
                    anchors.margins: 15
                    spacing: 12

                    // Icon Circle
                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: PowerProfileService.currentProfile === modelData.id ? Qt.alpha(modelData.color, 0.2) : "#181825"
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: Theme.iconFont
                            font.pixelSize: 20
                            color: PowerProfileService.currentProfile === modelData.id ? modelData.color : "#585b70"
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: modelData.label
                            font.pixelSize: 14
                            font.weight: Font.Black
                            color: PowerProfileService.currentProfile === modelData.id ? "white" : "#cdd6f4"
                        }
                        Text {
                            text: PowerProfileService.currentProfile === modelData.id ? "ACTIVE" : "SELECT"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            font.letterSpacing: 1
                            color: PowerProfileService.currentProfile === modelData.id ? modelData.color : "#585b70"
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}