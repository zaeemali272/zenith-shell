// services/CenterState.qml
import QtQuick
import Quickshell
import "../Settings"

pragma Singleton

Item {
    id: root

    property bool qsVisible: false
    property string activeTab: "Default"
    // Sub-tool for the Focus tab: "Todo", "Roadmap", "Timer", or "Services".
    property string focusTool: "Todo"
    // Sub-tab for the Wallpaper page: "Wallpaper", "Themes", "Slideshow", "Animated"
    property string wallpaperSubTab: "Wallpaper"
    // Sub-tab index for Settings page: 0=General, 1=Bar, 2=Appearance, 3=Workspace, 4=Battery, 5=Media, 6=Hyprland, 7=Displays
    property int settingsSubTab: 0
    property rect anchorRect: Qt.rect(0, 0, 0, 0)

    function open(tab, rect) {
        let targetTab = (tab && tab !== "") ? tab : "Default";
        if (targetTab === "Theme" || targetTab === "Themes") {
            targetTab = "Wallpaper";
            wallpaperSubTab = "Themes";
        } else if (targetTab === "Display" || targetTab === "Displays" || targetTab === "Resolution" || targetTab === "Project") {
            targetTab = "Settings";
            settingsSubTab = 4;
        }
        activeTab = targetTab;
        if (rect !== undefined) anchorRect = rect;
        
        DynamicIslandService.close();
        QuickSettingsService.close();
        qsVisible = true;
    }

    function toggle(tab, rect) {
        let targetTab = (tab && tab !== "") ? tab : "Default";
        if (targetTab === "Theme" || targetTab === "Themes") {
            if (qsVisible && activeTab === "Wallpaper" && wallpaperSubTab === "Themes") {
                close();
                return;
            }
            open("Theme", rect);
            return;
        }
        if (targetTab === "Display" || targetTab === "Displays" || targetTab === "Resolution" || targetTab === "Project") {
            if (qsVisible && activeTab === "Settings" && settingsSubTab === 4) {
                close();
                return;
            }
            open("Display", rect);
            return;
        }
        if (qsVisible && activeTab === targetTab) {
            close();
        } else {
            open(targetTab, rect);
        }
    }

    // The menu binds MenuWindow.shown to this flag and owns its own
    // visibility (so the exit animation can finish). Setting the flag is the
    // whole job.
    function close() {
        qsVisible = false;
    }
}
