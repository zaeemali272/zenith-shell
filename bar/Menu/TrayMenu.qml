import "../../"
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
    implicitHeight: menuSurface.implicitHeight + 10

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
        y: 8 
        color: "#11111b"
        border.color: "#313244"
        border.width: 1
        radius: 12
        focus: true
        
        // --- WIDTH FIX ---
        // Increased min-width to 220 for better readability
        implicitWidth: Math.max(220, menuContent.implicitWidth + 30)
        implicitHeight: menuContent.implicitHeight + 20

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
            anchors.margins: 12
            spacing: 6

            Repeater {
                model: menuOpener.children
                delegate: Rectangle {
                    id: menuItem
                    Layout.fillWidth: true
                    // Slightly taller items for a premium touch
                    implicitHeight: modelData.isSeparator ? 13 : 38
                    radius: 8
                    
                    color: (itemMouse.containsMouse || (subMenuLoader.active && subMenuLoader.item.currentItem === modelData)) ? "#313244" : "transparent"

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 10; height: 1
                        color: "#313244"
                        visible: modelData.isSeparator
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        visible: !modelData.isSeparator
                        spacing: 12

                        Text {
                            text: modelData.text
                            Layout.fillWidth: true
                            color: itemMouse.containsMouse ? "#89b4fa" : "#a6adc8"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            // Prevent text from looking cramped
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "󰅂"
                            font.family: Theme.iconFont
                            font.pixelSize: 14
                            color: "#585b70"
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