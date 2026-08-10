import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../.."
import "../../services"
import "./components"

PanelWindow {
    id: root
    property var parentWindow: null
    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "mediaplayer"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: mainContent
    }

    onVisibleChanged: {
        if (visible) {
            MenuService.register(root);
            mainContent.forceActiveFocus();
            showAnim.restart();
        } else {
            MenuService.unregister(root);
            mainContent.opacity = 0;
            mainContent.scale = 0.94;
            mainTranslate.y = -6;
        }
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: mainContent; property: "opacity"; from: 0; to: 1; duration: Theme.animNormal; easing.type: Theme.animEasing }
        NumberAnimation { target: mainContent; property: "scale"; from: 0.94; to: 1.0; duration: Theme.animNormal; easing.type: Theme.animEasing }
        NumberAnimation { target: mainTranslate; property: "y"; from: -6; to: 0; duration: Theme.animNormal; easing.type: Theme.animEasing }
    }

    // --- DISMISS ON OUTER CLICK ---
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: CenterState.close()
    }

    // Masterwork Material 3 Floating Media Card (Directly below media widget)
    Rectangle {
        id: mainContent
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Theme.barMarginTop + Theme.barHeight + Theme.scaled(4)

        width: Math.min(Theme.scaled(500), (screen ? screen.width : Theme.screenWidth) - Theme.scaled(20))
        height: Math.min(Theme.scaled(200), (screen ? screen.height : Theme.screenHeight) - Theme.barHeight - Theme.scaled(20))

        color: Theme.glassBackground
        radius: Theme.cardRadius
        border.color: Theme.glassBorder
        border.width: 1

        clip: true
        focus: true
        opacity: 0
        scale: 0.94
        transformOrigin: Item.Top

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) CenterState.close()
        }
        transform: Translate { id: mainTranslate; y: -6 }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(16)
            spacing: Theme.scaled(10)

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(8)
                Text { text: "󰎆"; font.family: Theme.iconFont; color: Theme.accentColor; font.pixelSize: Theme.scaled(14) }
                Text { text: "MEDIA PLAYER"; color: Theme.subtext0; font.pixelSize: Theme.scaled(9); font.weight: Font.Black; font.letterSpacing: 1 }
                
                Item { Layout.fillWidth: true }
                
                // Bubble Focus Toggle Button
                Rectangle {
                    width: Theme.scaled(40); height: Theme.scaled(22); radius: 999
                    color: MediaPlayerService.mediaFocus ? Theme.accentColor : Qt.rgba(255, 255, 255, 0.12)
                    border.width: 0
                    scale: toggleMouse.pressed ? 0.94 : (toggleMouse.containsMouse ? 1.03 : 1.0)

                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: MediaPlayerService.mediaFocus ? "󰖳" : "󰖲"
                        font.family: Theme.iconFont
                        color: MediaPlayerService.mediaFocus ? Colors.on_primary : "#ffffff"
                        font.pixelSize: 11
                    }
                    
                    MouseArea {
                        id: toggleMouse
                        anchors.fill: parent
                        hoverEnabled: true
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
