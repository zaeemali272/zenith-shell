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

    property var menuHandle: null

    property var currentItem: null
    property var parentMenu: null

    visible: false
    color: "transparent"
    grabFocus: false

    implicitWidth: menuSurface.implicitWidth
    implicitHeight: menuSurface.implicitHeight + Theme.scaled(10)

    HyprlandFocusGrab {
        id: grab
        active: root.visible
        windows: [root]
        onCleared: root.closeAll()
    }

    Connections {
        target: MenuService
        function onCloseRequested() {
            root.closeAll();
        }
    }

    Shortcut {
        sequences: ["Escape"]
        enabled: root.visible
        onActivated: {
            if (stackView.depth > 1) stackView.pop();
            else root.closeAll();
        }
    }

    function openFor(item, visualParent, edges) {
        if (!item) return;
        let handle = item.menu !== undefined ? item.menu : item;
        if (!handle) return;

        if (root.visible && currentItem === item) {
            root.closeAll();
            return;
        }

        root.menuHandle = handle;
        root.currentItem = item;
        root.anchor.window = visualParent.QsWindow.window;
        root.anchor.rect = visualParent.mapToItem(null, 0, 0, visualParent.width, visualParent.height);
        root.anchor.edges = edges || Edges.Bottom;
        root.anchor.gravity = edges || Edges.Bottom;

        stackView.replace(subMenuComp, { handle: handle, isSubMenu: false });

        exitAnim.stop();
        root.visible = true;
        menuSurface.forceActiveFocus();
        enterAnim.restart();
    }

    function closeAll() {
        if (!root.visible) return;
        enterAnim.stop();
        exitAnim.restart();
    }

    ParallelAnimation {
        id: enterAnim
        onStarted: menuSurface.forceActiveFocus()
        NumberAnimation {
            target: menuSurface
            property: "opacity"
            from: 0
            to: 1
            duration: 140
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: menuSurface
            property: "scale"
            from: 0.95
            to: 1.0
            duration: 180
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: menuSurface
            property: "y"
            from: -Theme.scaled(4)
            to: Theme.scaled(8)
            duration: 160
            easing.type: Easing.OutCubic
        }
        onFinished: {
            menuSurface.forceActiveFocus();
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation {
            target: menuSurface
            property: "opacity"
            to: 0
            duration: 90
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: menuSurface
            property: "scale"
            to: 0.96
            duration: 90
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: menuSurface
            property: "y"
            to: -Theme.scaled(2)
            duration: 90
            easing.type: Easing.InQuad
        }
        onFinished: {
            root.visible = false;
            root.currentItem = null;
        }
    }

    Rectangle {
        id: menuSurface
        y: Theme.scaled(8)
        color: Theme.glassBackground
        border.color: Theme.glassBorder
        border.width: 1
        radius: Theme.scaled(14)
        antialiasing: true
        focus: true
        transformOrigin: Item.TopRight

        Keys.onEscapePressed: {
            if (stackView.depth > 1) stackView.pop();
            else root.closeAll();
        }

        implicitWidth: Math.max(Theme.scaled(220), stackView.implicitWidth)
        implicitHeight: stackView.implicitHeight + Theme.scaled(16)

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutCubic
            }
        }

        StackView {
            id: stackView
            anchors.fill: parent
            anchors.margins: Theme.scaled(8)

            implicitWidth: currentItem ? currentItem.implicitWidth : Theme.scaled(220)
            implicitHeight: currentItem ? currentItem.implicitHeight : Theme.scaled(100)

            pushEnter: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animFast; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "x"; from: 18; to: 0; duration: Theme.animFast; easing.type: Easing.OutCubic }
                }
            }
            pushExit: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animInstant; easing.type: Easing.InCubic }
                    NumberAnimation { property: "x"; from: 0; to: -18; duration: Theme.animInstant; easing.type: Easing.InCubic }
                }
            }
            popEnter: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animFast; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "x"; from: -18; to: 0; duration: Theme.animFast; easing.type: Easing.OutCubic }
                }
            }
            popExit: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animInstant; easing.type: Easing.InCubic }
                    NumberAnimation { property: "x"; from: 0; to: 18; duration: Theme.animInstant; easing.type: Easing.InCubic }
                }
            }
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
                    color: backMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                    border.width: 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.scaled(10)
                        anchors.rightMargin: Theme.scaled(10)
                        spacing: Theme.scaled(6)

                        Text {
                            text: "󰅁"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(18)
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
                            color: entry.isSeparator ? "transparent" : (itemMouse.containsMouse ? Theme.menuDarkHover : "transparent")
                            border.width: 0
                            scale: itemMouse.pressed ? 0.97 : 1.0

                            Behavior on color { ColorAnimation { duration: Theme.animInstant } }
                            Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

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
                                    visible: entry.icon !== "" && entry.icon !== undefined && entry.icon !== null
                                    source: {
                                        if (!entry.icon) return "";
                                        var iconStr = String(entry.icon);
                                        if (iconStr.startsWith("/") || iconStr.startsWith("file://") || iconStr.startsWith("image://"))
                                            return iconStr;
                                        return "image://icon/" + iconStr;
                                    }
                                    Layout.preferredWidth: Theme.scaled(16)
                                    Layout.preferredHeight: Theme.scaled(16)
                                    fillMode: Image.PreserveAspectFit
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: (entry.checkState === Qt.Checked || entry.checked) ? "󰄬" : (entry.isCheckable ? "󰄱" : "")
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(11)
                                    color: Theme.accentColor
                                    visible: entry.isCheckable || entry.checkState !== undefined || entry.checked !== undefined
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: String(entry.text || "").replace(/&/g, "")
                                    Layout.fillWidth: true
                                    color: entry.enabled ? (itemMouse.containsMouse ? Theme.accentColor : Theme.text) : Theme.subtext0
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
                                        try {
                                            if (typeof entry.triggered === "function") {
                                                entry.triggered();
                                            } else if (typeof entry.activate === "function") {
                                                entry.activate();
                                            } else if (typeof entry.trigger === "function") {
                                                entry.trigger();
                                            }
                                        } catch(e1) {}
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
