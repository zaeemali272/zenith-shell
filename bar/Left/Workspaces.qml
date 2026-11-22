import ".."
import "../.."
import "../../Settings"
import "../../services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: workspaceBar

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: mainPill.width

    readonly property HyprlandMonitor monitor: (QsWindow.window && QsWindow.window.monitor) ? QsWindow.window.monitor : null
    property int updateCounter: 0

    Timer {
        id: wsDebounceTimer
        interval: 35
        repeat: false
        onTriggered: workspaceBar.updateCounter++
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { workspaceBar.updateCounter++; }
        function onActiveToplevelChanged() { workspaceBar.updateCounter++; }
        function onRawEvent(event) {
            if (!event) return;
            let n = event.name || "";
            if (n.includes("window") || n.includes("workspace") || n.includes("mon")) {
                wsDebounceTimer.restart();
            }
        }
    }

    // Floating Bubble Pill Container
    Rectangle {
        id: mainPill
        anchors.centerIn: parent
        anchors.leftMargin: Theme.scaled(WorkspaceSettings.barMargins || 0)
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: row.implicitWidth + Theme.scaled(20)
        color: pillHoverArea.containsMouse ? Theme.pillHoverColor : Theme.pillColor
        radius: height / 2
        border.width: WorkspaceSettings.backgroundStyle === "full" ? 1 : 0
        border.color: Theme.glassBorder
        antialiasing: true

        Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        MouseArea {
            id: pillHoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.scaled(WorkspaceSettings.spacing || 8)

            Repeater {
                model: Hyprland.workspaces

                delegate: Rectangle {
                    id: wsBubble

                    visible: modelData && modelData.id > 0

                    readonly property bool isOccupied: {
                        workspaceBar.updateCounter;
                        if (!modelData) return false;
                        if (modelData.toplevels && modelData.toplevels.values && modelData.toplevels.values.length > 0) return true;
                        if (modelData.lastIpcObject && modelData.lastIpcObject.windows !== undefined) return modelData.lastIpcObject.windows > 0;
                        if (Hyprland.toplevels && Hyprland.toplevels.values) {
                            let tls = Hyprland.toplevels.values;
                            for (let i = 0; i < tls.length; i++) {
                                if (tls[i] && tls[i].workspace && tls[i].workspace.id === modelData.id) return true;
                            }
                        }
                        return false;
                    }

                    readonly property bool isCurrentActive: {
                        workspaceBar.updateCounter;
                        if (Hyprland.focusedWorkspace && modelData) return Hyprland.focusedWorkspace.id === modelData.id;
                        return modelData ? modelData.focused : false;
                    }

                    readonly property var wsGlyphs: {
                        workspaceBar.updateCounter;
                        return workspaceBar.getWorkspaceGlyphs(modelData);
                    }

                    readonly property bool isIconsMode: WorkspaceSettings.displayStyle === "icons"
                    readonly property bool isHybridMode: WorkspaceSettings.displayStyle === "hybrid"
                    readonly property bool hasIcons: (isIconsMode || isHybridMode) && wsGlyphs.length > 0

                    // Bubble Dimensions
                    height: isCurrentActive 
                        ? Theme.scaled(22) 
                        : (hasIcons ? Theme.scaled(20) : (isOccupied ? Theme.scaled(10) : Theme.scaled(8)))

                    width: {
                        if (isCurrentActive) {
                            if (isHybridMode && wsGlyphs.length > 0) {
                                return Math.max(Theme.scaled(WorkspaceSettings.activeWidth || 42), Theme.scaled(30 + Math.min(2, wsGlyphs.length) * 14));
                            }
                            if (hasIcons) {
                                return Math.max(Theme.scaled(WorkspaceSettings.activeWidth || 42), Theme.scaled(22 + wsGlyphs.length * 16));
                            }
                            return Theme.scaled(WorkspaceSettings.activeWidth || 42);
                        }
                        if (hasIcons) {
                            return Theme.scaled(14 + wsGlyphs.length * 14);
                        }
                        return height; // Circular dot when inactive in numbers mode or empty
                    }

                    radius: height / 2
                    anchors.verticalCenter: parent.verticalCenter
                    antialiasing: true

                    color: {
                        if (isCurrentActive) {
                            return Theme.accentColor;
                        }
                        if (hasIcons) {
                            return wsMouse.containsMouse 
                                ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.22)
                                : Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.10);
                        }
                        // Non-active dot for number option (or empty): dull accent theme color
                        if (isOccupied) {
                            return wsMouse.containsMouse 
                                ? Theme.accentColor 
                                : Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.50);
                        }
                        return wsMouse.containsMouse 
                            ? Theme.accentColor 
                            : Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.25);
                    }

                    // Remove border from non-active workspaces
                    border.width: 0

                    // Bouncy Morphing Animations
                    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                    Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on radius { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

                    // Elastic Bubble Bounce on Hover & Click
                    scale: wsMouse.pressed ? 0.85 : (wsMouse.containsMouse ? 1.2 : 1.0)
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.elasticEasing; easing.overshoot: 1.15 } }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        anchors.margins: -Theme.scaled(4)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData) {
                                if (typeof modelData.activate === "function") {
                                    modelData.activate();
                                } else {
                                    Hyprland.dispatch("workspace " + modelData.id);
                                }
                            }
                        }
                    }

                    // Content 1: Active Workspace Number (visible only when active and not showing icons)
                    Text {
                        anchors.centerIn: parent
                        text: modelData ? modelData.id.toString() : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Bold
                        color: Colors.on_primary
                        visible: isCurrentActive && !hasIcons
                        opacity: visible ? 1.0 : 0.0

                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                    }

                    // Content 2: Active Hybrid Row (ID + App Icons)
                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.scaled(4)
                        visible: isCurrentActive && isHybridMode && wsBubble.wsGlyphs.length > 0
                        opacity: visible ? 1.0 : 0.0

                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData ? modelData.id.toString() : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight: Font.Bold
                            color: Colors.on_primary
                            antialiasing: true
                        }

                        Repeater {
                            model: wsBubble.wsGlyphs.slice(0, 2)

                            delegate: Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(12)
                                color: Colors.on_primary
                                antialiasing: true
                            }
                        }
                    }

                    // Content 3: Icons Row for Workspace (inactive icons or pure icons mode active)
                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.scaled(3)
                        visible: hasIcons && !(isCurrentActive && isHybridMode)
                        opacity: visible ? 1.0 : 0.0

                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                        Repeater {
                            model: wsBubble.wsGlyphs

                            delegate: Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData
                                font.family: Theme.iconFont
                                font.pixelSize: isCurrentActive ? Theme.scaled(13) : Theme.scaled(12)
                                color: isCurrentActive 
                                    ? Colors.on_primary 
                                    : (wsMouse.containsMouse ? Theme.barIconColor : Qt.rgba(Theme.barIconColor.r, Theme.barIconColor.g, Theme.barIconColor.b, 0.65))
                                antialiasing: true
                            }
                        }
                    }
                }
            }
        }
    }

    function getAppInfo(appId, title) {
        let app = (appId || "").toLowerCase().trim();
        let t = (title || "").toLowerCase().trim();

        // 1. Terminals (Match app class first!)
        if (app.includes("kitty")) return { key: "kitty", glyph: "󰄛" };
        if (app.includes("alacritty")) return { key: "alacritty", glyph: "󰞷" };
        if (app.includes("ghostty")) return { key: "ghostty", glyph: "󰊠" };
        if (app.includes("wezterm")) return { key: "wezterm", glyph: "" };
        if (app.includes("foot") || app.includes("konsole") || app.includes("terminal") || app.includes("ptyxis")) return { key: "terminal", glyph: "󰆍" };

        // 2. Editors & IDEs
        if (app.includes("antigravity")) return { key: "antigravity", glyph: "󰀘" };
        if (app.includes("code") || app.includes("vscode") || app.includes("vscodium")) return { key: "vscode", glyph: "󰨞" };
        if (app.includes("neovim") || app.includes("nvim") || t.startsWith("nvim") || t.startsWith("neovim")) return { key: "neovim", glyph: "" };
        if (app.includes("vim") || t.startsWith("vim ")) return { key: "vim", glyph: "" };
        if (app.includes("emacs")) return { key: "emacs", glyph: "" };
        if (app.includes("sublime")) return { key: "sublime", glyph: "" };
        if (app.includes("cursor")) return { key: "cursor", glyph: "󰅩" };
        if (app.includes("zed")) return { key: "zed", glyph: "󰘦" };
        if (app.includes("intellij") || app.includes("idea")) return { key: "intellij", glyph: "" };
        if (app.includes("pycharm")) return { key: "pycharm", glyph: "" };
        if (app.includes("clion")) return { key: "clion", glyph: "" };
        if (app.includes("webstorm")) return { key: "webstorm", glyph: "" };
        if (app.includes("android-studio")) return { key: "androidstudio", glyph: "󰀴" };

        // 3. Browsers (Carefully check Zen Browser WITHOUT matching 'zenith'!)
        if (app === "zen" || app.includes("zen-browser") || app.includes("zen_browser") || app.startsWith("zen-") || (t.includes("zen browser") && !app.includes("terminal") && !app.includes("kitty"))) return { key: "zen", glyph: "󰖟" };
        if (app.includes("firefox") || app.includes("waterfox") || app.includes("librewolf") || app.includes("floorp")) return { key: "firefox", glyph: "󰈹" };
        if (app.includes("chrome") || app.includes("chromium")) return { key: "chrome", glyph: "󰊯" };
        if (app.includes("brave")) return { key: "brave", glyph: "󰹢" };
        if (app.includes("edge")) return { key: "edge", glyph: "󰇩" };
        if (app.includes("opera")) return { key: "opera", glyph: "󰏎" };
        if (app.includes("safari")) return { key: "safari", glyph: "󰀹" };
        if (app.includes("tor")) return { key: "tor", glyph: "󰈹" };
        if (app.includes("browser") || app.includes("vivaldi") || app.includes("qutebrowser")) return { key: "browser", glyph: "󰖟" };

        // 4. Communication
        if (app.includes("discord") || app.includes("webcord") || app.includes("vesktop") || app.includes("armcord")) return { key: "discord", glyph: "󰙯" };
        if (app.includes("telegram") || app.includes("ayugram")) return { key: "telegram", glyph: "󰭹" };
        if (app.includes("slack")) return { key: "slack", glyph: "󰒱" };
        if (app.includes("whatsapp")) return { key: "whatsapp", glyph: "󰖣" };
        if (app.includes("signal") || app.includes("element") || app.includes("matrix")) return { key: "signal", glyph: "󰭹" };
        if (app.includes("mail") || app.includes("thunderbird") || app.includes("geary") || app.includes("betterbird")) return { key: "mail", glyph: "󰇮" };

        // 5. Media & Audio
        if (app.includes("spotify") || app.includes("feishin") || app.includes("cider") || app.includes("music") || app.includes("amberol") || app.includes("rhythmbox")) return { key: "spotify", glyph: "󰓇" };
        if (app.includes("vlc") || app.includes("mpv") || app.includes("celluloid") || app.includes("clapper") || app.includes("kodi")) return { key: "video", glyph: "󰕼" };
        if (app.includes("pavucontrol") || app.includes("qpwgraph") || app.includes("easyeffects") || app.includes("helvum")) return { key: "audio", glyph: "󰕾" };
        if (app.includes("obs") || app.includes("studio")) return { key: "obs", glyph: "󰑋" };

        // 6. Files & Notes
        if (app.includes("thunar") || app.includes("nautilus") || app.includes("dolphin") || app.includes("pcmanfm") || app.includes("nemo") || app.includes("yazi") || app.includes("ranger") || (app.includes("files") && !app.includes("zenith"))) return { key: "files", glyph: "󰉋" };
        if (app.includes("obsidian")) return { key: "obsidian", glyph: "󱞁" };
        if (app.includes("notion")) return { key: "notion", glyph: "" };
        if (app.includes("libreoffice") || app.includes("writer") || app.includes("calc") || app.includes("impress")) return { key: "office", glyph: "󰈦" };
        if (app.includes("pdf") || app.includes("evince") || app.includes("zathura") || app.includes("okular")) return { key: "pdf", glyph: "󰈦" };

        // 7. Design & Gaming
        if (app.includes("gimp")) return { key: "gimp", glyph: "" };
        if (app.includes("inkscape")) return { key: "inkscape", glyph: "" };
        if (app.includes("blender")) return { key: "blender", glyph: "󰂫" };
        if (app.includes("figma")) return { key: "figma", glyph: "󰽉" };
        if (app.includes("krita") || app.includes("darktable")) return { key: "krita", glyph: "󰽉" };
        if (app.includes("steam") || app.includes("lutris") || app.includes("heroic") || app.includes("gamescope") || app.includes("prism") || app.includes("minecraft")) return { key: "steam", glyph: "󰓓" };

        // 8. System & Utilities
        if (app.includes("btop") || app.includes("htop") || app.includes("missioncenter") || app.includes("glances")) return { key: "monitor", glyph: "󰍛" };
        if (app.includes("settings") || app.includes("control-center")) return { key: "settings", glyph: "󰒓" };
        if (app.includes("docker") || app.includes("lazydocker")) return { key: "docker", glyph: "󰡨" };

        let genericKey = app ? app.split(/[\s\-_\.]+/)[0] : "app";
        return { key: genericKey, glyph: "󰖲" };
    }

    function getAppGlyph(appId, title) {
        return getAppInfo(appId, title).glyph;
    }

    function getWorkspaceGlyphs(ws) {
        if (!ws) return [];
        let seenApps = {};
        let glyphs = [];

        function addWindow(appId, title) {
            if (!appId && !title) return;
            let info = getAppInfo(appId, title);

            // Deduplicate multiple windows of the same parent application
            if (seenApps[info.key]) return;
            seenApps[info.key] = true;

            if (info.glyph && glyphs.indexOf(info.glyph) === -1) {
                glyphs.push(info.glyph);
            }
        }

        // 1. Direct toplevels on ws object
        if (ws.toplevels && ws.toplevels.values) {
            for (let i = 0; i < ws.toplevels.values.length; i++) {
                if (glyphs.length >= 3) break;
                let tl = ws.toplevels.values[i];
                if (!tl) continue;
                let appId = (tl.lastIpcObject && (tl.lastIpcObject.initialClass || tl.lastIpcObject.class))
                         || (tl.wayland && tl.wayland.appId)
                         || tl.appId
                         || "";
                let title = tl.title || (tl.lastIpcObject ? (tl.lastIpcObject.title || tl.lastIpcObject.initialTitle) : "") || "";
                addWindow(appId, title);
            }
        }

        // 2. Hyprland.toplevels matching workspace id
        if (glyphs.length < 3 && Hyprland.toplevels && Hyprland.toplevels.values) {
            for (let i = 0; i < Hyprland.toplevels.values.length; i++) {
                if (glyphs.length >= 3) break;
                let tl = Hyprland.toplevels.values[i];
                if (tl && tl.workspace && tl.workspace.id === ws.id) {
                    let appId = (tl.lastIpcObject && (tl.lastIpcObject.initialClass || tl.lastIpcObject.class))
                             || (tl.wayland && tl.wayland.appId)
                             || tl.appId
                             || "";
                    let title = tl.title || (tl.lastIpcObject ? (tl.lastIpcObject.title || tl.lastIpcObject.initialTitle) : "") || "";
                    addWindow(appId, title);
                }
            }
        }

        // 3. Fallback to lastwindowtitle in lastIpcObject
        if (glyphs.length === 0 && ws.lastIpcObject && ws.lastIpcObject.lastwindowtitle) {
            addWindow("", ws.lastIpcObject.lastwindowtitle);
        }

        // Fallback for occupied workspace without matched icon
        if (glyphs.length === 0 && ws.lastIpcObject && ws.lastIpcObject.windows > 0) {
            glyphs.push("󰖲");
        }

        return glyphs.slice(0, 3);
    }

    function getWorkspaceGlyph(ws) {
        let glyphs = getWorkspaceGlyphs(ws);
        return glyphs.length > 0 ? glyphs[0] : "";
    }

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0) {
                Hyprland.dispatch("workspace", "e+1");
            } else if (event.angleDelta.y > 0) {
                Hyprland.dispatch("workspace", "e-1");
            }
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }
}