import ".."
import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

MouseArea {
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

    hoverEnabled: true
    implicitHeight: Theme.pillHeight
    implicitWidth: pill.width
    width: implicitWidth
    height: implicitHeight

    onContainsMouseChanged: {
        if (!containsMouse && (!tooltipMouse || !tooltipMouse.containsMouse)) hideTimer.start();
        else hideTimer.stop();
    }

    Pill {
        id: pill
        implicitHeight: Theme.pillHeight
        width: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        clip: true
        onClicked: {
            glancesExec.running = false;
            glancesExec.running = true;
        }

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

    // Tooltip Logic with Debounce to prevent flickering
    Timer {
        id: hideTimer
        interval: 150
        repeat: false
    }

    PopupWindow {
        id: tooltip
        visible: root.QsWindow && root.QsWindow.window && (root.containsMouse || (tooltipMouse && tooltipMouse.containsMouse) || hideTimer.running)
        
        // Ensure it anchors to the bar window
        anchor.window: root.QsWindow ? root.QsWindow.window : null
        
        // Use a stable rect that doesn't jump to 0,0 when hidden
        anchor.rect: {
            if (!root.QsWindow || !root.QsWindow.window || root.width <= 0) return Qt.rect(0, 0, 0, 0);
            
            const p = root.mapToItem(null, 0, 0);
            const centerX = p.x + (root.width / 2);
            const targetX = centerX - (tooltip.implicitWidth / 2);
            
            const winWidth = root.QsWindow.window.width;
            const winHeight = root.QsWindow.window.height;
            const boundedX = Math.max(10, Math.min(winWidth - tooltip.implicitWidth - 10, targetX));
            
            // Anchor to the bottom edge of the bar window (y=winHeight)
            return Qt.rect(Math.round(boundedX), winHeight, tooltip.implicitWidth, 0);
        }

        // Use Bottom edges to push it below the widget
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom 
        
        implicitWidth: 450
        implicitHeight: mainLayout.implicitHeight + 40
        color: "transparent"

        // Allow hovering into the tooltip
        MouseArea {
            id: tooltipMouse
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: {
                if (!containsMouse && !root.containsMouse) hideTimer.start();
                else hideTimer.stop();
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            color: "#181825"
            border.color: "#313244"
            border.width: 1
            radius: 8
            // ... (rest of the content)

            ColumnLayout {
                id: mainLayout
                anchors.fill: parent
                anchors.margins: 15
                spacing: 12

                Text {
                    text: `${root.arch} / Linux ${root.kernel} IP ${root.ip}`
                    color: "#cdd6f4"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                }

                RowLayout {
                    Text { text: root.cpuModel; color: "#cdd6f4"; font.family: "JetBrains Mono"; font.pixelSize: 12; Layout.fillWidth: true }
                    Text { text: root.freq; color: "#cdd6f4"; font.family: "JetBrains Mono"; font.pixelSize: 12 }
                }

                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    TooltipBar { label: "CPU "; value: root.cpu; color: Theme.cpuColor }
                    TooltipBar { label: "MEM "; value: root.mem; color: Theme.memColor }
                    TooltipBar { label: "LOAD"; value: root.loadPerc; displayValue: root.load.toFixed(1) + "%"; color: Theme.tempColor }
                    TooltipBar { label: "FS  "; value: root.fs; color: "#fab387" }
                }

                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    visible: root.coreUsages.length > 0

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#313244" }
                    Text { text: "PER CORE USAGE"; color: "#6e738d"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true }

                    GridLayout {
                        columns: 2; columnSpacing: 20; rowSpacing: 4; Layout.fillWidth: true
                        Repeater {
                            model: root.coreUsages
                            delegate: TooltipBar {
                                Layout.fillWidth: true
                                label: "C" + index.toString().padEnd(2, ' ')
                                value: modelData
                                color: value > 80 ? Theme.criticalColor : (value > 50 ? Theme.lowColor : Theme.cpuColor)
                                barWidth: 10
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#313244"; visible: root.coreTemps.length > 0 }
                    Text { text: "PER CORE TEMPS"; color: "#6e738d"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; visible: root.coreTemps.length > 0 }

                    GridLayout {
                        columns: 4; columnSpacing: 10; rowSpacing: 4; Layout.fillWidth: true; visible: root.coreTemps.length > 0
                        Repeater {
                            model: root.coreTemps
                            delegate: Text {
                                text: "Core " + index + ": " + modelData + "°C"
                                color: modelData > 80 ? Theme.criticalColor : (modelData > 60 ? Theme.lowColor : Theme.tempColor)
                                font.family: "JetBrains Mono"; font.pixelSize: 11
                            }
                        }
                    }
                }
            }
        }
    }

    component TooltipBar: RowLayout {
        property string label
        property int value
        property string displayValue: value + "%"
        property color color
        property int barWidth: 20

        function makeBar(v, width) {
            let blocks = Math.round(Math.min(v, 100) / (100 / width));
            let bar = "[";
            for (let i = 0; i < width; i++) {
                bar += (i < blocks) ? "▪" : " ";
            }
            return bar + "]";
        }

        Text { text: label; color: "#cdd6f4"; font.family: "JetBrains Mono"; font.pixelSize: 12; Layout.preferredWidth: contentWidth }
        Text { text: makeBar(value, barWidth); color: parent.color; font.family: "JetBrains Mono"; font.pixelSize: 12; Layout.fillWidth: true }
        Text { text: displayValue.padStart(6, ' '); color: parent.color; font.family: "JetBrains Mono"; font.pixelSize: 12; Layout.preferredWidth: contentWidth; horizontalAlignment: Text.AlignRight }
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