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
    property var parentMenu: null

    visible: false
    color: "transparent"
    grabFocus: true

    // Use implicit dimensions as width/height are deprecated in 0.2.1
    // Add 5px extra height for the top margin
    implicitWidth: menuSurface.implicitWidth
    implicitHeight: menuSurface.implicitHeight + 5

    function openFor(item, visualParent, edges) {
        if (!item)
            return ;

        // SystemTrayItem has a .menu property, QsMenuEntry is itself a handle
        let handle = item.menu !== undefined ? item.menu : item;
        if (!handle) return;

        if (root.visible && currentItem === item) {
            root.visible = false;
            currentItem = null;
            return ;
        }
        
        root.menuHandle = handle;
        root.currentItem = item;
        // Use the bar as the anchor window if visualParent is inside the bar
        root.anchor.window = bar;
        root.anchor.rect = visualParent.mapToItem(null, 0, 0, visualParent.width, visualParent.height);
        root.anchor.edges = edges || Edges.Bottom;
        root.anchor.gravity = edges || Edges.Bottom;
        root.visible = true;
    }

    HyprlandFocusGrab {
        active: root.visible && !subMenuLoader.active
        windows: {
            let winList = [root, bar];
            if (parentMenu) winList.push(parentMenu);
            return winList;
        }
        onCleared: {
            root.visible = false;
            if (parentMenu) parentMenu.visible = false;
        }
    }

    onVisibleChanged: {
        if (visible) {
            menuSurface.forceActiveFocus();
        } else {
            subMenuLoader.active = false;
        }
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

        // Dynamic width based on content, with a minimum of 160
        implicitWidth: Math.max(160, menuContent.implicitWidth + 16)
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
            anchors.right: parent.right
            anchors.margins: 8
            spacing: 4

            Repeater {
                model: menuOpener.children
                delegate: Rectangle {
                    id: menuItem
                    
                    Layout.fillWidth: true
                    implicitWidth: itemRow.implicitWidth + 16
                    implicitHeight: modelData.isSeparator ? 1 : 32
                    
                    // Change color on hover
                    color: itemMouse.containsMouse || (subMenuLoader.active && subMenuLoader.item.currentItem === modelData) ? Theme.accentColor : "transparent"
                    radius: 4

                    // Separator style
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.borderColor
                        visible: modelData.isSeparator
                    }

                    RowLayout {
                        id: itemRow
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        visible: !modelData.isSeparator
                        spacing: 8

                        // Label
                        Text {
                            id: itemText
                            Layout.fillWidth: true
                            text: modelData.text
                            color: (itemMouse.containsMouse || (subMenuLoader.active && subMenuLoader.item.currentItem === modelData)) ? "white" : Theme.fontColor
                            font.pixelSize: 13
                        }

                        // Submenu indicator
                        Text {
                            text: "󰅂"
                            font.family: Theme.iconFont
                            font.pixelSize: 14
                            color: (itemMouse.containsMouse || (subMenuLoader.active && subMenuLoader.item.currentItem === modelData)) ? "white" : Theme.inactiveTextColor
                            visible: modelData.hasChildren
                        }
                    }

                    MouseArea {
                        id: itemMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (modelData.hasChildren) {
                                openSub();
                            } else {
                                modelData.triggered();
                                closeAll();
                            }
                        }

                        onEntered: {
                            if (modelData.hasChildren) {
                                subMenuTimer.start();
                            } else {
                                subMenuLoader.active = false;
                            }
                        }

                        onExited: {
                            subMenuTimer.stop();
                        }
                    }

                    Timer {
                        id: subMenuTimer
                        interval: 250
                        onTriggered: openSub()
                    }

                    function openSub() {
                        subMenuLoader.active = true;
                        subMenuLoader.item.openFor(modelData, menuItem, Edges.Right);
                    }
                }
            }
        }
    }

    Loader {
        id: subMenuLoader
        active: false
        source: "TrayMenu.qml"
        onLoaded: {
            item.parentMenu = root;
        }
    }

    function closeAll() {
        root.visible = false;
        if (parentMenu) parentMenu.closeAll();
    }
}
