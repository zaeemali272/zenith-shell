import "../../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: 20
    Layout.fillWidth: true

    Text {
        text: "Power Options"
        color: "white"
        font.bold: true
        font.pixelSize: 22
    }

    GridLayout {
        columns: 2
        Layout.fillWidth: true
        rowSpacing: 15
        columnSpacing: 15

        Repeater {
            model: [
                { icon: "󰐥", label: "Shutdown", cmd: "shutdown now", color: "#f38ba8" },
                { icon: "󰑐", label: "Reboot", cmd: "reboot", color: "#89b4fa" },
                { icon: "󰤄", label: "Suspend", cmd: "systemctl suspend", color: "#fab387" },
                { icon: "󰗼", label: "Logout", cmd: "hyprctl dispatch exit", color: "#a6e3a1" }
            ]

            delegate: Rectangle {
                id: powerBtn
                Layout.fillWidth: true
                height: 120
                color: "#1e1e2e"
                radius: 24
                border.color: m.containsMouse ? modelData.color : "#313244"
                border.width: m.containsMouse ? 2 : 1
                
                Behavior on border.color { ColorAnimation { duration: 200 } }

                MouseArea {
                    id: m
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        powerProc.command = ["sh", "-c", modelData.cmd];
                        powerProc.running = true;
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10
                    
                    Rectangle {
                        width: 48; height: 48; radius: 24
                        color: m.containsMouse ? modelData.color : "#2a2a32"
                        Layout.alignment: Qt.AlignHCenter
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: Theme.iconFont
                            font.pixelSize: 24
                            color: m.containsMouse ? "black" : modelData.color
                        }
                    }
                    
                    Text {
                        text: modelData.label
                        font.pixelSize: 14
                        font.bold: true
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }

    Process { id: powerProc }
}
