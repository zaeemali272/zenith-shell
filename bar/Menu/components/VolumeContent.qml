import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: 20
    Layout.fillWidth: true

    Text {
        text: "Audio"
        color: "white"
        font.bold: true
        font.pixelSize: 22
    }

    // Main Output & Mic Controls in cards
    RowLayout {
        Layout.fillWidth: true
        spacing: 15

        Rectangle {
            Layout.fillWidth: true
            height: 140
            color: "#1e1e2e"
            radius: 18
            border.color: "#313244"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                
                VolumeSlider {
                    label: "Speaker Output"
                    icon: VolumeService.btActive ? Theme.btIcon : "󰓃"
                    value: VolumeService.outputVolume
                    sliderColor: Theme.accentColor
                    Layout.fillWidth: true
                    onChange: (v) => {
                        setOut.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v / 100).toFixed(2)];
                        setOut.running = true;
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 18
                    color: VolumeService.muted ? "#f38ba8" : "#313244"
                    Text { 
                        anchors.centerIn: parent; 
                        text: VolumeService.muted ? "Muted" : "Active"; 
                        color: VolumeService.muted ? "black" : "white"; 
                        font.bold: true; 
                        font.pixelSize: 12 
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { muteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]; muteProc.running = true; }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 140
            color: "#1e1e2e"
            radius: 18
            border.color: "#313244"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                
                VolumeSlider {
                    label: "Microphone"
                    icon: "󰍬"
                    value: VolumeService.micVolume
                    sliderColor: "#fab387" // Or some other distinct color
                    Layout.fillWidth: true
                    onChange: (v) => {
                        setMic.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (v / 100).toFixed(2)];
                        setMic.running = true;
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 18; color: "#313244"
                    Text { anchors.centerIn: parent; text: "Microphone Settings"; color: "white"; font.bold: true; font.pixelSize: 12 }
                }
            }
        }
    }

    // App volumes
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12
        visible: VolumeService.appsModel.count > 0

        Text {
            text: "Application Volumes"
            color: "#bac2de"
            font.bold: true
            font.pixelSize: 16
        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            columnSpacing: 15
            rowSpacing: 15

            Repeater {
                model: VolumeService.appsModel
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 110
                    color: "#1e1e2e"
                    radius: 16
                    border.color: "#313244"
                    
                    required property string name
                    required property int volume
                    required property int id
                    required property string icon

                    VolumeSlider {
                        anchors.fill: parent
                        anchors.margins: 15
                        label: name; icon: "󰓃"; value: volume; Layout.fillWidth: true
                        onChange: (v) => {
                            setAppVol.command = ["pactl", "set-sink-input-volume", id, v + "%"];
                            setAppVol.running = true;
                        }
                        Process { id: setAppVol }
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
