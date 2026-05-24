import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../services"

PanelWindow {
    id: root

    // Cover the whole screen
    implicitWidth: screen ? screen.width : 1920
    implicitHeight: screen ? screen.height : 1080

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    color: "transparent"
    visible: MenuService.openMenus.length > 0

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onClicked: (mouse) => {
            MenuService.closeAll();
            mouse.accepted = false; 
        }
    }
}
