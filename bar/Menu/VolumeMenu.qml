// bar/Menu/VolumeMenu.qml
import "../.."
import "../../services"
import "./components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: menuRoot

    property var anchorItem: null

    visible: false
    color: "transparent"
    implicitWidth: 280
    implicitHeight: content.implicitHeight + 35
    anchor.window: anchorItem ? anchorItem.QsWindow.window : null
    anchor.rect: anchorItem ? anchorItem.mapToItem(null, 0, 0, anchorItem.width, anchorItem.height) : Qt.rect(0, 0, 0, 0)
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    // No more manual "get" processes on visible.
    // The Service is already listening for changes.
    onVisibleChanged: {
        if (visible) {
            VolumeService.update();
            focusTimer.start();
        }
    }

    Timer {
        id: focusTimer

        interval: 10
        onTriggered: mainRect.forceActiveFocus()
    }

    HyprlandFocusGrab {
        active: menuRoot.visible
        onCleared: menuRoot.visible = false
    }

    Rectangle {
        id: mainRect

        anchors.fill: parent
        anchors.margins: 5
        radius: 12
        color: Theme.backgroundColor || "#111111"
        border.color: Theme.borderColor
        border.width: 1
        clip: true
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape)
                menuRoot.visible = false;

        }

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 15
            spacing: 18

            Text {
                text: "Audio Control"
                color: Theme.fontColor
                font.bold: true
                font.pixelSize: 16
            }

            // --- Output Volume (Linked to Service) ---
            VolumeSlider {
                label: "Output"
                icon: VolumeService.btActive ? Theme.btIcon : ""
                value: VolumeService.outputVolume
                color: VolumeService.btActive ? Theme.bluetoothColor : Theme.fontColor
                Layout.fillWidth: true
                onChange: (v) => {
                    // Update system
                    setOut.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v / 100).toFixed(2)];
                    setOut.running = true;
                }
            }

            // --- Mic Volume (Linked to Service) ---
            VolumeSlider {
                label: "Microphone"
                icon: ""
                value: VolumeService.micVolume
                color: Theme.fontColor
                Layout.fillWidth: true
                onChange: (v) => {
                    setMic.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (v / 100).toFixed(2)];
                    setMic.running = true;
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#333"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    height: 35
                    radius: 6
                    color: VolumeService.muted ? Theme.accentColor : "#1a1a1a"

                    Text {
                        anchors.centerIn: parent
                        text: VolumeService.muted ? "Unmute Output" : "Mute Output"
                        color: "white"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            muteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
                            muteProc.running = true;
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#333"
                visible: VolumeService.appsModel.count > 0
            }

            Text {
                visible: VolumeService.appsModel.count > 0
                text: "Apps"
                color: Theme.fontColor
                font.bold: true
                font.pixelSize: 14
            }

            Repeater {
                model: VolumeService.appsModel

                delegate: VolumeSlider {
                    required property string name
                    required property int volume
                    required property int id
                    required property string icon

                    label: name
                    // Map generic icon if needed, or use model's icon
                    icon: icon
                    value: volume
                    color: Theme.fontColor
                    Layout.fillWidth: true
                    onChange: (v) => {
                        setAppVol.command = ["pactl", "set-sink-input-volume", id, v + "%"];
                        setAppVol.running = true;
                    }

                    Process {
                        id: setAppVol
                    }

                }

            }
        }

    }

    // Only Action Processes remain.
    // Data fetching is handled entirely by VolumeService.
    Process {
        id: muteProc
    }

    Process {
        id: setOut
    }

    Process {
        id: setMic
    }

}
