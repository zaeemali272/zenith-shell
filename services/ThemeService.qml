pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

QtObject {
    id: root

    readonly property string configPath: PathSettings.stateDir + "/theme_config.json"
    readonly property string scriptPath: PathSettings.scriptsDir + "/zenith-theme.sh"

    property string themeMode: "dynamic" // "dynamic" or "preset"
    property string currentPreset: "catppuccin-mocha"
    property string accentColor: ""
    property string borderGlow: "glass" // "glass", "neon", "gradient"
    property var presets: []

    // Built-in fallback presets if scripts/zenith-theme.sh hasn'\''t finished listing
    readonly property var defaultPresets: [
        { id: "catppuccin-mocha", name: "Catppuccin Mocha", category: "Pastel Dark", background: "#1e1e2e", surface: "#1e1e2e", primary: "#cba6f7", secondary: "#89b4fa" },
        { id: "tokyo-night", name: "Tokyo Night Storm", category: "Cyber Dark", background: "#1f2335", surface: "#1f2335", primary: "#7aa2f7", secondary: "#bb9af7" },
        { id: "nord", name: "Nord Frost", category: "Arctic Minimal", background: "#2e3440", surface: "#2e3440", primary: "#88c0d0", secondary: "#81a1c1" },
        { id: "gruvbox-dark", name: "Gruvbox Retro", category: "Warm Vintage", background: "#282828", surface: "#282828", primary: "#d79921", secondary: "#fe8019" },
        { id: "rose-pine", name: "Rosé Pine", category: "Serene Muted", background: "#191724", surface: "#191724", primary: "#ebbcba", secondary: "#f6c177" },
        { id: "cyberpunk", name: "Cyberpunk 2077", category: "Neon Synth", background: "#0d0d14", surface: "#0d0d14", primary: "#ffee00", secondary: "#00f0ff" },
        { id: "oled-black", name: "OLED Pitch Black", category: "Ultra Minimal OLED", background: "#000000", surface: "#000000", primary: "#38bdf8", secondary: "#a855f7" },
        { id: "dracula", name: "Dracula", category: "Gothic Vampire", background: "#282a36", surface: "#282a36", primary: "#ff79c6", secondary: "#bd93f9" },
        { id: "midnight", name: "Midnight Sapphire", category: "Deep Ocean", background: "#0b132b", surface: "#0b132b", primary: "#48cae4", secondary: "#90e0ef" },
        { id: "catppuccin-macchiato", name: "Catppuccin Macchiato", category: "Soft Dark", background: "#24273a", surface: "#24273a", primary: "#c6a0f6", secondary: "#8aadf4" }
    ]

    // Watch config changes
    property FileView _configFile: FileView {
        path: root.configPath
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            try {
                let parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object") {
                    if (parsed.mode) root.themeMode = parsed.mode;
                    if (parsed.preset) root.currentPreset = parsed.preset;
                    if (parsed.accent !== undefined) root.accentColor = parsed.accent;
                    if (parsed.borderGlow) root.borderGlow = parsed.borderGlow;
                }
            } catch(e) {}
        }
    }

    // Process to list available presets
    property Process listProc: Process {
        id: listProc
        command: [root.scriptPath, "--list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text);
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        root.presets = parsed;
                        return;
                    }
                } catch(e) {}
                root.presets = root.defaultPresets;
            }
        }
    }

    // Process to apply themes
    property Process applyProc: Process {
        id: applyProc
    }

    function applyPreset(presetId, customAccent) {
        let acc = (customAccent !== undefined) ? customAccent : root.accentColor;
        let cmd = [root.scriptPath, "--preset", presetId];
        if (acc && acc !== "") {
            cmd.push("--accent", acc);
        }
        root.themeMode = "preset";
        root.currentPreset = presetId;
        if (customAccent !== undefined) root.accentColor = customAccent;

        applyProc.command = cmd;
        applyProc.running = true;
    }

    function applyDynamic(wallPath) {
        let cmd = [root.scriptPath, "--dynamic"];
        if (wallPath && wallPath !== "") {
            cmd.push(wallPath);
        }
        root.themeMode = "dynamic";
        applyProc.command = cmd;
        applyProc.running = true;
    }

    function setAccent(hex) {
        root.accentColor = hex;
        if (root.themeMode === "preset") {
            applyPreset(root.currentPreset, hex);
        } else {
            let cmd = [root.scriptPath, "--dynamic"];
            if (hex && hex !== "") {
                cmd.push("--color", hex);
            }
            applyProc.command = cmd;
            applyProc.running = true;
        }
    }

    function setBorderGlow(style) {
        root.borderGlow = style;
        saveState();
    }

    function saveState() {
        saveProc.command = ["sh", "-c", "cat <<'EOF' > " + root.configPath + "\n" + JSON.stringify({
            mode: root.themeMode,
            preset: root.currentPreset,
            accent: root.accentColor,
            borderGlow: root.borderGlow
        }, null, 2) + "\nEOF"];
        saveProc.running = true;
    }

    property Process saveProc: Process { id: saveProc }

    Component.onCompleted: {
        root.presets = root.defaultPresets;
        listProc.running = true;
    }
}
