import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: 25
    Layout.fillWidth: true

    // --- Header ---
    RowLayout {
        Layout.fillWidth: true
        ColumnLayout {
            spacing: 2; Layout.fillWidth: true
            Text { text: "AUDIO CONTROL"; color: "#89b4fa"; font.pixelSize: 14; font.letterSpacing: 2; font.weight: Font.Black; opacity: 0.8 }
            Text { text: "OUTPUT & INPUT"; color: "#585b70"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
        }
    }

    // Main Controls Row
    RowLayout {
        Layout.fillWidth: true; spacing: 15

        // Speaker Card
        Rectangle {
            Layout.fillWidth: true; height: 160; color: "#11111b"; radius: 24; border.color: "#313244"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 15
                VolumeSlider {
                    label: "OUTPUT"; icon: VolumeService.btActive ? "󰓃" : "󰓃" // Adjust icon logic if needed
                    value: VolumeService.outputVolume; sliderColor: "#89b4fa"
                    onChange: (v) => { setOut.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v / 100).toFixed(2)]; setOut.running = true; }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 40; radius: 12
                    color: VolumeService.muted ? "#f38ba8" : "#181825"; border.color: "#313244"
                    Text { 
                        anchors.centerIn: parent; text: VolumeService.muted ? "MUTED" : "ACTIVE"
                        color: VolumeService.muted ? "black" : "white"; font.weight: Font.Black; font.pixelSize: 11; font.letterSpacing: 1
                    }
                    MouseArea { anchors.fill: parent; onClicked: { muteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]; muteProc.running = true; } }
                }
            }
        }

        // Mic Card
        Rectangle {
            Layout.fillWidth: true; height: 160; color: "#11111b"; radius: 24; border.color: "#313244"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 15
                VolumeSlider {
                    label: "INPUT"; icon: "󰍬"; value: VolumeService.micVolume; sliderColor: "#fab387"
                    onChange: (v) => { setMic.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (v / 100).toFixed(2)]; setMic.running = true; }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 40; radius: 12; color: "#181825"; border.color: "#313244"
                    Text { anchors.centerIn: parent; text: "MIC SETTINGS"; color: "#a6adc8"; font.weight: Font.Black; font.pixelSize: 11; font.letterSpacing: 1 }
                }
            }
        }
    }

    // App volumes
    ColumnLayout {
        Layout.fillWidth: true; spacing: 15; visible: VolumeService.appsModel.count > 0
        Text { text: "APPLICATIONS"; color: "#585b70"; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 2 }

        GridLayout {
            columns: 2; Layout.fillWidth: true; columnSpacing: 15; rowSpacing: 15
            Repeater {
                model: VolumeService.appsModel
                delegate: Rectangle {
                    Layout.fillWidth: true; height: 130; color: "#11111b"; radius: 20; border.color: "#313244"
                    required property string name; required property int volume; required property int id; required property string icon
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 15
                        VolumeSlider {
                            label: name.toUpperCase(); icon: "󰓃"; value: volume; sliderColor: "#a6e3a1"
                            onChange: (v) => { setAppVol.command = ["pactl", "set-sink-input-volume", id, v + "%"]; setAppVol.running = true; }
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