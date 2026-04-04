import "../../services/"
import "./components/"
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PopupWindow {
    id: menuRoot

    property var anchorItem: null
    
    visible: CenterState.visible
    grabFocus: true
    
    anchor.window: bar
    anchor.edges: Edges.Top
    anchor.rect.y: bar.height + 8
    anchor.rect.x: {
        let barCenter = bar.width / 2;
        let targetX = barCenter - (implicitWidth / 2);
        return Math.max(10, Math.min(bar.width - implicitWidth - 10, targetX));
    }
    
    implicitWidth: 850
    implicitHeight: 550
    color: "transparent"

    HyprlandFocusGrab {
        active: menuRoot.visible
        windows: [menuRoot, bar]
        onCleared: CenterState.visible = false
    }

    Pane {
        id: mainContent

        anchors.fill: parent
        focus: true
        
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                CenterState.visible = false;
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
                // Rectangle {
                //     Layout.fillWidth: true
                //     height: 1
                //     color: "#111111"
                // }

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

        background: Rectangle {
            color: "#010101"
            radius: 10
            border.color: '#181825'
            border.width: 1
        }

    }

}
