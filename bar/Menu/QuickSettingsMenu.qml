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
    grabFocus: QuickSettingsService.isSticky

    HyprlandFocusGrab {
        active: root.visible && QuickSettingsService.isSticky
        windows: [root, parentWindow]
        onCleared: QuickSettingsService.close()
    }
    
    onVisibleChanged: {
        if (visible && QuickSettingsService.isSticky) {
            mainContent.forceActiveFocus();
        }
    }
    
    // Position the window relative to the bar
    anchor.window: parentWindow
    // Anchored to the bottom-right corner of the parent window.
    anchor.edges: Edges.Bottom | Edges.Right 
    anchor.gravity: Edges.Bottom | Edges.Right
    
    // Attached to top-right side below the bar
    anchor.rect: {
        const barHeight = (parentWindow && parentWindow.height > 0) ? parentWindow.height : 45;
        const barWidth = (parentWindow && parentWindow.width > 0) ? parentWindow.width : 1920;
        
        // Align the right edge of the popup with the right edge of the bar, offset by 10px margin.
        // The top edge is aligned with the bottom of the bar.
        return Qt.rect(barWidth - implicitWidth - 10, barHeight, 0, 0);
    }

    implicitWidth: 650 
    implicitHeight: 600

    Rectangle {
        id: mainContent
        anchors.fill: parent
        anchors.topMargin: 8
        color: "#0f0f14"
        radius: 28
        border.color: "#2a2a32"
        border.width: 1

        layer.enabled: true
        
        // Background clicks and focus management
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                mouse.accepted = true; // Consume to prevent focus loss
                mainContent.forceActiveFocus();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // Modern Tab Buttons
            RowLayout {
                id: tabRow
                Layout.fillWidth: true
                spacing: 12
                
                Repeater {
                    model: [
                        { id: "network", icon: "󰤨", title: "Wi-Fi" },
                        { id: "bluetooth", icon: "󰂯", title: "BT" },
                        { id: "volume", icon: "󰕾", title: "Audio" },
                        { id: "powerprofile", icon: "󰍛", title: "Mode" },
                        { id: "resources", icon: "󰘚", title: "System" },
                        { id: "battery", icon: "󰁹", title: "Power" },
                        { id: "power", icon: "󰐥", title: "Exit" }
                    ]

                    delegate: Rectangle {
                        id: tabButton
                        Layout.fillWidth: true
                        height: 48
                        radius: 24
                        color: QuickSettingsService.activeTab === modelData.id ? Theme.accentColor : "#1e1e2e"
                        
                        Behavior on color { ColorAnimation { duration: 200 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            
                            Text {
                                text: modelData.icon
                                font.family: Theme.iconFont
                                font.pixelSize: 18
                                color: QuickSettingsService.activeTab === modelData.id ? "#000000" : "white"
                            }
                            
                            Text {
                                text: modelData.title
                                font.pixelSize: 13
                                font.bold: true
                                color: QuickSettingsService.activeTab === modelData.id ? "#000000" : "white"
                                visible: root.implicitWidth > 550
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log(`[QuickSettingsMenu] Tab clicked: ${modelData.id}`)
                                QuickSettingsService.activeTab = modelData.id
                            }
                        }
                    }
                }
            }

            Rectangle { 
                Layout.fillWidth: true; 
                height: 1; 
                color: "#2a2a32" 
                Layout.topMargin: 5
                Layout.bottomMargin: 5
            }

            // Content Area
            StackLayout {
                id: contentStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: {
                    switch (QuickSettingsService.activeTab) {
                        case "network": return 0;
                        case "bluetooth": return 1;
                        case "volume": return 2;
                        case "powerprofile": return 3;
                        case "resources": return 4;
                        case "battery": return 5;
                        case "power": return 6;
                        default: return 0;
                    }
                }

                WifiContent { }
                BluetoothContent { }
                VolumeContent { }
                PowerProfileContent { }
                ResourcesContent { }
                BatteryContent { }
                PowerContent { }
            }
        }

        // Hover tracking (on top of everything but blocks nothing)
        MouseArea {
            id: hoverTracker
            anchors.fill: parent
            anchors.topMargin: -12
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            
            onEntered: QuickSettingsService.isHoveringMenu = true
            onExited: QuickSettingsService.isHoveringMenu = false
        }
    }
}
