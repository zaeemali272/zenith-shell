//@ pragma UseQApplication
import QtQml 2.15
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "bar"
import "bar/Menu"
import "bar/Menu/components"
import "services"
import "Settings"

Scope {
    readonly property var _notifications: NotificationService
    readonly property var _battery: BatteryService
    readonly property var _media: MediaPlayerService
    readonly property var _productivity: ProductivityService

    // --- INSTANT IPC VIA NAMED PIPE (FIFO) ---
    property string cmdPath: Quickshell.env("HOME") + "/.cache/zenith_command"
    
    Process {
        id: ipcReader
        command: ["stdbuf", "-oL", "tail", "-n", "0", "-f", cmdPath]
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

        if (lowerAction === "dashboard" || lowerAction === "toggle_dashboard" || lowerAction === "actionlauncher" || lowerAction === "overview") {
            let tab = "Default";
            if (lowerArg === "pomodoro") tab = "Pomodoro";
            else if (lowerArg === "wallpaper" || lowerArg === "wallpapers") tab = "Wallpaper";
            CenterState.toggle(tab);
        } else if (lowerAction === "quicksettings" || lowerAction === "toggle_quicksettings") {
            let tab = arg || "network";
            QuickSettingsService.toggle(tab);
        } else if (lowerAction === "wallpaper" || lowerAction === "wallpapers") {
            CenterState.toggle("Wallpaper");
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
        } else if (lowerAction === "close" || lowerAction === "close_all") {
            MenuService.closeAll();
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
            }
        }
    }

    Bar {
        id: bar
        controlCenterMenuRef: controlCenter
    }

    ControlCenter {
        id: controlCenter
        parentWindow: bar
        Component.onCompleted: CenterState.menuRef = controlCenter
    }

    QuickSettingsMenu {
        id: quickSettingsMenu
        parentWindow: bar
        Component.onCompleted: QuickSettingsService.menuRef = quickSettingsMenu
    }

    NotificationPopup {
        id: notificationPopup
    }

    OsdPopup {
        id: osdPopup
    }
}