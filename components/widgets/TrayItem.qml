// bar/Right/TrayItem.qml
import "../../.."
import QtQuick
import Quickshell.Services.SystemTray
import "../"
import "../../"

MouseArea {
    id: root

    property var item
    property var menuRef

    visible: root.item !== undefined && root.item !== null && root.item.status !== Status.Passive
    implicitWidth: visible ? Theme.iconSize + 2 : 0
    implicitHeight: visible ? Theme.pillHeight : 0
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
        console.log(`[TrayItem] Clicked! Button: ${mouse.button}, item exists: ${!!root.item}`);
        if (!root.item)
            return ;

        if (mouse.button === Qt.LeftButton) {
            console.log("[TrayItem] Activating item");
            root.item.activate();
        } else if (mouse.button === Qt.RightButton) {
            console.log(`[TrayItem] Right click. hasMenu: ${root.item.hasMenu}, menuRef exists: ${!!menuRef}`);
            if (root.item.hasMenu && menuRef)
                menuRef.openFor(root.item, root);
        }
    }

    Image {
        id: trayIcon

        anchors.centerIn: parent
        width: Theme.iconSize
        height: Theme.iconSize
        fillMode: Image.PreserveAspectFit
        source: {
            if (!root.item || !root.item.icon)
                return "";

            var iconName = String(root.item.icon);
            // FIX: If the app already provided the full image:// URI or a file path
            if (iconName.startsWith("image://") || iconName.startsWith("/") || iconName.startsWith("file://"))
                return iconName;

            // Fallback for raw pixmaps if the ID is missing from the name
            if (root.item.iconPixmap && !iconName)
                return "image://qspixmap/" + root.item.id;

            // Standard lookup for simple names like "discord" or "network-vignette"
            return "image://icon/" + iconName;
        }
        // If it still fails, show a placeholder instead of a checkerboard
        onStatusChanged: {
            if (status === Image.Error) {
                let iconName = String(root.item ? root.item.icon : "");
                if (iconName && !iconName.includes("://") && !iconName.startsWith("/")) {
                    // Try OneUI paths before giving up
                    let oneUIPath = "file:///usr/share/icons/OneUI/24/actions/" + iconName + ".svg";
                    if (source.toString() !== oneUIPath) {
                        source = oneUIPath;
                        return;
                    }
                    let oneUIApp = "file:///usr/share/icons/OneUI/24/apps/" + iconName + ".svg";
                    if (source.toString() !== oneUIApp) {
                        source = oneUIApp;
                        return;
                    }
                }
                console.warn("Failed to load: " + source);
            }

        }
    }

    // Optional: Visual indicator if the icon is missing
    Rectangle {
        anchors.fill: trayIcon
        color: "red"
        opacity: 0.3
        visible: trayIcon.status === Image.Error
    }

}
