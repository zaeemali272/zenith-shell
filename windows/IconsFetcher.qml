pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: iconsFetcher

    function getValidIcon(appName, desktopEntry, iconName) {
        let raw = (iconName || "").trim();
        let desktop = (desktopEntry || "").replace(".desktop", "").trim();
        let app = (appName || "").trim();

        let searchStr = (desktop + " " + app + " " + raw).toLowerCase();
        let id = (app + " " + desktop).toLowerCase();

        let candidates = [];

        // 1. Precise Target Mappings using the actual names found on your drive
        if (id.includes("freedownloadmanager") || searchStr.includes("freedownloadmanager") || id.includes("fdm")) {
            candidates.push("freedownloadmanager-bin", "freedownloadmanager", "freedownloadmanager_fdm_up", "fdm");
        } else if (id.includes("zed") || searchStr.includes("zed")) {
            candidates.push("zed", "dev.zed.Zed", "zed-editor");
        } else if (id.includes("thunar") || searchStr.includes("thunar")) {
            candidates.push("org.xfce.thunar", "thunar");
        } else if (id.includes("code") || searchStr.includes("vscode") || searchStr.includes("visual studio code")) {
            candidates.push("com.visualstudio.code", "vscode", "code");
        } else if (id.includes("zen") && !id.includes("zenity")) {
            candidates.push("zen-browser", "zen");
        } else if (id.includes("kitty")) {
            candidates.push("kitty");
        } else if (id.includes("terminal") || id.includes("foot") || id.includes("alacritty")) {
            candidates.push("utilities-terminal", "terminal");
        } else if (searchStr.includes("discord")) {
            candidates.push("com.discordapp.Discord", "discord");
        } else if (searchStr.includes("spotify")) {
            candidates.push("com.spotify.Client", "spotify");
        }

        if (raw !== "") {
            candidates.push(raw);
            if (raw.includes("/")) {
                let parts = raw.split("/");
                candidates.push(parts[parts.length - 1]);
            }
        }
        if (desktop !== "") candidates.push(desktop);

        if (desktop.includes(".")) {
            let parts = desktop.split(".");
            candidates.push(parts[parts.length - 1]);
        }

        let cleanCandidates = [];
        for (let entry of candidates) {
            let base = entry.replace(/\.(png|svg|xpm|jpg)$/i, "");
            cleanCandidates.push(base);
        }

        let uniqueCandidates = cleanCandidates.filter((v, i, a) => v && v !== "" && a.indexOf(v) === i);

        // 2. Native Quickshell Theme Provider Match Loop
        for (let name of uniqueCandidates) {
            let path = Quickshell.iconPath(name, false); 
            if (path && path !== "") {
                if (path.startsWith("/")) return "file://" + path;
                return "image://icon/" + name;
            }
        }

        if (raw.startsWith("/")) {
            if (Quickshell.iconPath(raw, true) !== "") return "file://" + raw;
        }

        // 3. System Directory Hard Fallbacks with absolute home folder paths
        let iconBases = [
            "/usr/share/icons/hicolor/scalable/apps/",
            "/usr/share/icons/hicolor/512x512/apps/", // Targets Zed
            "/usr/share/icons/hicolor/256x256/apps/", // Targets FDM
            "/usr/share/icons/hicolor/48x48/apps/",
            "/usr/share/pixmaps/",
            "/usr/share/icons/Papirus/48x48/apps/",
            "/usr/share/icons/Papirus-Dark/48x48/apps/",
            "/home/zaeem/.local/share/icons/hicolor/scalable/apps/",
            "/home/zaeem/.local/share/icons/hicolor/512x512/apps/",
            "/home/zaeem/.local/share/icons/hicolor/256x256/apps/"
        ];

        for (let name of uniqueCandidates) {
            for (let base of iconBases) {
                let svgPath = base + name + ".svg";
                let pngPath = base + name + ".png";
                
                if (Quickshell.iconPath(svgPath, true) !== "") return "file://" + svgPath;
                if (Quickshell.iconPath(pngPath, true) !== "") return "file://" + pngPath;
            }
        }

        return "image://icon/application-x-executable";
    }

    function isMainApp(appId, name) {
        if (!appId && !name) return false;
        let id = (appId || "").toLowerCase();
        let disp = (name || "").toLowerCase();
        
        const hideKeywords = [
            "lutris1", "pinentry", "bulk-rename", "volman", "assistant", "designer", 
            "linguist", "qdbusviewer", "qv4l2", "qvidcap", "avahi", "system-config-", 
            "hplip", "cups", "xdg-desktop-portal", "server", "backend", "helper", 
            "engine", "service", "setup", "wizard", "daemon", "url handler", "handler",
            "prompter", "viewer", "mounter", "writer", "bssh", "bvnc", "byobu", "java-java",
            "electron", "beta", "cmake-gui", "wine", "zenity",
            
            "-settings", "settings-", "qt5ct", "qt6ct", "kvantum", "lstopo", 
            "polkit", "authentication", "kiod", "ksecretd", "jshell", "jconsole", 
            "xterm", "uxterm", "xwayland", "about", "xampp", "nonplasma", "openjdk"
        ];

        for (let kw of hideKeywords) {
            if (id.includes(kw) || disp.includes(kw)) return false;
        }

        const mainApps = [
            "firefox", "chrome", "chromium", "code", "thunar", "kitty", "obsidian", 
            "discord", "spotify", "telegram", "vlc", "mpv", "steam", "zed", "element", 
            "missioncenter", "lutris", "zen", "pavucontrol", "wine", "terminal", 
            "duolingo", "beekeeper", "brave", "htop", "goverlay", "dosbox", "chess",
            "freedownloadmanager"
        ];

        for (let app of mainApps) {
            if (id.includes(app) || disp.includes(app)) return true;
        }

        return disp.length > 4;
    }
}