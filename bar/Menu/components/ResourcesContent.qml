import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."
import "../../../"
import "../../../services"

ColumnLayout {
    id: root
    spacing: 20
    Layout.fillWidth: true
    Layout.fillHeight: true

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
                } catch (e) {
                    console.log("Error parsing resource data:", e)
                }
            }
        }
    }

    Timer {
        interval: 3000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: { resourceExec.running = false; resourceExec.running = true; }
    }

    // Header / System Info
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 5
        
        Text {
            text: "System Resources"
            color: "white"
            font.pixelSize: 22
            font.bold: true
        }
        
        Text {
            text: `${root.arch} • ${root.kernel} • IP: ${root.ip}`
            color: "#a6adc8"
            font.pixelSize: 12
        }
    }

    // Main Stats
    RowLayout {
        Layout.fillWidth: true
        spacing: 15

        ResourceCard {
            title: "CPU"
            value: root.cpu
            icon: ""
            color: Theme.cpuColor
            Layout.fillWidth: true
        }

        ResourceCard {
            title: "Memory"
            value: root.mem
            icon: ""
            color: Theme.memColor
            Layout.fillWidth: true
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 15

        ResourceCard {
            title: "Temp"
            value: root.temp
            suffix: "°C"
            icon: ""
            color: Theme.tempColor
            Layout.fillWidth: true
        }

        ResourceCard {
            title: "Disk"
            value: root.fs
            icon: "󰋊"
            color: "#fab387"
            Layout.fillWidth: true
        }
    }

    // Per-core usages if available
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10
        visible: root.coreUsages.length > 0

        Text {
            text: "Per-Core Usage"
            color: "#bac2de"
            font.pixelSize: 14
            font.bold: true
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: root.coreUsages
                delegate: Rectangle {
                    width: (parent.width - 24) / 4
                    height: 35
                    color: "#1e1e2e"
                    radius: 8
                    border.color: "#313244"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        Text { text: "C" + index; color: "#6e738d"; font.pixelSize: 10; font.bold: true }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            color: "#313244"
                            radius: 2
                            Rectangle {
                                width: parent.width * (modelData / 100)
                                height: parent.height
                                color: modelData > 80 ? Theme.criticalColor : (modelData > 50 ? Theme.lowColor : Theme.cpuColor)
                                radius: 2
                            }
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true } // Spacer

    component ResourceCard: Rectangle {
        id: cardRoot
        property string title
        property int value
        property string suffix: "%"
        property string icon
        property color color
        
        height: 80
        color: "#1e1e2e"
        radius: 12
        border.color: "#313244"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: cardRoot.icon
                    font.family: Theme.iconFont
                    font.pixelSize: 18
                    color: cardRoot.color
                }
                Text {
                    text: cardRoot.title
                    color: "#a6adc8"
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
                Text {
                    text: cardRoot.value + cardRoot.suffix
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 6
                color: "#313244"
                radius: 3
                Rectangle {
                    width: parent.width * (cardRoot.value / 100)
                    height: parent.height
                    color: cardRoot.color
                    radius: 3
                    
                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
