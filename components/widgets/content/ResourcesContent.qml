import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import Quickshell.Io
import "../../"
import "../../.."
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
            color: "#89b4fa"
            font.pixelSize: Theme.scaled(14)
            font.letterSpacing: 2
            font.weight: Font.Black
            opacity: 0.8
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: "#313244"; opacity: 0.4; Layout.leftMargin: Theme.scaled(10) }
    }

    // --- Main Stats Grid ---
    GridLayout {
        columns: 2
        Layout.fillWidth: true
        rowSpacing: Theme.scaled(20)
        columnSpacing: Theme.scaled(20)

        ResourceCard {
            Layout.fillWidth: true
            title: "PROCESSOR"; value: root.cpu; icon: ""; accent: "#89b4fa"; suffix: "%"
        }
        ResourceCard {
            Layout.fillWidth: true
            title: "MEMORY"; value: root.mem; icon: ""; accent: "#cba6f7"; suffix: "%"
        }
        ResourceCard {
            Layout.fillWidth: true
            title: "THERMAL"; value: root.temp; icon: ""; accent: root.temp > 70 ? "#f38ba8" : "#94e2d5"; suffix: "°C"
        }
        ResourceCard {
            Layout.fillWidth: true
            title: "STORAGE"; value: root.fs; icon: "󰋊"; accent: "#fab387"; suffix: "%"
        }
    }

    // --- Detailed Cores (Liquid Logic Fixed) ---
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.scaled(15)
        
        Text {
            text: "LOGICAL CORES"
            color: "#585b70"
            font.pixelSize: Theme.scaled(11)
            font.weight: Font.Bold
            font.letterSpacing: 1
            Layout.leftMargin: Theme.scaled(5)
        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.scaled(10)

            Repeater {
                model: root.coreUsages
                delegate: Rectangle {
                    width: (root.width - Theme.scaled(70)) / 4
                    height: Theme.scaled(40)
                    radius: Theme.scaled(12)
                    border.width: 1
                    border.color: modelData > 70 ? Qt.alpha("#f38ba8", 0.4) : "#313244"
                    
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#181825" }
                        GradientStop { position: 1.0 - (modelData / 100); color: "#181825" }
                        GradientStop { position: 1.0 - (modelData / 100); color: Qt.alpha(modelData > 70 ? "#f38ba8" : "#89b4fa", 0.15) }
                        GradientStop { position: 1.0; color: Qt.alpha(modelData > 70 ? "#f38ba8" : "#89b4fa", 0.15) }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData + "%"
                        color: modelData > 70 ? "#f38ba8" : "#cdd6f4"
                        font.pixelSize: Theme.scaled(12)
                        font.weight: Font.Black
                        style: Text.Outline
                        styleColor: "#181825" 
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
        color: "#11111b"
        radius: Theme.scaled(28)
        border.color: "#313244"
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
                    color: "#6c7086"
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
                Text { text: cardRoot.value; color: "white"; font.pixelSize: Theme.scaled(32); font.weight: Font.Black }
                Text { text: cardRoot.suffix; color: cardRoot.accent; font.pixelSize: Theme.scaled(16); font.weight: Font.Bold; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: Theme.scaled(6) }
                
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(22); color: "transparent"; border.color: "#313244"; border.width: 3
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
