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
    visible: MenuService.openMenus.length > 0 || DynamicIslandService.active



    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        
        onPressed: (mouse) => {
            // Closed explicitly here because this file imports the services and
            // MenuService does not. Every surface that can be open off a click
            // gets closed, whichever one the click actually landed outside of.
            MenuService.closeAll();
            DynamicIslandService.close();
            CenterState.close();
            QuickSettingsService.close();
        }
    }
}
