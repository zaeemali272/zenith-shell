// bar/Right/TrayItem.qml
import "../.."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

MouseArea {
    id: root

    property var item
    property var menuRef

    visible: root.item !== undefined && root.item !== null
    implicitWidth: visible ? Theme.iconSize + Theme.scaled(4) : 0
    implicitHeight: visible ? Theme.pillHeight : 0
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true

    scale: root.pressed ? 0.88 : (root.containsMouse ? 1.2 : 1.0)
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Theme.elasticEasing } }

    readonly property string trayScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/tray_focus.py"

    Process {
        id: focusProc
        property string itemStr: ""
        property string titleStr: ""
        property string iconStr: ""

        command: [
            "python3",
            root.trayScript,
            focusProc.itemStr,
            focusProc.titleStr,
            focusProc.iconStr
        ]
    }

    onClicked: (mouse) => {
        if (!root.item) return;

        let itemIdStr = String(root.item.id || "");
        let itemTitleStr = String(root.item.title || "");
        let itemIconStr = String(root.item.icon || "");

        if (mouse.button === Qt.LeftButton) {
            // Pass (0, 0) arguments as required by Qt C++ StatusNotifierItem::activate(int x, int y)
            try {
                if (typeof root.item.activate === "function") {
                    root.item.activate(0, 0);
                }
            } catch(e1) {}

            focusProc.command = ["python3", root.trayScript, itemIdStr, itemTitleStr, itemIconStr];
            focusProc.running = false;
            focusProc.running = true;
        } else if (mouse.button === Qt.RightButton) {
            if (root.item.hasMenu && menuRef) {
                menuRef.openFor(root.item, root);
            } else {
                try { if (typeof root.item.secondaryActivate === "function") root.item.secondaryActivate(0, 0); } catch(e1) {}
                try { if (typeof root.item.contextMenu === "function") root.item.contextMenu(0, 0); } catch(e2) {}
            }
        }
    }

    Image {
        id: trayIcon

        anchors.centerIn: parent
        width: Theme.iconSize
        height: Theme.iconSize
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
                    if (source.toString() !== quickshellSource && quickshellSource !== "") {
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

    Text {
        anchors.centerIn: parent
        text: "󰏤"
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        color: Theme.accentColor
        visible: trayIcon.status === Image.Error && trayIcon.source.toString() === ""
    }
}