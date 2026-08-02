import QtQuick
import Quickshell
import "./"

pragma Singleton

Item {
    id: service

    property bool qsVisible: false
    property string activeTab: "network"
    property var menuRef: null
    property rect lastRect: Qt.rect(0, 0, 0, 0)

    function open(tab, rect) {
        if (typeof CenterState !== "undefined") {
            CenterState.close();
        }

        if (tab && tab !== "") {
            activeTab = tab;
        }

        if (rect && rect.width > 0) {
            lastRect = rect;
        }

        if (menuRef) {
            menuRef.visible = true;
        }
        qsVisible = true;
    }

    function toggle(tab, rect) {
        if (qsVisible && activeTab === tab) {
            close();
        } else {
            open(tab, rect);
        }
    }

    function close() {
        if (menuRef) {
            menuRef.visible = false;
        }
        qsVisible = false;
    }
}
