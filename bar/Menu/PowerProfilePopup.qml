import "../.."
import "../../services"
import "./components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: menuRoot

    property var anchorItem: null

    visible: false
    color: "transparent"
    implicitWidth: 220
    implicitHeight: content.implicitHeight + 40
    anchor.window: (anchorItem && anchorItem.QsWindow) ? anchorItem.QsWindow.window : null
    anchor.rect: anchorItem ? anchorItem.mapToItem(null, 0, 0, anchorItem.width, anchorItem.height) : Qt.rect(0, 0, 0, 0)
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    HyprlandFocusGrab {
        active: menuRoot.visible
        onCleared: menuRoot.visible = false
    }

    Rectangle {
        id: mainContent

        anchors.fill: parent
        anchors.margins: 5
        radius: 12
        color: Theme.backgroundColor || "#111111"
        border.color: hoverTracker.containsMouse ? Theme.menuHoverBorder : Theme.menuBorder
        border.width: 1
        clip: true
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape)
                menuRoot.visible = false;

        }

        // Timer to force focus when opened
        Timer {
            interval: 10
            running: menuRoot.visible
            onTriggered: mainContent.forceActiveFocus()
        }

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 15
            spacing: 12

            Text {
                text: "Power Profiles"
                font.pixelSize: 16
                font.bold: true
                color: Theme.fontColor
            }

            Repeater {
                model: ["performance", "balanced", "powersave", "turbo"]

                delegate: Rectangle {
                    height: 38
                    radius: 8
                    // Darker on hover: #0a0a0a instead of #1a1a1a
                    color: PowerProfileService.currentProfile === modelData ? Theme.accentColor : (delegateMouse.containsMouse ? "#0a0a0a" : "#1a1a1a")
                    Layout.fillWidth: true
                    
                    Behavior on color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            text: {
                                switch (modelData) {
                                case "performance":
                                    return "󰀦";
                                case "powersave":
                                    return "󰍛";
                                case "balanced":
                                    return "󰏤";
                                case "turbo":
                                    return "󰞃";
                                default:
                                    return "󰀄";
                                }
                            }
                            font.family: Theme.iconFont
                            font.pixelSize: 14
                            color: PowerProfileService.currentProfile === modelData ? "black" : (delegateMouse.containsMouse ? "white" : "#cdd6f4")
                        }

                        Text {
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            font.pixelSize: 12
                            font.bold: PowerProfileService.currentProfile === modelData
                            color: PowerProfileService.currentProfile === modelData ? "black" : (delegateMouse.containsMouse ? "white" : "#cdd6f4")
                        }

                    }

                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            PowerProfileService.setProfile(modelData);
                            menuRoot.visible = false;
                        }
                    }

                }

            }

        }
        
        // Hover tracking and click handling
        MouseArea {
            id: hoverTracker
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onPressed: (mouse) => {
                mouse.accepted = true;
                mainContent.forceActiveFocus();
            }
        }
    }
}
