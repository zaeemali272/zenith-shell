import "../../services"
import "../../Settings"
import "../widgets"
import "../widgets/popups"
import "../widgets/popups" 
import "../../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../../"
import Quickshell.Hyprland
import "../"
import "../../"
import Quickshell.Wayland
import "../"
import "../../"

PopupWindow {
    id: menuRoot

    property var parentWindow: null
    visible: false
    
    grabFocus: true

    HyprlandFocusGrab {
        active: menuRoot.visible
        windows: [menuRoot]
        onCleared: menuRoot.visible = false
    }
    
    onVisibleChanged: {
        if (visible) {
            CenterState.qsVisible = true;
            mainContent.forceActiveFocus();
        } else {
            CenterState.qsVisible = false;
        }
    }

    anchor.window: parentWindow
    anchor.edges: Edges.Top
    
    anchor.rect: {
        const barHeight = (parentWindow && parentWindow.height > 0) ? parentWindow.height : 45;
        const barWidth = (parentWindow && parentWindow.width > 0) ? parentWindow.width : 1920;
        let targetX = (barWidth - implicitWidth) / 2;
        return Qt.rect(Math.max(10, Math.min(barWidth - implicitWidth - 10, targetX)), barHeight + 8, 0, 0);
    }
    
    implicitWidth: Theme.scaled(850)
    implicitHeight: Theme.scaled(550)
    color: "transparent"

    Rectangle {
        id: mainContent
        anchors.fill: parent
        focus: true
        color: Theme.menuBackground
        radius: Theme.pillRadius
        border.color: hoverTracker.containsMouse ? Theme.menuHoverBorder : Theme.menuBorder
        border.width: 1
        
        // Background area focus catch
        MouseArea {
            id: hoverTracker
            anchors.fill: parent
            anchors.topMargin: -12
            hoverEnabled: true
            onEntered: CenterState.isHoveringMenu = true
            onExited: CenterState.isHoveringMenu = false
            onPressed: (mouse) => {
                mouse.accepted = false; // Propagate click
                mainContent.forceActiveFocus();
            }
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                CenterState.close("escape_key");
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.menuPadding
            spacing: Theme.menuSpacing

            // --- Left Column: Notifications & Media ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 450
                spacing: Theme.menuSpacing

                NotificationList {
                    visible: GeneralSettings.enableNotifications
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                MprisPlayer {
                    visible: GeneralSettings.enableMedia
                    Layout.fillWidth: true
                }
            }

            // --- Right Column: Calendar & Todo ---
            ColumnLayout {
                Layout.preferredWidth: 320
                Layout.fillHeight: true
                spacing: Theme.menuSpacing

                CalendarWidget {
                    Layout.fillWidth: true
                }

                WeatherWidget {
                    visible: GeneralSettings.enableWeather
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
