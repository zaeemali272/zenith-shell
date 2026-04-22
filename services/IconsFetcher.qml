import QtQuick
import Quickshell

pragma Singleton

Item {
    id: root

    // Centralized icon resolution based on NotificationItem's robust logic
    function getIconPath(appName, desktopEntry, iconName) {
        let candidates = [];
        
        // Raw icon name/path
        if (iconName && iconName !== "") candidates.push(iconName);
        
        // Desktop entry / app name variations
        let cleanName = (desktopEntry || appName || "").toLowerCase().replace(".desktop", "").replace(/\s+/g, '-');
        if (cleanName !== "") {
            candidates.push(cleanName);
            if (!cleanName.endsWith("-bin")) candidates.push(cleanName + "-bin");
        }

        // Standard system icon directories
        let bases = [
            "/usr/share/icons/OneUI/symbolic/status/",
            "/usr/share/icons/hicolor/scalable/apps/",
            "/usr/share/icons/hicolor/128x128/apps/",
            "/usr/share/icons/Adwaita/scalable/apps/",
            "/usr/share/icons/breeze/apps/48/",
            "/usr/share/icons/breeze-dark/apps/48/"
        ];

        let finalCandidates = [];
        
        // 1. Try Quickshell provider first
        for (let name of candidates) {
            if (!name.includes("/")) {
                let path = Quickshell.iconPath(name);
                if (path && path !== "") finalCandidates.push(path);
            } else {
                finalCandidates.push(name);
            }
        }

        // 2. Try manual file paths
        for (let name of candidates) {
            if (name.includes("/")) continue;
            for (let base of bases) {
                finalCandidates.push("file://" + base + name + ".svg");
                finalCandidates.push("file://" + base + name + ".png");
            }
        }
        
        // 3. Fallbacks
        finalCandidates.push(Quickshell.iconPath("application-x-executable"));
        finalCandidates.push(Quickshell.iconPath("dialog-information"));

        // Return first valid path
        for (let path of finalCandidates) {
            if (path && path !== "") return path;
        }
        
        return "image://icon/application-x-executable";
    }
}
