import QtQuick
import Quickshell
import "../services"

Item {
    id: clipboardRoot
    visible: false

    function toggle() {
        DynamicIslandService.toggle("clipboard");
    }

    function open() {
        DynamicIslandService.open("clipboard");
    }

    function close() {
        DynamicIslandService.close();
    }
}
