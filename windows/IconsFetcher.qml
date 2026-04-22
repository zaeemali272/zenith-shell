pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: iconsFetcher

    function getIconPath(appName, desktopEntry, iconName) {
        let candidates = [];
        
        if (iconName && iconName !== "") candidates.push(iconName);
        
        if (desktopEntry && desktopEntry !== "") {
            let clean = desktopEntry.replace(".desktop", "");
            candidates.push(clean);
            candidates.push(clean.toLowerCase());
            if (clean.includes(".")) {
                let parts = clean.split(".");
                candidates.push(parts[parts.length - 1]);
            }
        }
        
        if (appName && appName !== "") {
            candidates.push(appName);
            candidates.push(appName.toLowerCase());
            let lower = appName.toLowerCase();
            if (lower.endsWith("-bin")) {
                candidates.push(lower.replace("-bin", ""));
            } else {
                candidates.push(lower + "-bin");
            }
        }

        for (let name of candidates) {
            if (!name || name.includes("/")) continue;
            let path = Quickshell.iconPath(name);
            if (path && path !== "") return "image://icon/" + name;
        }
        
        if (candidates.length > 0) {
            for (let name of candidates) {
                if (name && !name.includes("/")) return "image://icon/" + name;
            }
        }

        return "image://icon/application-x-executable";
    }
}
