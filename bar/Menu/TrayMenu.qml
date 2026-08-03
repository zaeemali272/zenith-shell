import "../.."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
        active: root.visible
        windows: [root, notificationPopup, osdPopup]
        onCleared: root.closeAll()
    }

    readonly property string trayScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/tray_focus.py"

    Process {
        id: windowFocusProc
        property string itemStr: ""
        property string titleStr: ""
        property string iconStr: ""

        command: [
            "python3",
            root.trayScript,
            windowFocusProc.itemStr,
            windowFocusProc.titleStr,
            windowFocusProc.iconStr
        ]
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

        stackView.replace(subMenuComp, { handle: handle, isSubMenu: false });

        root.visible = true;
        menuSurface.forceActiveFocus();
    }

    function closeAll() {
        root.visible = false;
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
            if (event.key === Qt.Key_Escape) {
                if (stackView.depth > 1) stackView.pop();
                else root.closeAll();
            }
        }

        implicitWidth: Math.max(Theme.scaled(220), stackView.implicitWidth)
        implicitHeight: stackView.implicitHeight + Theme.scaled(16)

        StackView {
            id: stackView
            anchors.fill: parent
            anchors.margins: Theme.scaled(8)

            implicitWidth: currentItem ? currentItem.implicitWidth : Theme.scaled(220)
            implicitHeight: currentItem ? currentItem.implicitHeight : Theme.scaled(100)

            pushEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
            pushExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }
            popEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
            popExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }
        }

        Component {
            id: subMenuComp

            ColumnLayout {
                id: menuColumn
                property var handle: null
                property bool isSubMenu: false

                spacing: Theme.scaled(4)
                implicitWidth: Math.max(Theme.scaled(200), menuRepeaterLayout.implicitWidth)
                implicitHeight: menuRepeaterLayout.implicitHeight + (isSubMenu ? backBtn.implicitHeight + Theme.scaled(8) : 0)

                QsMenuOpener {
                    id: menuOpener
                    menu: menuColumn.handle
                }

                Rectangle {
                    id: backBtn
                    visible: menuColumn.isSubMenu
                    Layout.fillWidth: true
                    implicitHeight: Theme.scaled(32)
                    radius: Theme.scaled(10)
                    color: backMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.scaled(10)
                        anchors.rightMargin: Theme.scaled(10)
                        spacing: Theme.scaled(6)

                        Text {
                            text: "󰅁"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(14)
                            color: Theme.accentColor
                        }
                        Text {
                            text: "Back"
                            font.pixelSize: Theme.scaled(11)
                            font.weight: Font.Bold
                            color: Theme.text
                        }
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: stackView.pop()
                    }
                }

                ColumnLayout {
                    id: menuRepeaterLayout
                    Layout.fillWidth: true
                    spacing: Theme.scaled(3)

                    Repeater {
                        model: menuOpener.children

                        delegate: Rectangle {
                            id: itemRect
                            readonly property var entry: modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: entry.isSeparator ? Theme.scaled(11) : Theme.scaled(34)
                            radius: Theme.scaled(10)
                            color: entry.isSeparator ? "transparent" : (itemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - Theme.scaled(10)
                                height: 1
                                color: Theme.glassBorder
                                visible: entry.isSeparator
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.scaled(10)
                                anchors.rightMargin: Theme.scaled(10)
                                visible: !entry.isSeparator
                                spacing: Theme.scaled(8)

                                Image {
                                    id: entryIcon
                                    visible: entry.icon !== ""
                                    source: entry.icon ? (entry.icon.startsWith("/") || entry.icon.startsWith("file://") || entry.icon.startsWith("image://") ? entry.icon : "image://icon/" + entry.icon) : ""
                                    Layout.preferredWidth: Theme.scaled(16)
                                    Layout.preferredHeight: Theme.scaled(16)
                                    fillMode: Image.PreserveAspectFit
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: entry.checkState === Qt.Checked ? "󰄬" : (entry.isCheckable ? "󰄱" : "")
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(11)
                                    color: Theme.accentColor
                                    visible: entry.isCheckable || entry.checkState !== undefined
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: entry.text || ""
                                    Layout.fillWidth: true
                                    color: entry.enabled ? (itemMouse.containsMouse ? Theme.accentColor : Theme.fontColor) : Theme.subtext0
                                    font.pixelSize: Theme.scaled(11)
                                    font.weight: itemMouse.containsMouse ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: "󰅂"
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(12)
                                    color: Theme.subtext0
                                    visible: entry.hasChildren
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: entry.enabled && !entry.isSeparator
                                enabled: entry.enabled && !entry.isSeparator
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (entry.hasChildren) {
                                        stackView.push(subMenuComp, { handle: entry, isSubMenu: true });
                                    } else {
                                        try { entry.triggered(); } catch(e1) {}
                                        try { if (typeof entry.activate === "function") entry.activate(); } catch(e2) {}
                                        try { if (typeof entry.trigger === "function") entry.trigger(); } catch(e3) {}

                                        if (root.currentItem) {
                                            let itemIdStr = String(root.currentItem.id || "");
                                            let itemTitleStr = String(root.currentItem.title || "");
                                            let itemIconStr = String(root.currentItem.icon || "");

                                            windowFocusProc.command = ["python3", root.trayScript, itemIdStr, itemTitleStr, itemIconStr];
                                            windowFocusProc.running = false;
                                            windowFocusProc.running = true;
                                        }

                                        root.closeAll();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}