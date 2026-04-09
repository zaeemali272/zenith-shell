import QtQuick
import Quickshell

pragma Singleton

Item {
    id: root

    property bool qsVisible: false
    property bool isSticky: false 
    property bool isHoveringMenu: false
    property string activeTab: "network"
    property rect anchorRect: Qt.rect(0, 0, 0, 0)
    
    property bool _toggleLocked: false
    Timer {
        id: debounceTimer
        interval: 500
        onTriggered: root._toggleLocked = false
    }

    onQsVisibleChanged: console.log(`[QuickSettingsService] qsVisible -> ${qsVisible}`)
    onIsStickyChanged: console.log(`[QuickSettingsService] isSticky -> ${isSticky}`)

    onIsHoveringMenuChanged: {
        console.log(`[QuickSettingsService] isHoveringMenu: ${isHoveringMenu}`)
        if (!isHoveringMenu) startHideTimer();
        else stopHideTimer();
    }

    Timer {
        id: hideTimer
        interval: 300
        onTriggered: {
            console.log(`[QuickSettingsService] hideTimer triggered! sticky=${isSticky}, hovering=${isHoveringMenu}`)
            if (!isSticky && !isHoveringMenu) {
                console.log("[QuickSettingsService] hideTimer closing menu")
                qsVisible = false;
            }
        }
    }
    
    function open(tab, rect) {
        console.log(`[QuickSettingsService] open(tab=${tab})`)
        hideTimer.stop();
        activeTab = tab;
        anchorRect = rect;
        isSticky = true;
        qsVisible = true;
    }

    function toggle(tab, rect) {
        if (_toggleLocked) {
            console.log("[QuickSettingsService] toggle ignored (debounced)")
            return;
        }
        _toggleLocked = true;
        debounceTimer.restart();

        console.log(`[QuickSettingsService] toggle(tab=${tab}, visible=${qsVisible}, activeTab=${activeTab})`)
        if (qsVisible && activeTab === tab) {
            close("toggle");
        } else {
            open(tab, rect);
        }
    }

    function startHideTimer() {
        if (!isSticky && qsVisible && !isHoveringMenu) {
            console.log("[QuickSettingsService] Starting hideTimer")
            hideTimer.restart();
        }
    }

    function stopHideTimer() {
        hideTimer.stop();
    }

    function close(reason = "unknown") {
        console.log(`[QuickSettingsService] close called by: ${reason}`)
        qsVisible = false;
        isSticky = false;
        hideTimer.stop();
    }
}
