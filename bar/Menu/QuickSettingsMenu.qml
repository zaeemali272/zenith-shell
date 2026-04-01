import "../.."
import "../../services"
import "./components"
import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root

    property var parentWindow: null

    onVisibleChanged: console.log("QuickSettingsMenu visible:", visible, "parentWindow:", parentWindow)

    visible: QuickSettingsService.qsVisible
    color: "transparent"
    
    // Anchor to the bar window
    anchor.window: parentWindow
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    
    anchor.rect: {
        // Rely on QuickSettingsService.anchorRect being set correctly by the trigger
        // The trigger uses mapToItem(null, ...), which in Quickshell maps to the window root.
        const buttonRect = QuickSettingsService.anchorRect;
        
        if (visible) {
            console.log("QuickSettingsMenu anchor.rect calculating:", JSON.stringify(buttonRect));
        }

        // Fallback dimensions if bar is not ready
        const barHeight = (parentWindow && parentWindow.height > 0) ? parentWindow.height : 45;
        const barWidth = (parentWindow && parentWindow.width > 0) ? parentWindow.width : 1920;

        // If buttonRect is invalid, return a default position
        if (!buttonRect || buttonRect.width <= 0) {
            return Qt.rect(10, barHeight, 0, 0); 
        }

        // Calculate popup's left edge to center it relative to the button's center
        const buttonCenterX = buttonRect.x + buttonRect.width / 2;
        const popupHalfWidth = implicitWidth / 2;
        const desiredPopupLeftX = buttonCenterX - popupHalfWidth;

        // Clamp desiredX to stay within window bounds (10px margin from left/right)
        const boundedX = Math.max(10, Math.min(barWidth - implicitWidth - 10, desiredPopupLeftX));

        // Y position: Place it at the bottom of the bar
        return Qt.rect(Math.round(boundedX), barHeight, 0, 0);
    }

    implicitWidth: 400
    implicitHeight: 550

    Rectangle {
        id: mainContent
        anchors.fill: parent
        // Visual gap between bar and menu
        anchors.topMargin: 8
        color: "#111111"
        radius: 16
        border.color: "#313244"
        border.width: 1

        MouseArea {
            id: menuMouse
            // Cover the gap area by anchoring to parent window's top
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
            anchors.margins: 20
            spacing: 15

            // Tab Buttons (Android-like)
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Repeater {
                    model: [
                        { id: "network", icon: "󰤨" },
                        { id: "bluetooth", icon: "󰂯" },
                        { id: "volume", icon: "󰕾" },
                        { id: "powerprofile", icon: "󰍛" },
                        { id: "battery", icon: "󰁹" },
                        { id: "power", icon: "󰐥" }
                    ]

                    delegate: Rectangle {
                        width: 50; height: 50
                        radius: 25
                        color: QuickSettingsService.activeTab === modelData.id ? Theme.accentColor : "#1e1e2e"
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: Theme.iconFont
                            font.pixelSize: 20
                            color: QuickSettingsService.activeTab === modelData.id ? "black" : "white"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: QuickSettingsService.activeTab = modelData.id
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#313244" }

            // Content Area
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: {
                    switch (QuickSettingsService.activeTab) {
                        case "network": return 0;
                        case "bluetooth": return 1;
                        case "volume": return 2;
                        case "powerprofile": return 3;
                        case "battery": return 4;
                        case "power": return 5;
                        default: return 0;
                    }
                }

                WifiContent { }
                BluetoothContent { }
                VolumeContent { }
                PowerProfileContent { }
                BatteryContent { }
                PowerContent { }
            }
        }
    }
}
