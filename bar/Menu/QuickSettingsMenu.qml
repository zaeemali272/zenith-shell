import "../.."
import "../../services"
import "../../Settings"
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
    
    grabFocus: true

    // Removed HyprlandFocusGrab to prevent instant close on widget click
    
    onVisibleChanged: {
        if (visible) {
            mainContent.forceActiveFocus();
        }
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
        focus: true
        color: Theme.menuBackground
        radius: Theme.menuRadius
        border.color: hoverTracker.containsMouse ? Theme.menuHoverBorder : Theme.menuBorder
        border.width: 1

        // MouseArea for background handling - keeps focus and tracks hover
        MouseArea {
            id: hoverTracker
            anchors.fill: parent
            hoverEnabled: true
            // acceptedButtons: Qt.NoButton is problematic for focus
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onContainsMouseChanged: QuickSettingsService.isHoveringMenu = containsMouse
            onPressed: (mouse) => {
                mouse.accepted = false; // Let events propagate to children
                mainContent.forceActiveFocus();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.menuPadding
            spacing: Theme.menuSpacing

            // --- MODERN TAB BAR ---
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: Theme.mantle
                radius: 16
                border.color: Theme.menuBorder

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
                            id: tabRect
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: QuickSettingsService.activeTab === modelData.id ? Theme.accentColor : (tabMouse.containsMouse ? "#1e1e2e" : "transparent")
                            
                            Behavior on color { ColorAnimation { duration: 200 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    text: modelData.icon
                                    font.family: Theme.iconFont; font.pixelSize: 18
                                    color: QuickSettingsService.activeTab === modelData.id ? "black" : (tabMouse.containsMouse ? "white" : Theme.subtext0)
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: modelData.title
                                    font.pixelSize: 10; font.weight: Font.Black
                                    color: QuickSettingsService.activeTab === modelData.id ? "black" : (tabMouse.containsMouse ? "white" : Theme.surface2)
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent; hoverEnabled: true
                                onClicked: QuickSettingsService.activeTab = modelData.id
                                onEntered: {
                                    if (QuickSettingsService.qsVisible) {
                                        QuickSettingsService.activeTab = modelData.id;
                                    }
                                }
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
    }
}
