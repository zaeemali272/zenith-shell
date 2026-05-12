import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../services"
import "./components"

PopupWindow {
    id: root
    property var parentWindow: null
    visible: false
    color: "transparent"
    
    anchor.window: parentWindow
    anchor.edges: Edges.Top | Edges.Right 
    // Position x offset to center on the center of the bar (roughly)
    anchor.rect: Qt.rect(parentWindow.width * 0.45 - implicitWidth/3, parentWindow.height + 10, 0, 0)
    
    implicitWidth: Theme.scaled(500)
    implicitHeight: Theme.scaled(180)

    // Auto-close on outer click
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.glassBackground
        radius: 24
        border.color: Theme.glassBorder
        border.width: 1
        clip: true
        
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
