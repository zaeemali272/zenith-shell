import QtQuick
import Quickshell
import "../windows"

Item {
    id: root
    property var _win: null

    function toggle() {
        if (!_win) {
            _win = overviewComponent.createObject(null);
        }
        if (_win) {
            _win.toggle();
        }
    }

    Component {
        id: overviewComponent
        Overview {}
    }
}
