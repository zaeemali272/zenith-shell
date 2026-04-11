import QtQuick
import Quickshell
import "../Settings"

pragma Singleton

Item {
    id: root

    property bool qsVisible: false
    property bool isSticky: false
    property bool isHoveringMenu: false
    
    property bool _toggleLocked: false
    Timer {
        id: debounceTimer
        interval: GeneralSettings.debounceInterval
        onTriggered: root._toggleLocked = false
    }

    // Lock focus-based close for a short time after opening
    property bool _focusCloseLocked: false
    Timer {
        id: focusCloseLockTimer
        interval: 300
        onTriggered: root._focusCloseLocked = false
    }

    onQsVisibleChanged: {
        if (qsVisible) {
            _focusCloseLocked = true;
            focusCloseLockTimer.restart();
            // Close the other menu if it's open
            if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close("switch");
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
                qsVisible = false;
            }
        }
    }

    function open() {
        hideTimer.stop();
        isSticky = true;
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
            close("toggle");
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

    function close(reason = "unknown") {
        if (reason === "focus_cleared" && _focusCloseLocked) return;
        qsVisible = false;
        isSticky = false;
        hideTimer.stop();
    }
}
