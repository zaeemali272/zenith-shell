import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: Theme.scaled(25)
    Layout.fillWidth: true

    opacity: 0
    scale: 0.98
    Component.onCompleted: {
        entryAnim.start();
    }
    ParallelAnimation {
        id: entryAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; to: 1; duration: 500; easing.type: Theme.elasticEasing }
    }

    // --- Header ---
    RowLayout {
        Layout.fillWidth: true
        ColumnLayout {
            spacing: Theme.scaled(2); Layout.fillWidth: true
            Text { text: "AUDIO CONTROL"; color: Theme.blue; font.pixelSize: Theme.scaled(14); font.letterSpacing: 2; font.weight: Font.Black; opacity: 0.8 }
            Text { text: "OUTPUT & INPUT"; color: Theme.surface2; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold; font.letterSpacing: 1 }
        }
    }

    // Main Controls Row
    GridLayout {
        columns: (Theme.isSmallScreen && Theme.isPortrait) ? 1 : 2
        Layout.fillWidth: true; columnSpacing: Theme.scaled(15); rowSpacing: Theme.scaled(15)

        // Speaker Card
        Rectangle {
            Layout.fillWidth: true; height: Theme.scaled(160); color: Theme.menuBackground; radius: Theme.scaled(24); border.color: Theme.surface1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.scaled(18); spacing: Theme.scaled(15)
                VolumeSlider {
                    label: "OUTPUT"; icon: VolumeService.btActive ? "󰓃" : "󰓃"
                    value: VolumeService.outputVolume; sliderColor: Theme.blue
                    onChange: (v) => { setOut.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v / 100).toFixed(2)]; setOut.running = true; }
                }
                Rectangle {
                    Layout.fillWidth: true; height: Theme.scaled(40); radius: Theme.scaled(12)
                    color: VolumeService.muted ? Theme.powerRed : Theme.backgroundColor; border.color: Theme.surface1
                    Text { 
                        anchors.centerIn: parent; text: VolumeService.muted ? "MUTED" : "ACTIVE"
                        color: VolumeService.muted ? "black" : Theme.text; font.weight: Font.Black; font.pixelSize: Theme.scaled(11); font.letterSpacing: 1
                    }
                    MouseArea { anchors.fill: parent; onClicked: { muteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]; muteProc.running = true; } }
                }

            }
        }

        // Mic Card
        Rectangle {
            Layout.fillWidth: true; height: Theme.scaled(160); color: Theme.menuBackground; radius: Theme.scaled(24); border.color: Theme.surface1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.scaled(18); spacing: Theme.scaled(15)
                VolumeSlider {
                    label: "INPUT"; icon: "󰍬"; value: VolumeService.micVolume; sliderColor: Theme.powerYellow
                    onChange: (v) => { setMic.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (v / 100).toFixed(2)]; setMic.running = true; }
                }
                Rectangle {
                    Layout.fillWidth: true; height: Theme.scaled(40); radius: Theme.scaled(12); color: Theme.menuBackground; border.color: Theme.surface1
                    Text { anchors.centerIn: parent; text: "MIC SETTINGS"; color: Theme.subtext0; font.weight: Font.Black; font.pixelSize: Theme.scaled(11); font.letterSpacing: 1 }
                }
            }
        }
    }

    // App volumes
    ColumnLayout {
        Layout.fillWidth: true; spacing: Theme.scaled(15); visible: VolumeService.appsModel.count > 0
        Text { text: "APPLICATIONS"; color: Theme.surface2; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; font.letterSpacing: 2 }

        GridLayout {
            columns: 2; Layout.fillWidth: true; columnSpacing: Theme.scaled(15); rowSpacing: Theme.scaled(15)
            Repeater {
                model: VolumeService.appsModel
                delegate: Rectangle {
                    Layout.fillWidth: true; height: Theme.scaled(130); color: Theme.menuBackground; radius: Theme.scaled(20); border.color: Theme.surface1
                    required property string name; required property int volume; required property int appId; required property string icon
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: Theme.scaled(15)
                        VolumeSlider {
                            label: name.toUpperCase(); icon: "󰓃"; value: volume; sliderColor: Theme.powerGreen
                            onChange: (v) => { setAppVol.command = ["pactl", "set-sink-input-volume", appId, v + "%"]; setAppVol.running = true; }
                            Process { id: setAppVol }
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
    Process { id: muteProc }
    Process { id: setOut }
    Process { id: setMic }
}