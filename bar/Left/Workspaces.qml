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

    function getAppGlyph(appId, title) {
        let id = ((appId || "") + " " + (title || "")).toLowerCase();
        // Browsers (distinct glyphs)
        if (id.includes("zen")) return "󰖟";
        if (id.includes("firefox") || id.includes("waterfox") || id.includes("librewolf")) return "󰈹";
        if (id.includes("chrome") || id.includes("chromium")) return "󰊯";
        if (id.includes("edge")) return "󰇩";
        if (id.includes("opera")) return "󰏎";
        if (id.includes("safari")) return "󰀹";
        if (id.includes("brave")) return "󰹢";
        if (id.includes("tor")) return "󰈹";
        if (id.includes("browser")) return "󰖟";

        // Editors & IDEs (distinct glyphs)
        if (id.includes("antigravity")) return "󰀘";
        if (id.includes("code") || id.includes("vscode") || id.includes("visual studio")) return "󰨞";
        if (id.includes("neovim") || id.includes("nvim")) return "";
        if (id.includes("vim")) return "";
        if (id.includes("emacs")) return "";
        if (id.includes("sublime")) return "";
        if (id.includes("intellij") || id.includes("idea")) return "";
        if (id.includes("pycharm")) return "";
        if (id.includes("clion")) return "";
        if (id.includes("webstorm")) return "";
        if (id.includes("cursor")) return "󰅩";
        if (id.includes("zed")) return "󰘦";

        // Terminals (distinct glyphs)
        if (id.includes("kitty")) return "󰄛";
        if (id.includes("ghostty")) return "󰊠";
        if (id.includes("alacritty")) return "󰞷";
        if (id.includes("wezterm")) return "";
        if (id.includes("foot") || id.includes("terminal") || id.includes("konsole") || id.includes("bash") || id.includes("zsh") || id.includes("fish")) return "󰆍";

        // Communication
        if (id.includes("discord") || id.includes("webcord") || id.includes("vesktop") || id.includes("armcord")) return "󰙯";
        if (id.includes("telegram") || id.includes("ayugram")) return "󰭹";
        if (id.includes("slack")) return "󰒱";
        if (id.includes("whatsapp")) return "󰖣";
        if (id.includes("signal") || id.includes("element")) return "󰭹";
        if (id.includes("mail") || id.includes("thunderbird") || id.includes("geary") || id.includes("betterbird")) return "󰇮";

        // Media & Audio
        if (id.includes("spotify") || id.includes("music") || id.includes("feishin") || id.includes("cider") || id.includes("youtube music") || id.includes("amberol") || id.includes("rhythmbox")) return "󰓇";
        if (id.includes("vlc") || id.includes("mpv") || id.includes("celluloid") || id.includes("kodi") || id.includes("video") || id.includes("clapper")) return "󰕼";
        if (id.includes("pavucontrol") || id.includes("qpwgraph") || id.includes("easyeffects") || id.includes("helvum")) return "󰕾";

        // Files & Notes
        if (id.includes("thunar") || id.includes("nautilus") || id.includes("dolphin") || id.includes("files") || id.includes("pcmanfm") || id.includes("nemo") || id.includes("yazi") || id.includes("ranger")) return "󰉋";
        if (id.includes("obsidian")) return "󱞁";
        if (id.includes("notion")) return "";
        if (id.includes("notes") || id.includes("logseq") || id.includes("joplin") || id.includes("anytype")) return "󱞁";
        if (id.includes("libreoffice") || id.includes("writer") || id.includes("calc") || id.includes("impress") || id.includes("document") || id.includes("pdf") || id.includes("evince") || id.includes("zathura")) return "󰈦";

        // Design & Gaming
        if (id.includes("gimp")) return "";
        if (id.includes("inkscape")) return "";
        if (id.includes("blender")) return "󰂫";
        if (id.includes("figma")) return "󰽉";
        if (id.includes("krita") || id.includes("darktable") || id.includes("rawtherapee")) return "󰽉";
        if (id.includes("steam") || id.includes("lutris") || id.includes("heroic") || id.includes("gamescope") || id.includes("prism") || id.includes("minecraft")) return "󰓓";

        // System
        if (id.includes("btop") || id.includes("htop") || id.includes("missioncenter") || id.includes("system-monitoring-center")) return "󰍛";
        if (id.includes("settings") || id.includes("control") || id.includes("pavucontrol")) return "󰒓";

        return "󰖲";
    }

    function getWorkspaceGlyphs(ws) {
        if (!ws) return [];
        let seenApps = {};
        let glyphs = [];

        function addWindow(appId, title) {
            if (!appId && !title) return;
            let id = ((appId || "") + " " + (title || "")).toLowerCase();
            
            // Parent app identification to deduplicate sub-windows and multiple instances
            let appKey = "";
            if (id.includes("zen")) appKey = "zen";
            else if (id.includes("antigravity")) appKey = "antigravity";
            else if (id.includes("code") || id.includes("vscode")) appKey = "vscode";
            else if (id.includes("firefox") || id.includes("waterfox") || id.includes("librewolf")) appKey = "firefox";
            else if (id.includes("chrome") || id.includes("chromium")) appKey = "chrome";
            else if (id.includes("brave")) appKey = "brave";
            else if (id.includes("edge")) appKey = "edge";
            else if (id.includes("opera")) appKey = "opera";
            else if (id.includes("safari")) appKey = "safari";
            else if (id.includes("neovim") || id.includes("nvim")) appKey = "neovim";
            else if (id.includes("vim")) appKey = "vim";
            else if (id.includes("emacs")) appKey = "emacs";
            else if (id.includes("sublime")) appKey = "sublime";
            else if (id.includes("cursor")) appKey = "cursor";
            else if (id.includes("zed")) appKey = "zed";
            else if (id.includes("intellij") || id.includes("idea")) appKey = "intellij";
            else if (id.includes("pycharm")) appKey = "pycharm";
            else if (id.includes("clion")) appKey = "clion";
            else if (id.includes("webstorm")) appKey = "webstorm";
            else if (id.includes("kitty")) appKey = "kitty";
            else if (id.includes("alacritty")) appKey = "alacritty";
            else if (id.includes("ghostty")) appKey = "ghostty";
            else if (id.includes("wezterm")) appKey = "wezterm";
            else if (id.includes("foot") || id.includes("terminal") || id.includes("konsole")) appKey = "terminal";
            else if (id.includes("discord") || id.includes("vesktop") || id.includes("webcord")) appKey = "discord";
            else if (id.includes("telegram") || id.includes("ayugram")) appKey = "telegram";
            else if (id.includes("slack")) appKey = "slack";
            else if (id.includes("whatsapp")) appKey = "whatsapp";
            else if (id.includes("mail") || id.includes("thunderbird") || id.includes("geary")) appKey = "mail";
            else if (id.includes("spotify")) appKey = "spotify";
            else if (id.includes("vlc") || id.includes("mpv") || id.includes("celluloid")) appKey = "video";
            else if (id.includes("pavucontrol") || id.includes("qpwgraph") || id.includes("easyeffects")) appKey = "audio";
            else if (id.includes("thunar") || id.includes("nautilus") || id.includes("dolphin") || id.includes("files")) appKey = "files";
            else if (id.includes("obsidian")) appKey = "obsidian";
            else if (id.includes("notion")) appKey = "notion";
            else if (id.includes("gimp")) appKey = "gimp";
            else if (id.includes("inkscape")) appKey = "inkscape";
            else if (id.includes("blender")) appKey = "blender";
            else if (id.includes("figma")) appKey = "figma";
            else if (id.includes("steam")) appKey = "steam";
            else if (id.includes("btop") || id.includes("htop") || id.includes("missioncenter")) appKey = "monitor";
            else if (id.includes("settings") || id.includes("control")) appKey = "settings";
            else {
                appKey = appId ? appId.toLowerCase().split(/[\s\-_\.]+/)[0] : "app";
            }

            // Only parent apps (deduplicate multiple windows of the same parent application)
            if (seenApps[appKey]) return;
            seenApps[appKey] = true;

            let glyph = getAppGlyph(appId, title);
            if (glyph && glyphs.indexOf(glyph) === -1) {
                glyphs.push(glyph);
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