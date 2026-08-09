// services/QuickSettingsService.qml
import QtQuick
import Quickshell
import "./"

pragma Singleton

Item {
    id: service

    property bool qsVisible: false
    property var menuRef: null
    property string activeTab: "network"
    property rect lastRect: Qt.rect(0, 0, 0, 0)

    onQsVisibleChanged: Variables.quickSettingsOpen = qsVisible

    function open(tab, rect) {
        if (typeof CenterState !== "undefined") {
            CenterState.close();
        }
        if (typeof DynamicIslandService !== "undefined") {
            DynamicIslandService.close();
        }

        if (tab && tab !== "") {
            activeTab = tab;
        }

        if (rect && rect.width > 0) {
            lastRect = rect;
        }

        qsVisible = true;
        if (menuRef) {
            menuRef.visible = true;
        }
    }

    function toggle(tab, rect) {
        let targetTab = (tab && tab !== "") ? tab : "network";
        if (qsVisible && activeTab === targetTab) {
            close();
        } else {
            open(targetTab, rect);
        }
    }

    function close() {
        qsVisible = false;
        if (menuRef) {
            menuRef.visible = false;
        }
    }
}
