import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import "../../services"

PopupWindow {
    id: root
    
    onVisibleChanged: {
        if (visible) MenuService.register(root)
        else MenuService.unregister(root)
    }

    property var menuHandle: null
    property var currentItem: null
    property var parentMenu: null

    visible: false
    color: "transparent"

    implicitWidth: menuSurface.implicitWidth
    implicitHeight: menuSurface.implicitHeight + Theme.scaled(10)

    grabFocus: false 

    HyprlandFocusGrab {
        id: grab
        active: root.visible && !subMenuLoader.active
        windows: [root, subMenuLoader.item, notificationPopup, osdPopup]
        onCleared: {
            root.visible = false;
            if (parentMenu) parentMenu.visible = false;
        }
    }

    Process {
        id: elementFocusProc
        command: ["sh", "-c", "hyprctl dispatch focuswindow class:^(element|Element|element-desktop)$ || element-desktop &"]
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
        radius: Theme.scaled(20)
        clip: true
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) root.closeAll()
        }

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
                    implicitHeight: modelData.isSeparator ? Theme.scaled(13) : Theme.scaled(36)
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
                            text: modelData.text || ""
                            Layout.fillWidth: true
                            color: itemMouse.containsMouse ? Theme.accentColor : "#ffffff"
                            font.pixelSize: Theme.scaled(12)
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "󰅂"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(14)
                            color: Theme.subtext0
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
                                // Multi-strategy activation for Electron / libappindicator DBusMenu items
                                try { if (typeof modelData.activate === "function") modelData.activate(0, 0); } catch(e1) {}
                                try { if (typeof modelData.activate === "function") modelData.activate(); } catch(e2) {}
                                try { if (typeof modelData.trigger === "function") modelData.trigger(); } catch(e3) {}
                                try { if (typeof modelData.triggered === "function") modelData.triggered(); } catch(e4) {}
                                
                                // Direct Element-Desktop Hyprland window focus + single-instance unhide fallback
                                let itemStr = "";
                                if (root.currentItem) {
                                    itemStr = String(root.currentItem.id || root.currentItem.title || root.currentItem.icon || "").toLowerCase();
                                    try { if (typeof root.currentItem.activate === "function") root.currentItem.activate(0, 0); } catch(e5) {}
                                }
                                let menuText = String(modelData.text || "").toLowerCase();
                                if (itemStr.includes("element") || menuText.includes("show") || menuText.includes("open") || menuText.includes("toggle")) {
                                    elementFocusProc.running = false;
                                    elementFocusProc.running = true;
                                }

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
