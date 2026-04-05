import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."
import "../../../"
import "../../../services"

ColumnLayout {
    id: root
    spacing: 28
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
            font.pixelSize: 14
            font.letterSpacing: 2
            font.weight: Font.Black
            opacity: 0.8
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: "#313244"; opacity: 0.4; Layout.leftMargin: 10 }
    }

    // --- Main Stats Grid ---
    GridLayout {
        columns: 2
        Layout.fillWidth: true
        rowSpacing: 20
        columnSpacing: 20

        Repeater {
            model: [
                { t: "PROCESSOR", v: root.cpu,  i: "", a: "#89b4fa", s: "%" },
                { t: "MEMORY",    v: root.mem,  i: "", a: "#cba6f7", s: "%" },
                { t: "THERMAL",   v: root.temp, i: "", a: root.temp > 70 ? "#f38ba8" : "#94e2d5", s: "°C" },
                { t: "STORAGE",   v: root.fs,   i: "󰋊", a: "#fab387", s: "%" }
            ]
            
            delegate: ResourceCard {
                title: modelData.t
                value: modelData.v
                icon: modelData.i
                accent: modelData.a
                suffix: modelData.s
            }
        }
    }

    // --- Detailed Cores (Liquid Logic Fixed) ---
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 15
        
        Text {
            text: "LOGICAL CORES"
            color: "#585b70"
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1
            Layout.leftMargin: 5
        }

        GridLayout {
            columns: 4
            Layout.fillWidth: true
            rowSpacing: 10
            columnSpacing: 10

            Repeater {
    model: root.coreUsages
    delegate: Rectangle {
        Layout.fillWidth: true
        height: 40
        radius: 12
        border.width: 1
        border.color: modelData > 70 ? Qt.alpha("#f38ba8", 0.4) : "#313244"
        
        // We use a gradient to create the "fill" effect. 
        // This is part of the background, so it CANNOT leak.
        gradient: Gradient {
            // The "Empty" part (Top)
            GradientStop { 
                position: 0.0
                color: "#181825" 
            }
            GradientStop { 
                position: 1.0 - (modelData / 100)
                color: "#181825" 
            }
            // The "Fill" part (Bottom)
            GradientStop { 
                position: 1.0 - (modelData / 100) 
                color: Qt.alpha(modelData > 70 ? "#f38ba8" : "#89b4fa", 0.15)
            }
            GradientStop { 
                position: 1.0
                color: Qt.alpha(modelData > 70 ? "#f38ba8" : "#89b4fa", 0.15)
            }
        }

        // We remove the inner Rectangle entirely!

        Text {
            anchors.centerIn: parent
            text: modelData + "%"
            color: modelData > 70 ? "#f38ba8" : "#cdd6f4"
            font.pixelSize: 12
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
        
        Layout.fillWidth: true
        height: 120
        color: "#11111b"
        radius: 28
        border.color: "#313244"
        border.width: 1

        Rectangle {
            anchors.fill: parent
            radius: 28
            opacity: 0.04
            gradient: Gradient {
                GradientStop { position: 0.0; color: cardRoot.accent }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Text { text: cardRoot.icon; font.family: Theme.iconFont; font.pixelSize: 24; color: cardRoot.accent }
                Text {
                    text: cardRoot.title
                    color: "#6c7086"
                    font.pixelSize: 10
                    font.weight: Font.Black
                    font.letterSpacing: 1.5
                    Layout.fillWidth: true
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: cardRoot.value; color: "white"; font.pixelSize: 32; font.weight: Font.Black }
                Text { text: cardRoot.suffix; color: cardRoot.accent; font.pixelSize: 16; font.weight: Font.Bold; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 6 }
                
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 44; height: 44; radius: 22; color: "transparent"; border.color: "#313244"; border.width: 3
                    Rectangle {
                        anchors.fill: parent; radius: 22; color: Qt.alpha(cardRoot.accent, 0.1); border.color: cardRoot.accent; border.width: 3
                        opacity: Math.min(cardRoot.value / 100, 1.0)
                    }
                    Text { anchors.centerIn: parent; text: ""; font.family: Theme.iconFont; font.pixelSize: 14; color: cardRoot.accent; visible: cardRoot.value < 90 }
                }
            }
        }
    }
}