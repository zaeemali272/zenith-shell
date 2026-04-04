import QtQuick
import Quickshell

pragma Singleton

Item {
    id: root

    property bool qsVisible: false
    property bool isSticky: false
    property bool isHoveringMenu: false

    onIsHoveringMenuChanged: {
        if (!isHoveringMenu) startHideTimer();
        else stopHideTimer();
    }

    Timer {
        id: hideTimer
        interval: 300
        onTriggered: {
            if (!isSticky && !isHoveringMenu) {
                qsVisible = false;
            }
        }
    }

    function open(sticky = false) {
        hideTimer.stop();
        if (qsVisible && isSticky && !sticky) return;
        
        isSticky = sticky;
        qsVisible = true;
    }

    function toggle() {
        if (qsVisible) {
            close();
        } else {
            open(true);
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
        qsVisible = false;
        isSticky = false;
        hideTimer.stop();
    }
}
