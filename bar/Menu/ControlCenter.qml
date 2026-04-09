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
    id: menuRoot

    property var parentWindow: null
    visible: CenterState.qsVisible
    
    // Focus & Grab logic
    grabFocus: false

    property bool _grabActive: false
    Timer {
        id: grabDelay
        interval: 100
        running: menuRoot.visible && CenterState.isSticky
        onTriggered: menuRoot._grabActive = true
    }
    onVisibleChanged: if (!visible) menuRoot._grabActive = false;

    HyprlandFocusGrab {
        active: menuRoot._grabActive
        windows: [menuRoot, parentWindow]
        onActiveChanged: console.log(`[ControlCenter] HyprlandFocusGrab active: ${active}`)
        onCleared: {
            console.log("[ControlCenter] Focus grab cleared (clicked outside)!");
            CenterState.close("focus_cleared");
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
    
    implicitWidth: 850
    implicitHeight: 550
    color: "transparent"

    Rectangle {
        id: mainContent
        anchors.fill: parent
        focus: true
        color: Theme.menuBackground
        radius: Theme.pillRadius
        border.color: Theme.menuBorder
        border.width: 1
        
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                CenterState.close("escape_key");
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                mouse.accepted = true;
                mainContent.forceActiveFocus();
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
