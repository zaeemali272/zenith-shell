//@ pragma UseQApplication
import QtQml 2.15
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "bar"
import "bar/Menu"
import "bar/Menu/components"
import "services"
import "windows" as Windows
import "Settings"

Scope {
// We need to reference these services to ensure they start listening for system events.
    readonly property var _notifications: NotificationService
    readonly property var _battery: BatteryService
    readonly property var _media: MediaPlayerService
    readonly property var _productivity: ProductivityService
    readonly property var _overview: OverviewService { id: overviewService }
    readonly property var _settings: SettingsService { id: settingsService }

    // --- IPC / COMMAND LISTENER ---
    // Listen for commands from external sources (scripts or other quickshell processes)
    // Commands are written to ~/.cache/zenith_command
    property string cmdPath: Quickshell.env("HOME") + "/.cache/zenith_command"
    
    Timer {
        id: ipcTimer
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            ipcReader.running = false;
            ipcReader.running = true;
        }
    }

    Process {
        id: ipcReader
        command: ["cat", cmdPath]
        stdout: StdioCollector {
            onStreamFinished: {
                let cmd = text.trim();
                if (cmd !== "") {
                    handleCommand(cmd);
                    ipcClearer.running = true;
                }
            }
        }
    }

    Process {
        id: ipcClearer
        command: ["sh", "-c", "> " + cmdPath]
    }

    function handleCommand(cmd) {
        console.log("[Zenith IPC]: Received command: " + cmd);
        let parts = cmd.split(":");
        let action = parts[0];
        let arg = parts.length > 1 ? parts[1] : "";

        if (action === "dashboard") {
            let tab = "Default";
            let lowerArg = arg.toLowerCase();
            if (lowerArg === "pomodoro") tab = "Pomodoro";
            else if (lowerArg === "wallpaper" || lowerArg === "wallpapers") tab = "Wallpaper";
            else if (lowerArg === "keybinds") tab = "Keybinds";
            else if (lowerArg === "user") tab = "User";
            
            // Toggle logic: If already open on the same tab, close it
            if (CenterState.qsVisible && CenterState.activeTab === tab) {
                CenterState.close();
            } else {
                CenterState.open(tab);
            }
        } else if (action === "quicksettings") {
            // Toggle logic: If already open on the same tab, close it
            if (QuickSettingsService.qsVisible && QuickSettingsService.activeTab === arg) {
                QuickSettingsService.close();
            } else {
                QuickSettingsService.open(arg || "network");
            }
        } else if (action === "close_all") {
            MenuService.closeAll();
        } else if (action === "toggle_dashboard") {
            CenterState.toggle();
        } else if (action === "Overview") {
            overviewService.toggle();
        } else if (action === "Settings") {
            settingsService.toggle();
        } else if (action === "Keybinds") {
            if (CenterState.qsVisible && CenterState.activeTab === "Keybinds") {
                CenterState.close();
            } else {
                CenterState.open("Keybinds");
            }
        } else if (action === "ActionLauncher") {
            if (CenterState.qsVisible && CenterState.activeTab === "Default") {
                CenterState.close();
            } else {
                CenterState.open("Default");
            }
        } else if (action === "toggle_quicksettings") {
            QuickSettingsService.toggle(arg || "network");
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
