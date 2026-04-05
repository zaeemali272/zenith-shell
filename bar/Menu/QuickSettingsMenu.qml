import "../.."
import "../../services"
import "./components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PopupWindow {
    id: root

    property var parentWindow: null
    visible: QuickSettingsService.qsVisible
    color: "transparent"
    
    // Focus & Grab logic
    grabFocus: QuickSettingsService.isSticky
    HyprlandFocusGrab {
        active: root.visible && QuickSettingsService.isSticky
        windows: [root, parentWindow]
        onCleared: QuickSettingsService.close()
    }
    
    // Positioning
    anchor.window: parentWindow
    anchor.edges: Edges.Bottom | Edges.Right 
    anchor.gravity: Edges.Bottom | Edges.Right
    
    anchor.rect: {
        const barHeight = (parentWindow && parentWindow.height > 0) ? parentWindow.height : 45;
        const barWidth = (parentWindow && parentWindow.width > 0) ? parentWindow.width : 1920;
        return Qt.rect(barWidth - implicitWidth - 10, barHeight + 10, 0, 0);
    }

    implicitWidth: 650 
    implicitHeight: 570

    Rectangle {
        id: mainContent
        anchors.fill: parent
        color: "#11111b"
        radius: 24
        border.color: "#313244"
        border.width: 1

        // Inner Shadow/Glow effect
        layer.enabled: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // --- MODERN TAB BAR ---
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: "#181825"
                radius: 16
                border.color: "#313244"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4
                    
                    Repeater {
                        model: [
                            { id: "network", icon: "󰤨", title: "Wi-Fi" },
                            { id: "bluetooth", icon: "󰂯", title: "BT" },
                            { id: "volume", icon: "󰕾", title: "Audio" },
                            { id: "powerprofile", icon: "󰍛", title: "Mode" },
                            { id: "resources", icon: "󰘚", title: "Sys" },
                            { id: "battery", icon: "󰁹", title: "Pwr" },
                            { id: "power", icon: "󰐥", title: "Exit" }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            // Active tab gets the accent color, others are transparent
                            color: QuickSettingsService.activeTab === modelData.id ? "#89b4fa" : "transparent"
                            
                            Behavior on color { ColorAnimation { duration: 200 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    text: modelData.icon
                                    font.family: Theme.iconFont; font.pixelSize: 18
                                    color: QuickSettingsService.activeTab === modelData.id ? "#11111b" : "#a6adc8"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: modelData.title
                                    font.pixelSize: 10; font.weight: Font.Black
                                    color: QuickSettingsService.activeTab === modelData.id ? "#11111b" : "#585b70"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true
                                onClicked: QuickSettingsService.activeTab = modelData.id
                            }
                        }
                    }
                }
            }

            // --- CONTENT AREA ---
            StackLayout {
                id: contentStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: ["network", "bluetooth", "volume", "powerprofile", "resources", "battery", "power"].indexOf(QuickSettingsService.activeTab)

                WifiContent { }
                BluetoothContent { }
                VolumeContent { }
                PowerProfileContent { }
                ResourcesContent { }
                BatteryContent { }
                PowerContent { }
            }
        }

        // Hover tracking to prevent accidental closure
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: QuickSettingsService.isHoveringMenu = true
            onExited: QuickSettingsService.isHoveringMenu = false
        }
    }
}