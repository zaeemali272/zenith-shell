import QtQuick
import Quickshell
import "../windows"

Item {
    id: root
    property var _win: null

    function toggle() {
        if (!_win) {
            _win = cheatsheetComponent.createObject(null);
        }
        if (_win) {
            _win.active = !_win.active;
        }
    }

    Component {
        id: cheatsheetComponent
        Cheatsheet {}
    }
}
