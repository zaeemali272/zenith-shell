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
    implicitWidth: pill.implicitWidth

    Pill {
        id: pill

        implicitHeight: Theme.pillHeight
        implicitWidth: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding

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
                showAbove: 50
                color: Theme.memColor
            }

            ResourceItem {
                icon: "|  "
                value: root.temp
                suffix: "°C"
                showAbove: 70
                color: Theme.tempColor
            }

        }

    }

    Process {
        id: resourceExec

        command: ["bash", "-c", "~/.config/quickshell/scripts/resources.sh"]

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
        property bool active: showAbove < 0 || value > showAbove

        spacing: Theme.pillGap
        visible: active // ← ACTUALLY remove from layout

        Text {
            text: icon
            color: parent.color
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: value + suffix
            color: parent.color
            font.pixelSize: Theme.fontSize
            Layout.alignment: Qt.AlignVCenter
        }

    }

}
