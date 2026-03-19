import "../../"
// bar/Menu/TrayMenu.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Hyprland

PopupWindow {
    id: root

    property var menuHandle: null
    property var currentItem: null

    visible: false
    color: "transparent"

    // Use implicit dimensions as width/height are deprecated in 0.2.1
    // Add 5px extra height for the top margin
    implicitWidth: menuSurface.implicitWidth
    implicitHeight: menuSurface.implicitHeight + 5

    function openFor(item, visualParent) {
        if (!item || !item.hasMenu)
            return ;

        if (root.visible && currentItem === item) {
            root.visible = false;
            currentItem = null;
            return ;
        }
        
        root.menuHandle = item.menu;
        root.currentItem = item;
        root.anchor.window = visualParent.QsWindow.window;
        root.anchor.rect = visualParent.mapToItem(null, 0, 0, visualParent.width, visualParent.height);
        root.anchor.edges = Edges.Bottom;
        root.anchor.gravity = Edges.Bottom;
        root.visible = true;
    }

    HyprlandFocusGrab {
        active: root.visible
        onCleared: root.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            focusTimer.start();
        }
    }

    Timer {
        id: focusTimer
        interval: 10
        onTriggered: menuSurface.forceActiveFocus()
    }

    // The actual visible box
    Rectangle {
        id: menuSurface

        // Offset it from the top to create a gap between the bar and the menu
        y: 5
        focus: true


        // Consume clicks inside the menu to prevent focus loss
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                mouse.accepted = true;
                menuSurface.forceActiveFocus();
            }
        }

        // Dynamic width based on content, with a minimum of 200
        implicitWidth: Math.max(200, menuContent.implicitWidth + 16)
        implicitHeight: menuContent.implicitHeight + 16
        color: Theme.backgroundColor
        border.color: Theme.borderColor
        border.width: 1
        radius: Theme.pillRadius ? Theme.pillRadius : 8

        QsMenuOpener {
            id: menuOpener
            menu: root.menuHandle
        }

        ColumnLayout {
            id: menuContent

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            spacing: 4

            Repeater {
                model: menuOpener.children
                delegate: Rectangle {
                    id: menuItem
                    
                    Layout.fillWidth: true
                    implicitWidth: itemText.implicitWidth + 40
                    implicitHeight: modelData.isSeparator ? 1 : 32
                    
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
                        id: itemText
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
                            modelData.trigger();
                            root.visible = false;
                        }
                    }
                }
            }
        }
    }
}
