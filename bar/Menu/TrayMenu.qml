import "../.."
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

    // Increased implicit width for a more "desktop" feel
    implicitWidth: menuSurface.implicitWidth
    implicitHeight: menuSurface.implicitHeight + Theme.scaled(10)

    grabFocus: true 

    HyprlandFocusGrab {
        id: grab
        active: root.visible && !subMenuLoader.active
        windows: [root, subMenuLoader.item]
        onCleared: {
            root.visible = false;
            if (parentMenu) parentMenu.visible = false;
        }
    }

    function openFor(item, visualParent, edges) {
        if (!item) return;
        let handle = item.menu !== undefined ? item.menu : item;
        if (!handle) return;

        if (root.visible && currentItem === item) {
            root.visible = false;
            return;
        }

        root.menuHandle = handle;
        root.currentItem = item;
        root.anchor.window = visualParent.QsWindow.window;
        root.anchor.rect = visualParent.mapToItem(null, 0, 0, visualParent.width, visualParent.height);
        root.anchor.edges = edges || Edges.Bottom;
        root.anchor.gravity = edges || Edges.Bottom;

        root.visible = true;
        menuSurface.forceActiveFocus();
    }

    Rectangle {
        id: menuSurface
        y: Theme.scaled(8)
        color: Theme.glassBackground
        border.color: Theme.glassBorder
        border.width: 1
        radius: Theme.scaled(12)
        focus: true

        // --- WIDTH FIX ---
        // Increased min-width to 220 for better readability
        implicitWidth: Math.max(Theme.scaled(220), menuContent.implicitWidth + Theme.scaled(30))
        implicitHeight: menuContent.implicitHeight + Theme.scaled(20)

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                mouse.accepted = true;
                menuSurface.forceActiveFocus();
            }
        }

        QsMenuOpener { id: menuOpener; menu: root.menuHandle }

        ColumnLayout {
            id: menuContent
            anchors.fill: parent
            anchors.margins: Theme.scaled(12)
            spacing: Theme.scaled(6)

            Repeater {
                model: menuOpener.children
                delegate: Rectangle {
                    id: menuItem
                    Layout.fillWidth: true
                    // Slightly taller items for a premium touch
                    implicitHeight: modelData.isSeparator ? Theme.scaled(13) : Theme.scaled(38)
                    radius: Theme.scaled(8)

                    color: (modelData.isSeparator) ? "transparent" : ((itemMouse.containsMouse || (subMenuLoader.active && subMenuLoader.item.currentItem === modelData)) ? Theme.surface1 : "transparent")

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - Theme.scaled(10); height: 1
                        color: Theme.menuBorder
                        visible: modelData.isSeparator
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.scaled(12)
                        anchors.rightMargin: Theme.scaled(12)
                        visible: !modelData.isSeparator
                        spacing: Theme.scaled(12)

                        Text {
                            text: modelData.text
                            Layout.fillWidth: true
                            color: itemMouse.containsMouse ? Theme.blue : Theme.subtext1
                            font.pixelSize: Theme.scaled(12)
                            font.weight: Font.Medium
                            // Prevent text from looking cramped
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "󰅂"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(14)
                            color: Theme.overlay1
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
                                root.closeAll();
                            }
                        }
                        onEntered: {
                            if (modelData.hasChildren) subMenuTimer.start();
                            else subMenuLoader.active = false;
                        }
                        onExited: subMenuTimer.stop()
                    }

                    Timer { id: subMenuTimer; interval: 200; onTriggered: openSub() }

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