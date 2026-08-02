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
        command: ["tail", "-f", cmdPath]
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
        let action = parts[0];
        let arg = parts.length > 1 ? parts[1] : "";

        if (action === "dashboard" || action === "toggle_dashboard" || action === "ActionLauncher") {
            let tab = "Default";
            let lowerArg = arg.toLowerCase();
            
            if (lowerArg === "pomodoro") tab = "Pomodoro";
            else if (lowerArg === "wallpaper" || lowerArg === "wallpapers") tab = "Wallpaper";
            
            if (CenterState.qsVisible && CenterState.activeTab === tab) {
                CenterState.close();
            } else {
                CenterState.open(tab);
            }
        } else if (action === "quicksettings" || action === "toggle_quicksettings") {
            if (QuickSettingsService.qsVisible && QuickSettingsService.activeTab === arg) {
                QuickSettingsService.close();
            } else {
                QuickSettingsService.open(arg || "network");
            }
        } else if (action === "close_all") {
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