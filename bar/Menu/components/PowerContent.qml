import "../../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: 12

    Text {
        text: "System Power"
        font.pixelSize: 18
        font.bold: true
        color: Theme.fontColor
    }

    GridLayout {
        columns: 2
        Layout.fillWidth: true
        rowSpacing: 10
        columnSpacing: 10

        Repeater {
            model: [
                { icon: "󰐥", label: "Shutdown", cmd: "shutdown now" },
                { icon: "󰑐", label: "Reboot", cmd: "reboot" },
                { icon: "󰤄", label: "Suspend", cmd: "systemctl suspend" },
                { icon: "󰗼", label: "Logout", cmd: "hyprctl dispatch exit" }
            ]

            delegate: Rectangle {
                Layout.fillWidth: true
                height: 80
                color: m.containsMouse ? Theme.accentColor : "#1a1a1a"
                radius: 12

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
                    spacing: 4
                    Text {
                        text: modelData.icon
                        font.family: Theme.iconFont
                        font.pixelSize: 24
                        color: m.containsMouse ? "black" : "white"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: modelData.label
                        font.pixelSize: 12
                        color: m.containsMouse ? "black" : "white"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    Process { id: powerProc }
}
