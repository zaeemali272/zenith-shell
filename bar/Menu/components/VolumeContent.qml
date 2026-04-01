import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: 18

    Text {
        text: "Audio Control"
        color: Theme.fontColor
        font.bold: true
        font.pixelSize: 18
    }

    VolumeSlider {
        label: "Output"
        icon: VolumeService.btActive ? Theme.btIcon : ""
        value: VolumeService.outputVolume
        color: VolumeService.btActive ? Theme.bluetoothColor : Theme.fontColor
        Layout.fillWidth: true
        onChange: (v) => {
            setOut.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v / 100).toFixed(2)];
            setOut.running = true;
        }
    }

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

    Rectangle { Layout.fillWidth: true; height: 1; color: "#333" }

    RowLayout {
        Layout.fillWidth: true; spacing: 10
        Rectangle {
            Layout.fillWidth: true; height: 35; radius: 6
            color: VolumeService.muted ? Theme.accentColor : "#1a1a1a"
            Text { anchors.centerIn: parent; text: VolumeService.muted ? "Unmute Output" : "Mute Output"; color: "white"; font.pixelSize: 11 }
            MouseArea {
                anchors.fill: parent
                onClicked: { muteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]; muteProc.running = true; }
            }
        }
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
            label: name; icon: icon; value: volume; color: Theme.fontColor; Layout.fillWidth: true
            onChange: (v) => {
                setAppVol.command = ["pactl", "set-sink-input-volume", id, v + "%"];
                setAppVol.running = true;
            }
            Process { id: setAppVol }
        }
    }

    Process { id: muteProc }
    Process { id: setOut }
    Process { id: setMic }
}
