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
        asynchronous: true
        smooth: true
        
        // --- MODIFIED ICON RESOLUTION ---
        source: {
            if (!root.item) return ""; // Ensure item exists

            var icon = root.item.icon;
            var iconName = "";

            // Safely get the icon name and check for standard URI/path formats
            if (icon !== null && icon !== undefined) {
                iconName = String(icon);
                // If the app already provided the full image:// URI or a file path
                if (iconName.startsWith("image://") || iconName.startsWith("/") || iconName.startsWith("file://"))
                    return iconName;
            }

            // Fallback for raw pixmaps if the icon name was not provided or not a valid URI/path
            // This is used if iconName is still empty after the above checks, or if iconPixmap exists.
            if (root.item.iconPixmap && !iconName) { // iconName will be "" if root.item.icon was null/undefined
                return "image://qspixmap/" + root.item.id;
            }

            // Standard lookup for simple names like "discord" or "network-vignette"
            // This is used if iconName was derived but not a URI/path, or if iconPixmap was not available.
            if (iconName) { // If iconName has a value from root.item.icon, try the standard lookup.
                return "image://icon/" + iconName;
            }

            // If all else fails, return an empty string to avoid rendering issues
            return "";
        }
        
        // If it still fails to load, try to resolve with Quickshell's helper
        onStatusChanged: {
            if (status === Image.Error) {
                // Attempt to use Quickshell's iconPath for a more reliable lookup
                let iconName = String(root.item && root.item.icon ? root.item.icon : "");
                if (iconName && !iconName.includes("://") && !iconName.startsWith("/") && !iconName.startsWith("image://")) {
                    // Only try Quickshell if it's a simple name and not already a path/URI
                    let quickshellSource = Quickshell.iconPath(iconName);
                    if (source.toString() !== quickshellSource) {
                        source = quickshellSource;
                        return;
                    }
                }
                // If Quickshell also fails or no iconName, use a generic fallback
                if (source.toString() !== Quickshell.iconPath("dialog-information")) {
                    source = Quickshell.iconPath("dialog-information");
                }
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
