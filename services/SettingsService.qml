import QtQuick
import Quickshell
import "../" as Shell
import "../" as Root

Item {
    id: root
    property var _win: null

    function toggle() {
        if (!_win) {
            _win = settingsComponent.createObject(null);
        }
        if (_win) {
            _win.visible = !_win.visible;
        }
    }

    Component {
        id: settingsComponent
        Root.Settings { }
    }
}
