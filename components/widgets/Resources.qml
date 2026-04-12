import ".."
import "../../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../../"
import Quickshell.Io
import "../"
import "../../"
import Quickshell.Wayland
import "../"
import "../../"

Item {
    id: root

    property int cpu: 0
    property int mem: 0
    property int temp: 0
    property double load: 0.0
    property int loadPerc: 0
    property int fs: 0
    property string cpuModel: ""
    property string freq: ""
    property string arch: ""
    property string kernel: ""
    property string ip: ""
    property var coreUsages: []
    property var coreTemps: []

    Process {
        id: glancesExec
        command: ["kitty", "-e", "glances"]
    }

    implicitHeight: Theme.pillHeight
    implicitWidth: pill.width
    width: implicitWidth
    height: implicitHeight

    Pill {
        id: pill
        implicitHeight: Theme.pillHeight
        width: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        clip: true

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Theme.pillSpacing

            ResourceItem { icon: ""; value: root.cpu; color: Theme.cpuColor }
            ResourceItem { icon: "|  "; value: root.mem; showAbove: 60; color: Theme.memColor }
            ResourceItem { icon: "|  "; value: root.temp; suffix: "°C"; showAbove: 85; color: Theme.tempColor }
        }

        Behavior on width {
            NumberAnimation { duration: 400; easing.type: Easing.OutExpo }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: pill.color = pill.hoverColor
        onExited: pill.color = pill.normalColor
        onClicked: {
            QuickSettingsService.toggle("resources", root.mapToItem(null, 0, 0, root.width, root.height));
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
                    root.load = data.load ?? 0.0;
                    root.loadPerc = data.load_perc ?? 0;
                    root.fs = data.fs ?? 0;
                    root.cpuModel = data.cpu_model ?? "";
                    root.freq = data.freq ?? "";
                    root.arch = data.arch ?? "";
                    root.kernel = data.kernel ?? "";
                    root.ip = data.ip ?? "";
                    root.coreUsages = data.core_usages ?? [];
                    root.coreTemps = data.core_temps ?? [];
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 4000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: { resourceExec.running = false; resourceExec.running = true; }
    }

    component ResourceItem: RowLayout {
        property string icon
        property int value
        property string suffix: "%"
        property color color
        property int showAbove: -1
        readonly property bool active: showAbove < 0 || value > showAbove

        spacing: Theme.pillGap
        visible: active
        Layout.preferredWidth: active ? -1 : 0
        opacity: active ? 1 : 0

        Text { text: icon; color: parent.color; font.family: Theme.iconFont; font.pixelSize: Theme.iconSize; Layout.alignment: Qt.AlignVCenter }
        Text { text: value.toString().padStart(2, '0') + suffix; color: parent.color; font.pixelSize: Theme.fontSize; Layout.alignment: Qt.AlignVCenter }

        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
}
