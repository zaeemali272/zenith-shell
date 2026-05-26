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
    
    grabFocus: false

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) root.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            MenuService.register(root);
            mainContent.forceActiveFocus();
            showAnim.restart();
        } else {
            MenuService.unregister(root);
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
    
    implicitWidth: Math.min(Theme.scaled(500), (screen ? screen.width : Theme.screenWidth) - 20)
    implicitHeight: Math.min(Theme.scaled(180), (screen ? screen.height : Theme.screenHeight) - Theme.barHeight - 20)

    Rectangle {
        id: mainContent
        anchors.fill: parent
        color: Theme.glassBackground
        radius: Theme.scaled(24)
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
            anchors.margins: Theme.scaled(20)
            spacing: Theme.scaled(10)

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(8)
                Text { text: "󰎆"; font.family: Theme.iconFont; color: Theme.blue; font.pixelSize: Theme.scaled(14) }
                Text { text: "MEDIA PLAYER"; color: Theme.subtext1; font.pixelSize: Theme.scaled(9); font.weight: Font.Black; font.letterSpacing: 1 }
                
                Item { Layout.fillWidth: true }
                
                // Toggle Button
                Rectangle {
                    width: Theme.scaled(40); height: Theme.scaled(20); radius: Theme.scaled(10)
                    color: MediaPlayerService.mediaFocus ? Theme.blue : Theme.surface1
                    
                    Text {
                        anchors.centerIn: parent
                        text: MediaPlayerService.mediaFocus ? "󰖳" : "󰖲"
                        font.family: Theme.iconFont
                        color: MediaPlayerService.mediaFocus ? Theme.base : Theme.text
                        font.pixelSize: 12
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: MediaPlayerService.mediaFocus = !MediaPlayerService.mediaFocus
                    }
                }
            }

            MprisPlayer {
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: root.visible
            }
        }
    }
}
