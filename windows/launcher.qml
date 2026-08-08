import QtQuick
import Quickshell
import "../services"

Item {
    id: launcherRoot
    visible: false

    function toggle() {
        DynamicIslandService.toggle("launcher");
    }

    function open() {
        DynamicIslandService.open("launcher");
    }

    function close() {
        DynamicIslandService.close();
    }
}