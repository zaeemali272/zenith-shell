// bar/Right/TrayItem.qml
import "../.."
import QtQuick
import Quickshell.Services.SystemTray

MouseArea {
    id: root

    property var item
    property var menuRef

    visible: root.item !== undefined && root.item !== null && root.item.status !== Status.Passive
    implicitWidth: visible ? Theme.iconSize + 2 : 0
    implicitHeight: visible ? Theme.pillHeight : 0
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onPressed: (event) => {
        if (!root.item)
            return ;

        if (event.button === Qt.LeftButton) {
            root.item.activate();
        } else if (event.button === Qt.RightButton && root.item.hasMenu) {
            if (menuRef)
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
            if (status === Image.Error)
                console.warn("Failed to load: " + source);

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
