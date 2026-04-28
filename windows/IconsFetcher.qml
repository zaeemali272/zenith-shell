pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: iconsFetcher

    function getCandidates(appName, desktopEntry, iconName) {
        let candidates = [];
        let names = [];
        
        let raw = (iconName || "");
        let desktop = (desktopEntry || "").replace(".desktop", "");
        let app = (appName || "");
        
        // 0. Handle absolute paths immediately
        if (raw.startsWith("/")) candidates.push("file://" + raw);
        if (app.startsWith("/")) candidates.push("file://" + app);
        
        // Search string includes everything we know about the app
        let searchStr = (desktop + " " + app + " " + raw).toLowerCase();
        
        // 1. High-Priority Manual Overrides
        if (searchStr.includes("element")) names.push("io.element.Element", "element", "element-desktop");
        if (searchStr.includes("lutris")) names.push("net.lutris.Lutris", "lutris");
        if (searchStr.includes("missioncenter") || searchStr.includes("mission center")) names.push("io.missioncenter.MissionCenter", "missioncenter");
        if (searchStr.includes("fileroller") || searchStr.includes("file-roller")) names.push("org.gnome.FileRoller", "file-roller", "gnome-fileroller");
        if (searchStr.includes("zed")) names.push("zed", "dev.zed.Zed");
        if (searchStr.includes("zen")) names.push("zen-browser", "zen", "zen-icon", "browser-zen");
        if (searchStr.includes("cmake")) names.push("CMakeSetup", "cmake", "cmake-gui");
        if (searchStr.includes("code") || searchStr.includes("visualstudio") || searchStr.includes("visual studio")) names.push("com.visualstudio.code", "vscode", "code", "visual-studio-code");
        if (searchStr.includes("kitty") || searchStr.includes("terminal")) names.push("kitty", "utilities-terminal", "terminal", "terminal-icon");
        if (searchStr.includes("thunar")) names.push("thunar", "system-file-manager", "org.gnome.Nautilus");
        if (searchStr.includes("obsidian")) names.push("obsidian", "obsidian-icon");
        if (searchStr.includes("pavucontrol") || searchStr.includes("volume")) names.push("multimedia-volume-control", "pavucontrol");
        if (searchStr.includes("beekeeper")) names.push("beekeeper-studio", "beekeeper");
        if (searchStr.includes("youtube music") || searchStr.includes("youtube-music") || searchStr.includes("yt-music") || searchStr.includes("ytmusic")) names.push("com.github.th-ch.youtube-music", "youtube-music", "yt-music", "multimedia-audio-player");
        if (searchStr.includes("goverlay")) names.push("goverlay");
        if (searchStr.includes("wine")) names.push("wine", "wine-icon", "wine-desktop");
        if (searchStr.includes("winetricks")) names.push("winetricks");
        if (searchStr.includes("steam")) names.push("steam", "steam_icon_logo", "steam-icon");
        if (searchStr.includes("discord")) names.push("com.discordapp.Discord", "discord", "discord-icon");
        if (searchStr.includes("spotify")) names.push("com.spotify.Client", "spotify", "spotify-client");
        if (searchStr.includes("browser") || searchStr.includes("firefox")) names.push("firefox", "browser", "firefox-browser");
        if (searchStr.includes("chrome") || searchStr.includes("google-chrome")) names.push("google-chrome", "chrome", "google-chrome-stable");
        if (searchStr.includes("kvantum")) names.push("kvantum", "kvantummanager", "kvantum-manager");
        if (searchStr.includes("freedownloadmanager") || searchStr.includes("fdm")) names.push("freedownloadmanager", "fdm", "org.freedownloadmanager.fdm", "freedownloadmanager-bin");
        
        // 2. Collect names from inputs (preserving case)
        if (raw !== "" && !raw.startsWith("/")) names.push(raw);
        if (desktop !== "") {
            names.push(desktop);
            names.push(desktop.replace(/\./g, '-'));
            let parts = desktop.split(".");
            if (parts.length > 1) names.push(parts[parts.length - 1]);
        }
        
        if (app !== "" && !app.startsWith("/")) {
            names.push(app);
            names.push(app.replace(/\s+/g, '-'));
            names.push(app.replace(/\./g, '-'));
            if (app.includes(".")) {
                let parts = app.split(".");
                names.push(parts[parts.length - 1]);
            }
        }

        // Add lowercase versions
        let lowerNames = names.map(n => n.toLowerCase());
        names = names.concat(lowerNames);

        // Deduplicate
        names = names.filter((v, i, a) => v && v !== "" && a.indexOf(v) === i);

        // 3. Quickshell icon provider (System Theme)
        for (let name of names) {
            if (!name.includes("/")) {
                let path = Quickshell.iconPath(name);
                if (path && path !== "") {
                    if (path.startsWith("/")) candidates.push("file://" + path);
                    else if (path.includes("://")) candidates.push(path);
                    else candidates.push("image://icon/" + path);
                }
            }
        }

        // 4. Manual directory scan (Broad Search)
        let bases = [
            "/usr/share/icons/OneUI/scalable/apps/",
            "/usr/share/icons/OneUI/48x48/apps/",
            "/usr/share/icons/OneUI/symbolic/status/",
            "/usr/share/icons/hicolor/scalable/apps/",
            "/usr/share/icons/hicolor/512x512/apps/",
            "/usr/share/icons/hicolor/256x256/apps/",
            "/usr/share/icons/hicolor/128x128/apps/",
            "/usr/share/icons/hicolor/64x64/apps/",
            "/usr/share/icons/hicolor/48x48/apps/",
            "/usr/share/icons/hicolor/32x32/apps/",
            "/usr/share/icons/Adwaita/scalable/apps/",
            "/usr/share/icons/Adwaita/48x48/apps/",
            "/usr/share/icons/breeze/apps/48/",
            "/usr/share/pixmaps/",
            "/usr/share/icons/"
        ];

        for (let name of names) {
            if (name.includes("/")) continue;
            for (let base of bases) {
                candidates.push("file://" + base + name + ".svg");
                candidates.push("file://" + base + name + ".png");
                candidates.push("file://" + base + name + ".xpm");
                // Try with @48 or similar if needed (optional)
            }
        }
        
        // 5. Fallback: image://icon/
        for (let name of names) {
            candidates.push("image://icon/" + name);
        }

        candidates.push("image://icon/application-x-executable");
        
        return candidates.filter((v, i, a) => v && v !== "" && a.indexOf(v) === i);
    }

    function getIconPath(appName, desktopEntry, iconName) {
        let cs = getCandidates(appName, desktopEntry, iconName);
        return cs.length > 0 ? cs[0] : "image://icon/application-x-executable";
    }

    function isMainApp(appId, name) {
        if (!appId && !name) return false;
        let id = (appId || "").toLowerCase();
        let disp = (name || "").toLowerCase();
        
        const hideKeywords = [
            "lutris1", "pinentry", "bulk-rename", "volman", 
            "assistant", "designer", "linguist", "qdbusviewer", "qv4l2", "qvidcap",
            "avahi", "bwa-", "system-config-", "hplip", "cups",
            "software-properties", "java-settings", "gcr-", "debian-uxterm", "debian-xterm",
            "texdoctk", "recons", "fcitx", "ibus", "im-config", "xdg-desktop-portal",
            "vnc", "server", "backend", "helper", "engine", "service", "setup", 
            "wizard", "debug", "test", "monitor", "agent", "handler", "mounter", "writer",
            "config", "profile", "session", "daemon", "kiod", "ksecretd", "nonplasma",
            "picker", "discover", "editor", "info", "utility", "manager", "qt6", "qt5", 
            "bssh", "bvnc", "xterm", "uxterm", "wayland", "x11", "tty", "shell", "console", 
            "xfce", "about", "open", "url", "handler"
        ];

        // Only hide if it's NOT in the mainApps list
        const mainApps = [
            "firefox", "chrome", "chromium", "code", "thunar", "kitty", "obsidian", 
            "discord", "spotify", "telegram", "vlc", "mpv", "steam", "zed", "element", 
            "messenger", "whatsapp", "slack", "missioncenter", "lutris", 
            "beekeeper", "vscode", "nautilus", "dolphin", "ark", "file-roller", "zen",
            "pavucontrol", "qemu", "virt-manager", "goverlay", "dosbox", "winetricks", "xarchiver",
            "youtube-music", "yt-music", "ytmusic", "youtube music", "tor-browser", "cmake", "zenity", "lollypop", "cameractrls",
            "pupgui2", "wine", "terminal", "browser", "manager", "editor", "player", "office",
            "kvantum", "fdm", "freedownloadmanager"
        ];

        for (let app of mainApps) {
            if (id.includes(app) || disp.includes(app)) return true;
        }

        for (let kw of hideKeywords) {
            if (id.includes(kw) || disp.includes(kw)) return false;
        }

        if (disp.length <= 3 && !mainApps.some(a => id.includes(a))) return false;
        
        return true;
    }
}
