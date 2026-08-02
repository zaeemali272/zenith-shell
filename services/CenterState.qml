import QtQuick
import Quickshell
import "../Settings"

pragma Singleton

Item {
    id: root

    property var menuRef: null
    property var mediaPopupRef: null
    property bool qsVisible: false
    property bool mediaVisible: false
    property string activeTab: "Default"
    property rect anchorRect: Qt.rect(0, 0, 0, 0)

    onQsVisibleChanged: {
        if (qsVisible) {
            if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
            mediaVisible = false;
            if (mediaPopupRef) mediaPopupRef.visible = false;
        }
    }

    function open(tab, rect) {
        if (tab && tab !== "") activeTab = tab;
        else activeTab = "Default";
        if (rect !== undefined) anchorRect = rect;
        
        if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
        mediaVisible = false;
        if (mediaPopupRef) mediaPopupRef.visible = false;
        
        if (menuRef) menuRef.visible = true;
        qsVisible = true;
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
        let targetTab = tab || "Default";
        if (qsVisible && activeTab === targetTab) {
            close();
        } else {
            open(targetTab, rect);
        }
    }

    function close() {
        if (menuRef) menuRef.visible = false;
        if (mediaPopupRef) mediaPopupRef.visible = false;
        qsVisible = false;
        mediaVisible = false;
    }
}
