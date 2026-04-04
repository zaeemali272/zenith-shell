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

    onIsHoveringMenuChanged: {
        if (!isHoveringMenu) startHideTimer();
        else stopHideTimer();
    }

    onQsVisibleChanged: console.log(`[QuickSettingsService] Visible: ${qsVisible}, Sticky: ${isSticky}, Tab: ${activeTab}`)
    onIsStickyChanged: console.log(`[QuickSettingsService] Sticky changed: ${isSticky}`)
    
    Timer {
        id: hideTimer
        interval: 300
        onTriggered: {
            if (!isSticky && !isHoveringMenu) {
                console.log("[QuickSettingsService] hideTimer triggered - closing hover menu")
                qsVisible = false;
            }
        }
    }
    
    function open(tab, rect, sticky = false) {
        console.log(`[QuickSettingsService] open request: tab=${tab}, sticky=${sticky}`)
        hideTimer.stop();
        
        if (qsVisible && isSticky && !sticky) {
            return;
        }
        
        activeTab = tab;
        anchorRect = rect;
        isSticky = sticky;
        qsVisible = true;
    }

    function toggle(tab, rect) {
        console.log(`[QuickSettingsService] toggle request: tab=${tab}, currentVisible=${qsVisible}`)
        hideTimer.stop();
        
        if (qsVisible && activeTab === tab) {
            close();
        } else {
            open(tab, rect, true);
        }
    }

    function startHideTimer() {
        if (!isSticky && qsVisible && !isHoveringMenu) {
            hideTimer.restart();
        }
    }

    function stopHideTimer() {
        if (hideTimer.running) {
            console.log("[QuickSettingsService] stopHideTimer - mouse returned")
            hideTimer.stop();
        }
    }

    function close() {
        console.log("[QuickSettingsService] close explicitly called")
        qsVisible = false;
        isSticky = false;
        hideTimer.stop();
    }
}
