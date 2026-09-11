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
import "windows/lock"

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
        function mail(): void { handleCommand("mail"); }
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
    //
    // Hyprland-dots binds keys to these with hl.dsp.global("zenith:<name>"):
    // no script and no IPC client per keypress. A normal bind delivers
    // `pressed` when the chord goes down and `released` when it comes up, so
    // only one edge may toggle. The launcher is the exception: the Super tap
    // in keybinds.lua fires from a release bind, which delivers `released`
    // alone.
    Instantiator {
        model: ["dashboard", "wallpaper", "pomodoro", "volume",
                "close", "clipboard", "emoji", "power", "settings", "lock"]
        delegate: GlobalShortcut {
            required property string modelData
            appid: "zenith"
            name: modelData
            onPressed: handleCommand(modelData)
        }
    }
    GlobalShortcut { appid: "zenith"; name: "launcher"; onReleased: handleCommand("launcher") }

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
            else if (lowerArg === "roadmap" || lowerArg === "roadmaps") { tab = "Pomodoro"; CenterState.focusTool = "Roadmap"; }
            CenterState.toggle(tab);
        } else if (lowerAction === "quicksettings" || lowerAction === "toggle_quicksettings") {
            let tab = arg || "network";
            QuickSettingsService.toggle(tab);
        } else if (lowerAction === "mail" || lowerAction === "email" || lowerAction === "inbox") {
            CenterState.toggle("Mail");
        } else if (lowerAction === "wallpaper" || lowerAction === "wallpapers") {
            CenterState.toggle("Wallpaper");
        } else if (lowerAction === "roadmap" || lowerAction === "roadmaps") {
            // Roadmap lives inside the Focus tab now, alongside the todo list.
            CenterState.focusTool = "Roadmap";
            CenterState.toggle("Pomodoro");
        } else if (lowerAction === "pomodoro") {
            CenterState.toggle("Pomodoro");
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
        } else if (lowerAction === "lock") {
            LockService.lock();
        } else if (lowerAction === "settings" || lowerAction === "config") {
            settingsVisible = !settingsVisible;
        } else if (lowerAction === "close" || lowerAction === "close_all") {
            MenuService.closeAll();
        }
    }

    DismissOverlay {
        id: dismissOverlay
    }

    // MenuService.closeAll() is the one "close everything" entry point (bar
    // click, click outside, fullscreen, the `close` command). It only emits
    // the request; the services that own the surfaces are closed here, so
    // MenuService itself never has to import them.
    Connections {
        target: MenuService
        function onCloseRequested() {
            CenterState.close();
            QuickSettingsService.close();
            DynamicIslandService.close();
        }
    }

    Connections {
        target: HyprlandService
        function onIsFullscreenChanged() {
            if (HyprlandService.isFullscreen) MenuService.closeAll();
        }
    }

    Bar {
        id: bar
    }

    // Each menu binds its own `shown` to its service flag; MenuWindow owns
    // `visible` so the exit animation can finish before the surface unmaps.
    ControlCenter { id: controlCenterMenu }
    QuickSettingsMenu { id: quickSettingsMenu }

    NotificationPopup {
        id: notificationPopup
    }

    OsdPopup {
        id: osdPopup
    }

    LockScreen {
        id: lockScreen
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