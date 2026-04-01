import QtQuick
import Quickshell

pragma Singleton

Item {
    id: root

    property bool qsVisible: false
    onQsVisibleChanged: console.log("QuickSettingsService visible changed to:", qsVisible)
    property bool isSticky: false // true if opened via click
    property string activeTab: "network" // network, bluetooth, power, volume, battery
    
    // Position tracking for the menu
    property rect anchorRect: Qt.rect(0, 0, 0, 0)

    Timer {
        id: hideTimer
        interval: 500
        onTriggered: {
            if (!isSticky) {
                console.log("QuickSettingsService hideTimer triggered, closing hover menu")
                qsVisible = false;
            }
        }
    }
    
    function open(tab, rect, sticky = false) {
        console.log("QuickSettingsService.open called:", tab, "sticky:", sticky);
        hideTimer.stop();
        if (qsVisible && activeTab === tab && isSticky && !sticky) {
            // Already open and sticky, hovering shouldn't change anything
            return;
        }
        
        activeTab = tab;
        anchorRect = rect;
        isSticky = sticky;
        qsVisible = true;
    }

    function toggle(tab, rect) {
        console.log("QuickSettingsService.toggle called:", tab, "visible:", qsVisible, "isSticky:", isSticky);
        hideTimer.stop();
        if (qsVisible && activeTab === tab) {
            if (isSticky) {
                qsVisible = false;
                isSticky = false;
            } else {
                isSticky = true;
                console.log("QuickSettingsService: converted hover to sticky");
            }
        } else {
            open(tab, rect, true);
        }
    }

    function startHideTimer() {
        if (!isSticky) {
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
