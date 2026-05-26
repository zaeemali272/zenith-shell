import QtQuick
import Quickshell
import "../Settings"

pragma Singleton

Item {
    id: root

    property var menuRef: null
    property var mediaPopupRef: null
    property bool qsVisible: false
    property bool isSticky: false
    property bool isHoveringMenu: false
    property string activeTab: "Default"
    
    property bool _toggleLocked: false

    Timer {
        id: debounceTimer
        interval: 300
        onTriggered: root._toggleLocked = false
    }

    onQsVisibleChanged: {
        if (qsVisible) {
            if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
        }
    }

    onIsHoveringMenuChanged: {
        if (!isHoveringMenu) startHideTimer();
        else stopHideTimer();
    }

    Timer {
        id: hideTimer
        interval: GeneralSettings.hideTimerInterval
        onTriggered: {
            if (!isSticky && !isHoveringMenu) {
                close();
            }
        }
    }

    function open() {
        isSticky = true;
        activeTab = "Default"; // Always reset to default tab
        
        // Ensure others are closed
        if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
        
        if (menuRef) menuRef.visible = true;
        qsVisible = true;
    }

    function hoverOpen() {
        if (qsVisible || (typeof QuickSettingsService !== "undefined" && QuickSettingsService.qsVisible)) {
            open();
        }
    }

    function toggle() {
        if (_toggleLocked) return;
        _toggleLocked = true;
        debounceTimer.restart();
        
        if (qsVisible) {
            close();
        } else {
            open();
        }
    }

    function startHideTimer() {
        if (!isSticky && qsVisible && !isHoveringMenu) {
            hideTimer.restart();
        }
    }

    function stopHideTimer() {
        hideTimer.stop();
    }

    function close() {
        if (menuRef) menuRef.visible = false;
        if (mediaPopupRef) mediaPopupRef.visible = false;
        isSticky = false;
        qsVisible = false;
        hideTimer.stop();
    }
}
