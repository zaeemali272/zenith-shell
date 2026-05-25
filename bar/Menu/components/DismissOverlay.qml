import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../services"

PanelWindow {
    id: root

    // Cover the whole screen
    implicitWidth: screen ? screen.width : 1920
    implicitHeight: screen ? screen.height : 1080

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: MenuService.openMenus.length > 0

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: false // Ensure hover events pass through
        
        onClicked: (mouse) => {
            MenuService.closeAll();
            mouse.accepted = false; 
        }
    }
}
