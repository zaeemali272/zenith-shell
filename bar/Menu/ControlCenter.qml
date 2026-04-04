import "../../services"
import "./components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PopupWindow {
    id: menuRoot

    property var parentWindow: null
    
    visible: CenterState.qsVisible
    grabFocus: CenterState.isSticky
    
    anchor.window: parentWindow
    anchor.edges: Edges.Top
    
    // Position below the bar, centered
    anchor.rect: {
        const barHeight = (parentWindow && parentWindow.height > 0) ? parentWindow.height : 45;
        const barWidth = (parentWindow && parentWindow.width > 0) ? parentWindow.width : 1920;
        
        let targetX = (barWidth - implicitWidth) / 2;
        return Qt.rect(Math.max(10, Math.min(barWidth - implicitWidth - 10, targetX)), barHeight + 8, 0, 0);
    }
    
    implicitWidth: 850
    implicitHeight: 550
    color: "transparent"

    HyprlandFocusGrab {
        active: menuRoot.visible && CenterState.isSticky
        windows: [menuRoot, parentWindow]
        onCleared: CenterState.close()
    }

    Rectangle {
        id: mainContent
        anchors.fill: parent
        focus: true
        color: "#010101"
        radius: 10
        border.color: '#181825'
        border.width: 1
        
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                CenterState.close();
            }
        }

        // Background clicks and focus management
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                mouse.accepted = true;
                mainContent.forceActiveFocus();
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            // --- Left Column: Notifications & Media ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 450
                spacing: 15

                NotificationList {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                MprisPlayer {
                    Layout.fillWidth: true
                }

            }

            // --- Right Column: Calendar & Todo ---
            ColumnLayout {
                Layout.preferredWidth: 320
                Layout.fillHeight: true
                spacing: 15

                CalendarWidget {
                    Layout.fillWidth: true
                }

                WeatherWidget {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }

        // Hover tracking (on top of everything but blocks nothing)
        MouseArea {
            id: hoverTracker
            anchors.fill: parent
            anchors.topMargin: -12
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            
            onEntered: CenterState.isHoveringMenu = true
            onExited: CenterState.isHoveringMenu = false
        }
    }
}
