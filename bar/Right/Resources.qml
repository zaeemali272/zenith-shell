import ".."
import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

MouseArea {
    id: root

    property int cpu: 0
    property int mem: 0
    property int temp: 0

    hoverEnabled: true
    implicitHeight: Theme.pillHeight
    // MouseArea width follows the animated pill width
    implicitWidth: pill.width

    Pill {
        id: pill

        implicitHeight: Theme.pillHeight
        // Calculate the target width based on layout contents
        width: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        // Essential to hide text while the pill is shrinking/expanding
        clip: true

        RowLayout {
            id: content

            anchors.centerIn: parent
            spacing: Theme.pillSpacing

            ResourceItem {
                icon: ""
                value: root.cpu
                color: Theme.cpuColor
            }

            ResourceItem {
                icon: "|  "
                value: root.mem
                showAbove: 60
                color: Theme.memColor
            }

            ResourceItem {
                icon: "|  "
                value: root.temp
                suffix: "°C"
                showAbove: 85
                color: Theme.tempColor
            }

        }

        // --- SMOOTH PILL EXPANSION ---
        Behavior on width {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }

        }

    }

    Process {
        id: resourceExec

        command: ["bash", "-c", "$HOME/.config/quickshell/scripts/resources.sh"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.cpu = data.cpu ?? 0;
                    root.mem = data.mem ?? 0;
                    root.temp = data.temp ?? 0;
                } catch (e) {
                    console.warn("Resource parse failed:", text);
                }
            }
        }

    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            resourceExec.running = false;
            resourceExec.running = true;
        }
    }

    component ResourceItem: RowLayout {
        property string icon
        property int value
        property string suffix: "%"
        property color color
        property int showAbove: -1
        // Logic check
        readonly property bool active: showAbove < 0 || value > showAbove

        spacing: Theme.pillGap
        // Handling layout exclusion and visibility
        visible: active
        Layout.preferredWidth: active ? -1 : 0
        opacity: active ? 1 : 0

        Text {
            text: icon
            color: parent.color
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: value.toString().padStart(2, '0') + suffix
            color: parent.color
            font.pixelSize: Theme.fontSize
            Layout.alignment: Qt.AlignVCenter
        }

        // Smoothly fade text in/out
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }

        }

    }

}
