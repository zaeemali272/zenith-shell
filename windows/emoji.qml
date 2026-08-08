import QtQuick
import Quickshell
import "../services"

Item {
    id: emojiRoot
    visible: false

    function toggle() {
        DynamicIslandService.toggle("emoji");
    }

    function open() {
        DynamicIslandService.open("emoji");
    }

    function close() {
        DynamicIslandService.close();
    }
}
