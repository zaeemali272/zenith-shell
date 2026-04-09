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

    onQsVisibleChanged: console.log(`[CenterState] qsVisible -> ${qsVisible}`)
    onIsStickyChanged: console.log(`[CenterState] isSticky -> ${isSticky}`)

    onIsHoveringMenuChanged: {
        console.log(`[CenterState] isHoveringMenu: ${isHoveringMenu}`)
        if (!isHoveringMenu) startHideTimer();
        else stopHideTimer();
    }

    Timer {
        id: hideTimer
        interval: GeneralSettings.hideTimerInterval
        onTriggered: {
            console.log(`[CenterState] hideTimer triggered! sticky=${isSticky}, hovering=${isHoveringMenu}`)
            if (!isSticky && !isHoveringMenu) {
                console.log("[CenterState] hideTimer closing menu")
                qsVisible = false;
            }
        }
    }

    function open() {
        console.log("[CenterState] open()")
        hideTimer.stop();
        isSticky = true;
        qsVisible = true;
    }

    function toggle() {
        if (_toggleLocked) {
            console.log("[CenterState] toggle ignored (debounced)")
            return;
        }
        _toggleLocked = true;
        debounceTimer.restart();

        console.log(`[CenterState] toggle() - visible=${qsVisible}`)
        if (qsVisible) {
            close("toggle");
        } else {
            open();
        }
    }

    function startHideTimer() {
        if (!isSticky && qsVisible && !isHoveringMenu) {
            console.log("[CenterState] starting hideTimer")
            hideTimer.restart();
        }
    }

    function stopHideTimer() {
        hideTimer.stop();
    }

    function close(reason = "unknown") {
        console.log(`[CenterState] close called by: ${reason}`)
        qsVisible = false;
        isSticky = false;
        hideTimer.stop();
    }
}
