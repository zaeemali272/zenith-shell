import QtQuick
import Quickshell
import "../" as Shell
import "../" as Root

Item {
    id: root
    property var _win: null

    function toggle(index = -1) {
        if (!_win) {
            _win = settingsComponent.createObject(null);
        }
        if (_win) {
            if (index !== -1) {
                _win.currentIndex = index;
                _win.visible = true;
            } else {
                _win.visible = !_win.visible;
            }
        }
    }

    Component {
        id: settingsComponent
        Root.Settings { }
    }
}
