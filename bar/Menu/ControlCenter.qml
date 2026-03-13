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

    // --- FIX 1: The Native Window Hack (From your working WifiMenu) ---
    Component.onCompleted: {
        if (menuRoot.QsWindow && menuRoot.QsWindow.window)
            menuRoot.QsWindow.window.focusable = true;

    }
    visible: CenterState.visible
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

    // --- FIX 2: Correct Window List for Grab ---
    HyprlandFocusGrab {
        active: menuRoot.visible
        // Include the menu's own window so it can actually receive the keys
        windows: menuRoot.QsWindow ? [menuRoot.QsWindow.window, bar.QsWindow.window] : [bar.QsWindow.window]
        onCleared: CenterState.visible = false
    }

    Pane {
        id: mainContent

        anchors.fill: parent
        focus: true

        // --- FIX 3: The "Grab Shield" (From your working WifiMenu) ---
        // Consumes the click so Hyprland doesn't return focus to the terminal
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                mouse.accepted = true;
                mainContent.forceActiveFocus();
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 25

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

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#111111"
                }

                TodoList {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

            }

        }

        background: Rectangle {
            color: "#010101"
            radius: 8
            border.color: '#111111'
            border.width: 1
        }

    }

}
