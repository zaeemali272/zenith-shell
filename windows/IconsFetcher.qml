pragma Singleton
import QtQuick
import Quickshell
import "../services" as Services

QtObject {
    id: iconsFetcher

    function getIconCandidates(appName, desktopEntry, iconName) {
        let raw = (iconName || "").trim();
        let desktop = (desktopEntry || "").replace(/\.desktop$/i, "").trim();
        let app = (appName || "").trim();

        let candidates = [];

        // Direct file path if specified
        if (raw.startsWith("/") || raw.startsWith("file://")) {
            candidates.push(raw.startsWith("file://") ? raw : "file://" + raw);
        }

        // An already-resolved "image://icon/<name>" comes back through here
        // when a notification is re-rendered; only the name is a token, or
        // every file probe below is built on a URL and fails.
        if (raw.startsWith("image://icon/")) raw = raw.substring("image://icon/".length);

        let rawTokens = [];
        if (raw !== "") {
            rawTokens.push(raw);
            if (raw.includes("/")) {
                let parts = raw.split("/");
                rawTokens.push(parts[parts.length - 1]);
            }
        }

        if (desktop !== "") {
            rawTokens.push(desktop);
            if (desktop.includes(".")) {
                let parts = desktop.split(".");
                rawTokens.push(parts[parts.length - 1]);
            }
        }

        if (app !== "") {
            let appSlug = app.toLowerCase().replace(/\s+/g, '-');
            rawTokens.push(appSlug);
            rawTokens.push(app.toLowerCase());
        }

        let appLower = app.toLowerCase();
        let desktopLower = desktop.toLowerCase();
        let rawLower = raw.toLowerCase();
        let combo = appLower + " " + desktopLower + " " + rawLower;

        // Sub-words from app and desktop
        let words = combo.split(/[\s\-_\.]+/);
        for (let w of words) {
            if (w.length >= 3) rawTokens.push(w);
        }

        // Domain-specific smart mapping for Linux desktop notifications
        if (combo.includes("screenshot") || combo.includes("hyprshot") || combo.includes("snip") || combo.includes("grimblast")) {
            rawTokens.push("accessories-screenshot", "gnome-screenshot", "camera-photo", "applets-screenshooter", "screenshot-ui-display");
        } else if (combo.includes("recorder") || combo.includes("screenrec") || combo.includes("screen record") || combo.includes("screencast")) {
            rawTokens.push("screenrecorder", "screen-recorder", "media-record", "screencast-recorded", "camera-video");
        } else if (combo.includes("antigravity")) {
            rawTokens.push("antigravity-ide", "antigravity");
        } else if (combo.includes("color picker") || combo.includes("hyprpicker") || combo.includes("pipette")) {
            rawTokens.push("color-picker", "gcolor3", "color-management");
        } else if (combo.includes("caffeine")) {
            rawTokens.push("preferences-desktop-screensaver", "caffeine");
        } else if (combo.includes("terminal") || combo.includes("shell") || combo.includes("bash") || combo.includes("zsh")) {
            rawTokens.push("utilities-terminal", "terminal", "kitty", "alacritty");
        } else if (combo.includes("thunar") || combo.includes("file manager")) {
            rawTokens.push("org.xfce.thunar", "thunar", "system-file-manager");
        } else if (combo.includes("dnd") || combo.includes("do not disturb")) {
            rawTokens.push("notifications-disabled", "preferences-desktop-notification-bell");
        } else if (combo.includes("zen")) {
            rawTokens.push("zen", "zen-browser", "web-browser");
        } else if (combo.includes("code") || combo.includes("vscode")) {
            rawTokens.push("code", "vscode", "visual-studio-code");
        } else if (combo.includes("telegram")) {
            rawTokens.push("telegram", "telegram-desktop", "org.telegram.desktop");
        } else if (combo.includes("discord")) {
            rawTokens.push("discord", "com.discordapp.Discord");
        } else if (combo.includes("spotify")) {
            rawTokens.push("spotify", "spotify-client");
        } else if (combo.includes("chrome")) {
            rawTokens.push("google-chrome", "chrome");
        } else if (combo.includes("firefox")) {
            rawTokens.push("firefox", "firefox-esr");
        }

        let cleanTokens = [];
        for (let entry of rawTokens) {
            if (!entry || entry === "") continue;
            if (entry.startsWith("/") || entry.startsWith("file://")) continue;
            let base = entry.replace(/\.(png|svg|xpm|jpg|jpeg)$/i, "").trim();
            if (base && base !== "") cleanTokens.push(base);
        }

        let uniqueTokens = cleanTokens.filter((v, i, a) => v && v !== "" && a.indexOf(v) === i);

        // Prioritized token expansion for battery, status, and symbolic icon formats
        let expandedTokens = [];
        for (let token of uniqueTokens) {
            // Normalize battery level tokens first (e.g. battery-level-100-symbolic -> battery-100)
            let batMatch = token.match(/^battery(?:-level)?-(\d+)(?:-(charging))?(?:-(symbolic))?$/i);
            if (batMatch) {
                let lvl = parseInt(batMatch[1]);
                let numStr = lvl.toString();
                let pad3 = numStr.padStart(3, '0');
                let isChg = !!batMatch[2];
                let chgSuffix = isChg ? "-charging" : "";

                expandedTokens.push("battery-" + numStr + chgSuffix);
                expandedTokens.push("battery-" + pad3 + chgSuffix);
                expandedTokens.push("battery-" + numStr + chgSuffix + "-symbolic");
                expandedTokens.push("battery-" + pad3 + chgSuffix + "-symbolic");
                expandedTokens.push("battery-" + numStr);
                expandedTokens.push("battery-" + pad3);
                if (isChg) {
                    expandedTokens.push("battery-good-charging-symbolic");
                    expandedTokens.push("battery-good-charging");
                    expandedTokens.push("battery-charging");
                } else {
                    expandedTokens.push("battery-good-symbolic");
                    expandedTokens.push("battery-good");
                }
                expandedTokens.push("battery-symbolic");
                expandedTokens.push("battery");
            }

            if (token.endsWith("-symbolic")) {
                expandedTokens.push(token);
                expandedTokens.push(token.replace(/-symbolic$/i, ""));
            } else {
                expandedTokens.push(token + "-symbolic");
                expandedTokens.push(token);
            }
        }

        let allTokens = expandedTokens.filter((v, i, a) => v && v !== "" && a.indexOf(v) === i);

        // 1. Native Qt Theme resolution (instant C++ check)
        for (let token of allTokens) {
            if (Quickshell.hasThemeIcon(token)) {
                candidates.push("image://icon/" + token);
            }
        }

        // 2. Pre-computed, distro-verified icon base paths and theme subpaths from Services.Variables
        // Only directories that exist: probing is done by an Image per
        // candidate, so every impossible path is a failed load and a warning.
        let iconDirs = Services.Variables.iconDirs || [];
        if (iconDirs.length === 0) {
            for (let base of (Services.Variables.iconBases || []))
                for (let sub of (Services.Variables.themeSubPaths || []))
                    iconDirs.push(base + sub);
        }

        let pixmapDirs = [
            "/etc/profiles/per-user/" + (Services.Variables.user || "") + "/share/pixmaps/",
            "/run/current-system/sw/share/pixmaps/",
            "/usr/share/pixmaps/",
            (Services.Variables.homeDir || "") + "/.local/share/pixmaps/"
        ];

        let fileTokens = allTokens.slice(0, 5);
        for (let token of fileTokens) {
            for (let dir of pixmapDirs) {
                candidates.push("file://" + dir + token + ".png");
                candidates.push("file://" + dir + token + ".svg");
            }
            for (let dir of iconDirs) {
                candidates.push("file://" + dir + token + ".svg");
                candidates.push("file://" + dir + token + ".png");
            }
        }

        // Fallback theme names
        for (let token of allTokens) {
            candidates.push("image://icon/" + token);
        }

        if (Quickshell.hasThemeIcon("dialog-information-symbolic")) {
            candidates.push("image://icon/dialog-information-symbolic");
        } else if (Quickshell.hasThemeIcon("dialog-information")) {
            candidates.push("image://icon/dialog-information");
        }
        if (Quickshell.hasThemeIcon("application-x-executable-symbolic")) {
            candidates.push("image://icon/application-x-executable-symbolic");
        }
        candidates.push("image://icon/application-x-executable");

        return candidates.filter((v, i, a) => v && v !== "" && a.indexOf(v) === i);
    }

    property var _iconCache: ({})

    function getValidIcon(appName, desktopEntry, iconName) {
        let key = (appName || "") + "::" + (desktopEntry || "") + "::" + (iconName || "");
        if (_iconCache[key]) return _iconCache[key];

        let raw = (iconName || "").trim();

        // Direct file path if specified
        if (raw.startsWith("/") || raw.startsWith("file://")) {
            let direct = raw.startsWith("file://") ? raw : ("file://" + raw);
            _iconCache[key] = direct;
            return direct;
        }

        // Fast native Qt Theme resolution
        if (raw !== "") {
            let sym = raw.endsWith("-symbolic") ? raw : (raw + "-symbolic");
            if (Quickshell.hasThemeIcon(sym)) {
                let res = "image://icon/" + sym;
                _iconCache[key] = res;
                return res;
            }
            if (Quickshell.hasThemeIcon(raw)) {
                let res = "image://icon/" + raw;
                _iconCache[key] = res;
                return res;
            }
        }

        let candidates = getIconCandidates(appName, desktopEntry, iconName);
        
        for (let cand of candidates) {
            if (cand.startsWith("image://icon/")) {
                let name = cand.replace("image://icon/", "");
                if (Quickshell.hasThemeIcon(name)) {
                    _iconCache[key] = cand;
                    return cand;
                }
            }
        }

        let fallback = (candidates.length > 0) ? candidates[0] : (
            Quickshell.hasThemeIcon("application-x-executable-symbolic")
                ? "image://icon/application-x-executable-symbolic"
                : "image://icon/application-x-executable"
        );
        _iconCache[key] = fallback;
        return fallback;
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