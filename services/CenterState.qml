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
            if (mediaPopupRef) mediaPopupRef.visible = false;
        }
    }

    function open(tab, rect) {
        let targetTab = (tab && tab !== "") ? tab : "Default";
        activeTab = targetTab;
        if (rect !== undefined) anchorRect = rect;
        
        if (typeof DynamicIslandService !== "undefined") DynamicIslandService.close();
        if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
        mediaVisible = false;
        if (mediaPopupRef) mediaPopupRef.visible = false;
        
        qsVisible = true;
        if (menuRef) menuRef.visible = true;
    }

    function toggleMedia(rect) {
        if (mediaVisible) {
            close();
        } else {
            close();
            if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
            if (rect !== undefined) anchorRect = rect;
            if (mediaPopupRef) mediaPopupRef.visible = true;
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

    function close() {
        qsVisible = false;
        mediaVisible = false;
        if (menuRef) menuRef.visible = false;
        if (mediaPopupRef) mediaPopupRef.visible = false;
    }
}
