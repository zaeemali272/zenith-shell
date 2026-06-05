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
    WlrLayershell.namespace: "dismiss_overlay"
    WlrLayershell.anchors.top: true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left: true
    WlrLayershell.anchors.right: true

    color: "transparent"
    visible: MenuService.openMenus.length > 0

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        
        onPressed: (mouse) => {
            console.log("[DismissOverlay] Clicked, closing all menus");
            MenuService.closeAll();
            // Don't accept the event so it can pass through to what's beneath
            mouse.accepted = false; 
        }
    }
}
