import "../../"
// bar/Menu/CustomMenu.qml
import QtQuick
import Quickshell
import "../"
import "../../"
import Quickshell.Services.SystemTray
import "../"
import "../../"

PopupWindow {
    id: root

    // Use 'var' instead of QsMenuHandle to avoid the 'undefined' crash at startup
    property var menuHandle: null

    // PopupWindow in 0.2.1 uses color for the window surface
    color: "transparent"

    // The actual visible box
    Rectangle {
        id: menuSurface

        // We use childrenRect to make the box fit the content automatically
        width: 220
        height: menuContent.height + 16
        color: Theme.backgroundColor
        border.color: Theme.borderColor
        border.width: 1
        radius: Theme.pillRadius ? Theme.pillRadius : 8

        QsMenuOpener {
            id: menuOpener

            menu: root.menuHandle
        }

        Column {
            id: menuContent

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            spacing: 4

            Repeater {
                model: menuOpener.children

                Rectangle {
                    id: menuItem

                    width: parent.width
                    height: modelData.isSeparator ? 1 : 32
                    // Change color on hover
                    color: itemMouse.containsMouse ? Theme.accentColor : "transparent"
                    radius: 4

                    // Separator style
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.borderColor
                        visible: modelData.isSeparator
                    }

                    // Label
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: modelData.text
                        color: itemMouse.containsMouse ? "white" : Theme.fontColor
                        font.pixelSize: 13
                        visible: !modelData.isSeparator
                    }

                    MouseArea {
                        id: itemMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            modelData.triggered();
                            root.close();
                        }
                    }

                }

            }

        }

    }

}
