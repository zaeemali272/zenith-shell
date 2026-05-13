import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../.."
import "../../services"
import "./components"

PopupWindow {
    id: root
    property var parentWindow: null
    visible: false
    color: "transparent"
    
    grabFocus: true

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: root.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            mainContent.forceActiveFocus();
            showAnim.restart();
        }
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: mainContent; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutQuint }
        NumberAnimation { target: mainContent; property: "scale"; from: 0.95; to: 1.0; duration: 500; easing.type: Easing.OutBack }
        NumberAnimation { target: mainTranslate; property: "y"; from: -20; to: 0; duration: 500; easing.type: Easing.OutBack }
    }

    anchor.window: parentWindow
    anchor.edges: Edges.Top | Edges.Right 
    // Position x offset to center on the center of the bar (roughly)
    anchor.rect: Qt.rect(parentWindow.width * 0.45 - implicitWidth/3, parentWindow.height + 10, 0, 0)
    
    implicitWidth: Theme.scaled(500)
    implicitHeight: Theme.scaled(180)

    Rectangle {
        id: mainContent
        anchors.fill: parent
        color: Theme.glassBackground
        radius: 24
        border.color: Theme.glassBorder
        border.width: 1
        clip: true
        focus: true

        opacity: 0
        scale: 0.95
        transform: Translate { id: mainTranslate; y: -20 }
        
        MouseArea {
            anchors.fill: parent
            onClicked: { /* Consume click */ }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            MprisPlayer {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
