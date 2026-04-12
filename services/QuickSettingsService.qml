import QtQuick
import Quickshell
import "../Settings"

pragma Singleton

Item {
    id: root

    property var menuRef: null
    property bool qsVisible: false
    property bool isSticky: false 
    property bool isHoveringMenu: false
    property string activeTab: "network"
    property rect anchorRect: Qt.rect(0, 0, 0, 0)
    
    property bool _toggleLocked: false

    Timer {
        id: debounceTimer
        interval: 300 
        onTriggered: root._toggleLocked = false
    }

    onQsVisibleChanged: {
        if (qsVisible) {
            if (typeof CenterState !== "undefined") CenterState.close();
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
    
    function open(tab, rect) {
        activeTab = tab;
        anchorRect = rect;
        isSticky = true;
        if (menuRef) menuRef.visible = true;
    }

    function hoverOpen(tab, rect) {
        if (qsVisible || (typeof CenterState !== "undefined" && CenterState.qsVisible)) {
            open(tab, rect);
        }
    }

    function toggle(tab, rect) {
        if (_toggleLocked) return;
        _toggleLocked = true;
        debounceTimer.restart();

        if (qsVisible && activeTab === tab) {
            close();
        } else {
            open(tab, rect);
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
        isSticky = false;
        hideTimer.stop();
    }
}
