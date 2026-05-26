import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."
import "../../../"
import "../../../services"

ColumnLayout {
    id: root
    spacing: Theme.scaled(28)
    Layout.fillWidth: true

    // --- Core Data ---
    property int cpu: 0
    property int mem: 0
    property int temp: 0
    property int fs: 0
    property var coreUsages: []

    // --- Backend Sync ---
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
                    root.fs = data.fs ?? 0;
                    root.coreUsages = data.core_usages ?? [];
                } catch (e) { console.log("Parse Error") }
            }
        }
    }

    Timer {
        interval: 2000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: { resourceExec.running = false; resourceExec.running = true; }
    }

    // --- Header ---
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "SYSTEM MONITOR"
            color: Theme.blue
            font.pixelSize: Theme.scaled(14)
            font.letterSpacing: 2
            font.weight: Font.Black
            opacity: 0.8
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface1; opacity: 0.4; Layout.leftMargin: Theme.scaled(10) }
    }

    // --- Main Stats Grid ---
    GridLayout {
        columns: 2
        Layout.fillWidth: true
        rowSpacing: Theme.scaled(20)
        columnSpacing: Theme.scaled(20)

        ResourceCard {
            Layout.fillWidth: true
            title: "PROCESSOR"; value: root.cpu; icon: ""; accent: Theme.blue; suffix: "%"
        }
        ResourceCard {
            Layout.fillWidth: true
            title: "MEMORY"; value: root.mem; icon: ""; accent: Theme.mauve; suffix: "%"
        }
        ResourceCard {
            Layout.fillWidth: true
            title: "THERMAL"; value: root.temp; icon: ""; accent: root.temp > 70 ? Theme.powerRed : Theme.green; suffix: "°C"
        }
        ResourceCard {
            Layout.fillWidth: true
            title: "STORAGE"; value: root.fs; icon: "󰋊"; accent: Theme.powerYellow; suffix: "%"
        }
    }

    // --- Detailed Cores (Liquid Logic Fixed) ---
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.scaled(15)
        
        Text {
            text: "LOGICAL CORES"
            color: Theme.surface2
            font.pixelSize: Theme.scaled(11)
            font.weight: Font.Bold
            font.letterSpacing: 1
            Layout.leftMargin: Theme.scaled(5)
        }

        Flow {
            id: coreFlow
            Layout.fillWidth: true
            spacing: Theme.scaled(10)

            Repeater {
                model: root.coreUsages
                delegate: Rectangle {
                    width: {
                        let cols = Theme.isSmallScreen ? (Theme.isPortrait ? 2 : 3) : 4;
                        return (coreFlow.width - (Theme.scaled(10) * (cols - 1))) / cols;
                    }
                    height: Theme.scaled(40)
                    radius: Theme.scaled(12)
                    border.width: 1
                    border.color: modelData > 70 ? Qt.alpha(Theme.powerRed, 0.4) : Theme.surface1
                    
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.mantle }
                        GradientStop { position: 1.0 - (modelData / 100); color: Theme.mantle }
                        GradientStop { position: 1.0 - (modelData / 100); color: Qt.alpha(modelData > 70 ? Theme.powerRed : Theme.blue, 0.15) }
                        GradientStop { position: 1.0; color: Qt.alpha(modelData > 70 ? Theme.powerRed : Theme.blue, 0.15) }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData + "%"
                        color: modelData > 70 ? Theme.powerRed : Theme.text
                        font.pixelSize: Theme.scaled(12)
                        font.weight: Font.Black
                        style: Text.Outline
                        styleColor: Theme.mantle 
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }

    // --- ResourceCard Component ---
    component ResourceCard: Rectangle {
        id: cardRoot
        property string title
        property int value
        property string suffix
        property string icon
        property color accent
        
        height: Theme.scaled(120)
        color: Theme.menuBackground
        radius: Theme.scaled(28)
        border.color: Theme.surface1
        border.width: 1

        Rectangle {
            anchors.fill: parent
            radius: Theme.scaled(28)
            opacity: 0.04
            gradient: Gradient {
                GradientStop { position: 0.0; color: cardRoot.accent }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(20)
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(12)
                Text { text: cardRoot.icon; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(24); color: cardRoot.accent }
                Text {
                    text: cardRoot.title
                    color: Theme.subtext0
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.Black
                    font.letterSpacing: 1.5
                    Layout.fillWidth: true
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(4)
                Text { text: cardRoot.value; color: Theme.text; font.pixelSize: Theme.scaled(32); font.weight: Font.Black }
                Text { text: cardRoot.suffix; color: cardRoot.accent; font.pixelSize: Theme.scaled(16); font.weight: Font.Bold; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: Theme.scaled(6) }
                
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(22); color: "transparent"; border.color: Theme.surface1; border.width: 3
                    Rectangle {
                        anchors.fill: parent; radius: Theme.scaled(22); color: Qt.alpha(cardRoot.accent, 0.1); border.color: cardRoot.accent; border.width: 3
                        opacity: Math.min(cardRoot.value / 100, 1.0)
                    }
                    Text { anchors.centerIn: parent; text: ""; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: cardRoot.accent; visible: cardRoot.value < 90 }
                }
            }
        }
    }
}
