// bar/Right/TrayItem.qml
import "../.."
import QtQuick
import Quickshell.Io
import Quickshell.Services.SystemTray

MouseArea {
    id: root

    property var item
    property var menuRef

    visible: root.item !== undefined && root.item !== null && root.item.status !== Status.Passive
    implicitWidth: visible ? Theme.iconSize + 2 : 0
    implicitHeight: visible ? Theme.pillHeight : 0
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    Process {
        id: elementFocusProc
        command: ["sh", "-c", "hyprctl dispatch focuswindow class:^(element|Element|element-desktop)$ || element-desktop &"]
    }

    onClicked: (mouse) => {
        if (!root.item)
            return;

        let itemStr = String(root.item.id || root.item.title || root.item.icon || "").toLowerCase();

        if (mouse.button === Qt.LeftButton) {
            try { if (typeof root.item.activate === "function") root.item.activate(0, 0); } catch(e1) {}
            try { if (typeof root.item.activate === "function") root.item.activate(); } catch(e2) {}
            
            if (itemStr.includes("element")) {
                elementFocusProc.running = false;
                elementFocusProc.running = true;
            }
        } else if (mouse.button === Qt.RightButton) {
            if (root.item.hasMenu && menuRef) {
                menuRef.openFor(root.item, root);
            } else {
                try { if (typeof root.item.secondaryActivate === "function") root.item.secondaryActivate(0, 0); } catch(e1) {}
                try { if (typeof root.item.secondaryActivate === "function") root.item.secondaryActivate(); } catch(e2) {}
                try { if (typeof root.item.contextMenu === "function") root.item.contextMenu(0, 0); } catch(e3) {}
                
                if (itemStr.includes("element")) {
                    elementFocusProc.running = false;
                    elementFocusProc.running = true;
                }
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
                if (iconName && !iconName.includes("://") && !iconName.startsWith("/") && !iconName.startsWith("image://")) {
                    let quickshellSource = Quickshell.iconPath(iconName);
                    if (source.toString() !== quickshellSource) {
                        source = quickshellSource;
                        return;
                    }
                }
                if (source.toString() !== Quickshell.iconPath("dialog-information")) {
                    source = Quickshell.iconPath("dialog-information");
                }
            }
        }
    }

    Rectangle {
        anchors.fill: trayIcon
        color: "red"
        opacity: 0.3
        visible: trayIcon.status === Image.Error
    }
}
