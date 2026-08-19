// services/CenterState.qml
import QtQuick
import Quickshell
import "../Settings"

pragma Singleton

Item {
    id: root

    property bool qsVisible: false
    property bool mediaVisible: false
    property var menuRef: null
    property var mediaPopupRef: null
    property string activeTab: "Default"
    // Sub-tool for the Focus tab: "Todo", "Roadmap" or "Timer".
    property string focusTool: "Todo"
    property rect anchorRect: Qt.rect(0, 0, 0, 0)

    onQsVisibleChanged: {
        if (qsVisible) {
            if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
            mediaVisible = false;
        }
    }

    function open(tab, rect) {
        let targetTab = (tab && tab !== "") ? tab : "Default";
        activeTab = targetTab;
        if (rect !== undefined) anchorRect = rect;
        
        if (typeof DynamicIslandService !== "undefined") DynamicIslandService.close();
        if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
        mediaVisible = false;
        
        qsVisible = true;
    }

    function toggleMedia(rect) {
        if (mediaVisible) {
            close();
        } else {
            close();
            if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
            if (rect !== undefined) anchorRect = rect;
            mediaVisible = true;
        }
    }

    function toggle(tab, rect) {
        let targetTab = (tab && tab !== "") ? tab : "Default";
        if (qsVisible && activeTab === targetTab) {
            close();
        } else {
            open(targetTab, rect);
        }
    }

    // Visibility is a binding: shell.qml declares
    //     ControlCenter      { visible: CenterState.qsVisible }
    //     QuickSettingsMenu  { visible: QuickSettingsService.qsVisible }
    // Assigning menuRef.visible here would overwrite that binding permanently,
    // after which the state flag still flips but the window stops following it.
    // Setting the flag is the whole job.
    function close() {
        qsVisible = false;
        mediaVisible = false;
    }
}
