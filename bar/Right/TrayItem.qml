// bar/Right/TrayItem.qml
//
// Design note: this deliberately does NOT try to move windows between
// Hyprland workspaces to fake show/hide. That fights Electron/Chromium's
// own window lifecycle and is unreliable across apps. Instead it always
// calls the StatusNotifierItem's Activate()/SecondaryActivate() methods,
// which is the actual protocol signal apps use to know "become visible /
// toggle visibility now". Well-behaved tray apps (including most Electron
// apps, when the app itself implements tray support properly) handle this
// correctly on their own. Apps that don't (e.g. plain Discord on Linux)
// need to be fixed at the app level (see the settings note below), not
// papered over here.

import "../.."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray

MouseArea {
    id: root

    property var item
    property var menuRef

    visible: root.item !== undefined && root.item !== null
    implicitWidth: visible ? Theme.iconSize + Theme.scaled(8) : 0
    implicitHeight: visible ? Theme.pillHeight : 0
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    scale: root.pressed ? 0.90 : (root.containsMouse ? 1.15 : 1.0)
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Theme.elasticEasing } }

    onClicked: (mouse) => {
        if (!root.item) return;

        if (mouse.button === Qt.LeftButton) {
            let pos = root.mapToItem(null, mouse.x, mouse.y);
            let globalX = Math.round(pos.x);
            let globalY = Math.round(pos.y);

            try {
                if (typeof root.item.activate === "function") {
                    root.item.activate(globalX, globalY);
                } else if (typeof root.item.secondaryActivate === "function") {
                    root.item.secondaryActivate(globalX, globalY);
                }
            } catch (e) {
                console.warn("Tray activate error:", e);
            }

            // Window focus / toggle fallback for Hyprland app windows
            let appId = String(root.item.id || root.item.title || "").toLowerCase().trim();
            if (appId !== "") {
                let targetWin = null;
                let workspaces = Hyprland.workspaces.values;
                for (let i = 0; i < workspaces.length; i++) {
                    let ws = workspaces[i];
                    if (!ws || !ws.toplevels) continue;
                    let toplevels = ws.toplevels.values;
                    for (let j = 0; j < toplevels.length; j++) {
                        let win = toplevels[j];
                        if (!win) continue;
                        let winClass = String(win.initialClass || win.waylandAppId || "").toLowerCase();
                        if (winClass !== "" && (winClass.includes(appId) || appId.includes(winClass))) {
                            targetWin = win;
                            break;
                        }
                    }
                    if (targetWin) break;
                }

                if (targetWin) {
                    if (Hyprland.activeWindow === targetWin) {
                        Hyprland.dispatch("workspace previous");
                    } else {
                        if (typeof targetWin.activate === "function") {
                            targetWin.activate();
                        } else {
                            Hyprland.dispatch("focuswindow address:" + targetWin.address);
                        }
                    }
                }
            }
        } else if (mouse.button === Qt.RightButton) {
            if (root.item.hasMenu && menuRef) {
                menuRef.openFor(root.item, root);
            } else {
                try {
                    if (typeof root.item.contextMenu === "function") {
                        root.item.contextMenu(0, 0);
                    } else if (typeof root.item.secondaryActivate === "function") {
                        root.item.secondaryActivate();
                    }
                } catch (e) {
                    console.warn("Tray contextMenu error:", e);
                }
            }
        } else if (mouse.button === Qt.MiddleButton) {
            try {
                if (typeof root.item.secondaryActivate === "function") {
                    root.item.secondaryActivate();
                }
            } catch (e) {
                console.warn("Tray secondaryActivate error:", e);
            }
        }
    }

    // Icon Container
    Item {
        anchors.centerIn: parent
        width: Theme.iconSize
        height: Theme.iconSize

        Image {
            id: trayIcon

            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true

            source: {
                if (!root.item) return "";

                var icon = root.item.icon;
                var iconName = "";

                if (icon !== null && icon !== undefined) {
                    iconName = String(icon);
                    if (iconName.startsWith("image://") || iconName.startsWith("/") || iconName.startsWith("file://"))
                        return iconName;
                }

                if (root.item.iconPixmap && !iconName) {
                    return "image://qspixmap/" + root.item.id;
                }

                if (iconName) {
                    return "image://icon/" + iconName;
                }

                return "";
            }

            onStatusChanged: {
                if (status === Image.Error) {
                    let iconName = String(root.item && root.item.icon ? root.item.icon : "");
                    if (iconName && !iconName.includes("://") && !iconName.startsWith("/")) {
                        let quickshellSource = Quickshell.iconPath(iconName);
                        if (quickshellSource && source.toString() !== quickshellSource) {
                            source = quickshellSource;
                            return;
                        }
                    }
                    let genericApp = Quickshell.iconPath("application-x-executable");
                    if (genericApp && source.toString() !== genericApp) {
                        source = genericApp;
                    }
                }
            }
        }

        // Fallback text glyph if image fails completely
        Text {
            anchors.centerIn: parent
            text: "󰏤"
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
            color: Theme.accentColor
            visible: trayIcon.status === Image.Error && trayIcon.source.toString() === ""
        }
    }

    // Attention indicator dot (NeedsAttention status)
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: Theme.scaled(3)
        anchors.right: parent.right
        anchors.rightMargin: Theme.scaled(2)
        width: Theme.scaled(6)
        height: Theme.scaled(6)
        radius: width / 2
        color: Theme.red
        border.color: Theme.surface0
        border.width: 1
        visible: root.item !== undefined && root.item !== null && (root.item.status === Status.NeedsAttention || root.item.status === 2)

        SequentialAnimation on opacity {
            running: parent.visible
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.3; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        }
    }

    property bool tooltipShow: false

    Timer {
        id: tooltipTimer
        interval: 400
        repeat: false
        running: false
        onTriggered: root.tooltipShow = true
    }

    onContainsMouseChanged: {
        if (containsMouse) {
            tooltipTimer.restart();
        } else {
            tooltipTimer.stop();
            tooltipShow = false;
        }
    }

    // Tooltip. A PopupWindow is a real Wayland surface; one per tray icon
    // sitting around unmapped is waste, so it only exists while hovered.
    Loader {
        active: root.tooltipShow && root.containsMouse && root.item
        sourceComponent: PopupWindow {
            anchor.window: root.QsWindow.window
            anchor.rect: root.mapToItem(null, 0, 0, root.width, root.height)
            anchor.edges: Edges.Bottom
            anchor.gravity: Edges.Bottom

            visible: tooltipText.text !== ""
            color: "transparent"

            implicitWidth: tooltipRect.implicitWidth
            implicitHeight: tooltipRect.implicitHeight + Theme.scaled(10)

            Rectangle {
                id: tooltipRect
                y: Theme.scaled(6)
                color: Theme.glassBackground
                border.color: Theme.glassBorder
                border.width: 1
                radius: Theme.scaled(8)

                implicitWidth: tooltipText.implicitWidth + Theme.scaled(16)
                implicitHeight: tooltipText.implicitHeight + Theme.scaled(10)

                Text {
                    id: tooltipText
                    anchors.centerIn: parent
                    text: {
                        if (!root.item) return "";
                        var title = String(root.item.title || "").trim();
                        var tooltip = String(root.item.tooltip || "").trim();
                        return title || tooltip || String(root.item.id || "").trim();
                    }
                    color: Theme.text
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.Medium
                }
            }
        }
    }
}
