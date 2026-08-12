//@ pragma UseQApplication
import QtQuick
import QtQml 2.15
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "bar"
import "bar/Menu"
import "bar/Menu/components"
import "services"
import "Settings"
import "windows"

Scope {
    readonly property var _notifications: NotificationService
    readonly property var _battery: BatteryService
    readonly property var _media: MediaPlayerService
    readonly property var _productivity: ProductivityService

    // --- IPC HANDLER FOR ZENITH:MENU ---
    IpcHandler {
        target: "zenith:menu"

        function toggle(drawer: string): void {
            handleCommand(drawer);
        }

        function launcher(): void { handleCommand("launcher"); }
        function dashboard(): void { handleCommand("dashboard"); }
        function wallpaper(): void { handleCommand("wallpaper"); }
        function ai(): void { handleCommand("ai"); }
        function pomodoro(): void { handleCommand("pomodoro"); }
        function volume(): void { handleCommand("volume"); }
        function clipboard(): void { handleCommand("clipboard"); }
        function emoji(): void { handleCommand("emoji"); }
        function power(): void { handleCommand("power"); }
        function settings(): void { handleCommand("settings"); }
        function close(): void { handleCommand("close"); }
    }

    // --- INSTANT IPC VIA NAMED PIPE (FIFO) ---
    property string cmdPath: Quickshell.env("HOME") + "/.cache/zenith_fifo"
    
    // --- NATIVE HYPRLAND GLOBAL SHORTCUTS ---
    GlobalShortcut { appid: "zenith"; name: "launcher"; onPressed: handleCommand("launcher") }
    GlobalShortcut { appid: "zenith"; name: "dashboard"; onPressed: handleCommand("dashboard") }
    GlobalShortcut { appid: "zenith"; name: "wallpaper"; onPressed: handleCommand("wallpaper") }
    GlobalShortcut { appid: "zenith"; name: "ai"; onPressed: handleCommand("ai") }
    GlobalShortcut { appid: "zenith"; name: "pomodoro"; onPressed: handleCommand("pomodoro") }
    GlobalShortcut { appid: "zenith"; name: "volume"; onPressed: handleCommand("volume") }
    GlobalShortcut { appid: "zenith"; name: "close"; onPressed: handleCommand("close") }
    GlobalShortcut { appid: "zenith"; name: "clipboard"; onPressed: handleCommand("clipboard") }
    GlobalShortcut { appid: "zenith"; name: "emoji"; onPressed: handleCommand("emoji") }
    GlobalShortcut { appid: "zenith"; name: "power"; onPressed: handleCommand("power") }
    GlobalShortcut { appid: "zenith"; name: "settings"; onPressed: handleCommand("settings") }
    
    property bool settingsVisible: false
    
    Process {
        id: ipcReader
        command: ["sh", "-c", "mkdir -p $HOME/.cache && (rm -f " + cmdPath + " 2>/dev/null; mkfifo " + cmdPath + " 2>/dev/null || true) && while true; do cat " + cmdPath + " 2>/dev/null || sleep 0.1; done"]
        running: true
        
        stdout: SplitParser {
            onRead: (data) => {
                let cmd = data.trim();
                if (cmd !== "") {
                    handleCommand(cmd);
                }
            }
        }
    }

    function handleCommand(cmd) {
        let parts = cmd.split(":");
        let action = parts[0].trim();
        let lowerAction = action.toLowerCase();
        let arg = parts.length > 1 ? parts[1].trim() : "";
        let lowerArg = arg.toLowerCase();

        if (lowerAction === "launcher" || lowerAction === "toggle_launcher" || lowerAction === "applauncher") {
            DynamicIslandService.toggle("launcher");
        } else if (lowerAction === "clipboard" || lowerAction === "toggle_clipboard" || lowerAction === "clip" || lowerAction === "cliphist") {
            DynamicIslandService.toggle("clipboard");
        } else if (lowerAction === "emoji" || lowerAction === "toggle_emoji" || lowerAction === "emojis" || lowerAction === "emojiselector") {
            DynamicIslandService.toggle("emoji");
        } else if (lowerAction === "dashboard" || lowerAction === "toggle_dashboard" || lowerAction === "actionlauncher" || lowerAction === "overview") {
            let tab = "Default";
            if (lowerArg === "pomodoro") tab = "Pomodoro";
            else if (lowerArg === "wallpaper" || lowerArg === "wallpapers") tab = "Wallpaper";
            else if (lowerArg === "ai" || lowerArg === "aiagent" || lowerArg === "agent") tab = "AI Agent";
            CenterState.toggle(tab);
        } else if (lowerAction === "quicksettings" || lowerAction === "toggle_quicksettings") {
            let tab = arg || "network";
            QuickSettingsService.toggle(tab);
        } else if (lowerAction === "wallpaper" || lowerAction === "wallpapers") {
            CenterState.toggle("Wallpaper");
        } else if (lowerAction === "pomodoro") {
            CenterState.toggle("Pomodoro");
        } else if (lowerAction === "ai" || lowerAction === "aiagent" || lowerAction === "agent") {
            CenterState.toggle("AI Agent");
        } else if (lowerAction === "wifi" || lowerAction === "network") {
            QuickSettingsService.toggle("network");
        } else if (lowerAction === "bluetooth" || lowerAction === "bt") {
            QuickSettingsService.toggle("bluetooth");
        } else if (lowerAction === "volume" || lowerAction === "audio") {
            QuickSettingsService.toggle("volume");
        } else if (lowerAction === "powerprofile" || lowerAction === "prof") {
            QuickSettingsService.toggle("powerprofile");
        } else if (lowerAction === "battery" || lowerAction === "pwr") {
            QuickSettingsService.toggle("battery");
        } else if (lowerAction === "power" || lowerAction === "sys") {
            QuickSettingsService.toggle("power");
        } else if (lowerAction === "settings" || lowerAction === "config") {
            settingsVisible = !settingsVisible;
        } else if (lowerAction === "close" || lowerAction === "close_all") {
            MenuService.closeAll();
            DynamicIslandService.close();
        }
    }

    DismissOverlay {
        id: dismissOverlay
    }

    Connections {
        target: HyprlandService
        function onIsFullscreenChanged() {
            if (HyprlandService.isFullscreen) {
                MenuService.closeAll();
                DynamicIslandService.close();
            }
        }
    }

    Bar {
        id: bar
        controlCenterMenuRef: controlCenterMenu
    }

    ControlCenter {
        id: controlCenterMenu
        parentWindow: bar
        visible: CenterState.qsVisible
        Component.onCompleted: CenterState.menuRef = this
    }

    QuickSettingsMenu {
        id: quickSettingsMenu
        parentWindow: bar
        visible: QuickSettingsService.qsVisible
        Component.onCompleted: QuickSettingsService.menuRef = this
    }

    NotificationPopup {
        id: notificationPopup
    }

    OsdPopup {
        id: osdPopup
    }

    DynamicIslandOverlay {
        id: dynamicIslandOverlay
        visible: DynamicIslandService.active
    }

    Loader {
        id: settingsLoader
        active: settingsVisible
        sourceComponent: Component {
            SettingsWindow {
                Component.onCompleted: visible = true
                onVisibleChanged: {
                    if (!visible) settingsVisible = false;
                }
            }
        }
    }
}