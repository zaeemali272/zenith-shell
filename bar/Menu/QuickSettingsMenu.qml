import "../.."
import "../../services"
import "./components"
import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root

    property var parentWindow: null

    onVisibleChanged: {
        if (visible) {
            console.log("QuickSettingsMenu visible:", visible, "parentWindow:", parentWindow)
        }
    }

    visible: QuickSettingsService.qsVisible
    color: "transparent"
    
    // Anchor to the bar window
    anchor.window: parentWindow
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    
    anchor.rect: {
        const buttonRect = QuickSettingsService.anchorRect;
        const barHeight = (parentWindow && parentWindow.height > 0) ? parentWindow.height : 45;
        const barWidth = (parentWindow && parentWindow.width > 0) ? parentWindow.width : 1920;

        if (!buttonRect || buttonRect.width <= 0) {
            return Qt.rect(barWidth - implicitWidth - 10, barHeight, 0, 0); 
        }

        const buttonCenterX = buttonRect.x + buttonRect.width / 2;
        const popupHalfWidth = implicitWidth / 2;
        
        // Offset to the right: instead of pure centering, we favor the right side
        // while still trying to stay near the button if possible.
        // To "attach to the right side", we can shift the desired center.
        const desiredPopupLeftX = buttonCenterX - (popupHalfWidth * 0.5); 

        // Clamp to screen bounds with 10px margin
        const boundedX = Math.max(10, Math.min(barWidth - implicitWidth - 10, desiredPopupLeftX));

        return Qt.rect(Math.round(boundedX), barHeight, 0, 0);
    }

    // Dynamic width based on the wide tabs layout
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
        
        MouseArea {
            id: menuMouse
            anchors.top: parent.top
            anchors.topMargin: -8 
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            hoverEnabled: true
            onContainsMouseChanged: {
                if (!containsMouse) QuickSettingsService.startHideTimer();
                else QuickSettingsService.stopHideTimer();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // Modern Tab Buttons (Android-like Pill buttons)
            RowLayout {
                id: tabRow
                Layout.fillWidth: true
                spacing: 12 // Increased spacing between tabs
                
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
                            spacing: 10 // Increased spacing between icon and text
                            
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
                            hoverEnabled: true
                            onClicked: QuickSettingsService.activeTab = modelData.id
                        }
                    }
                }
            }

            // Divider
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

                WifiContent { Layout.fillWidth: true; Layout.fillHeight: true }
                BluetoothContent { Layout.fillWidth: true; Layout.fillHeight: true }
                VolumeContent { Layout.fillWidth: true; Layout.fillHeight: true }
                PowerProfileContent { Layout.fillWidth: true; Layout.fillHeight: true }
                ResourcesContent { Layout.fillWidth: true; Layout.fillHeight: true }
                BatteryContent { Layout.fillWidth: true; Layout.fillHeight: true }
                PowerContent { Layout.fillWidth: true; Layout.fillHeight: true }
            }
        }
    }
}
