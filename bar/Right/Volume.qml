// bar/Volume.qml
import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var menuRef: null
    // Binding directly to the Singleton Service
    readonly property int volume: VolumeService.outputVolume
    readonly property bool muted: VolumeService.muted
    readonly property bool btActive: VolumeService.btActive
    readonly property color activeColor: btActive ? Theme.bluetoothColor : Theme.fontColor
    readonly property bool micActive: VolumeService.micActive

    function volumeIcon(v, m) {
        if (m)
            return Theme.volMute;

        if (v >= 70)
            return Theme.volHigh;

        if (v >= 30)
            return Theme.volMid;

        return Theme.volLow;
    }

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: pill.width

    Pill {
        id: pill

        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: volumeContent.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                muteExec.running = false;
                muteExec.running = true;
            } else if (mouse.button === Qt.LeftButton) {
                QuickSettingsService.toggle("volume");
            }
        }

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                volUp.running = false;
                volUp.running = true;
            } else {
                volDown.running = false;
                volDown.running = true;
            }
            // Tell the service to refresh immediately for a snappy UI
            VolumeService.update();
        }

        RowLayout {
            id: volumeContent
            anchors.centerIn: parent
            spacing: Theme.pillGap

            // Microphone Indicator (Visible ONLY when active/capturing)
            Text {
                visible: root.micActive
                text: VolumeService.micMuted ? "\uf131" : "\uf130"
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                color: VolumeService.micMuted ? Theme.red : Theme.accentColor
            }

            Text {
                visible: root.btActive
                text: Theme.btIcon
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                color: root.activeColor
            }

            Text {
                visible: !root.btActive
                text: volumeIcon(root.volume, root.muted)
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                color: root.activeColor
            }

            Text {
                text: root.muted ? "Muted" : root.volume + "%"
                font.pixelSize: Theme.fontSize
                color: root.activeColor
            }
        }
    }

    // Actions stay here for simplicity, but they trigger a Service update
    Process {
        id: muteExec

        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }

    Process {
        id: volUp

        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]
    }

    Process {
        id: volDown

        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
    }
}