import "../../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import Quickshell.Io
import "../../"

ColumnLayout {
    id: root
    spacing: Theme.scaled(20)
    Layout.fillWidth: true

    Text {
        text: "Power Options"
        color: "white"
        font.bold: true
        font.pixelSize: Theme.scaled(22)
        Layout.leftMargin: Theme.scaled(5)
    }

    GridLayout {
        columns: 2
        Layout.fillWidth: true
        rowSpacing: Theme.scaled(15)
        columnSpacing: Theme.scaled(15)

        Repeater {
            model: [
                { icon: "󰌾", label: "Lock",     cmd: "hyprlock --immediate-render --no-fade-in", color: "#b4befe" },
                { icon: "󰒲", label: "BIOS",     cmd: "systemctl reboot --firmware-setup", color: "#cba6f7" },
                { icon: "󰗼", label: "Logout",   cmd: "hyprctl dispatch exit", color: "#a6e3a1" },
                { icon: "󰤄", label: "Suspend",  cmd: "systemctl suspend", color: "#fab387" },
                { icon: "󰑐", label: "Reboot",   cmd: "reboot", color: "#89b4fa" },
                { icon: "󰐥", label: "Power",    cmd: "shutdown now", color: "#f38ba8" }
            ]

            delegate: Rectangle {
                id: powerBtn
                Layout.fillWidth: true
                height: Theme.scaled(120)
                color: "#1e1e2e"
                radius: Theme.scaled(24)
                
                // Border lights up on hover
                border.color: m.containsMouse ? modelData.color : "#313244"
                border.width: m.containsMouse ? 2 : 1
                
                // Smooth scale effect for that "modern" feel
                scale: m.pressed ? 0.95 : 1.0
                
                Behavior on border.color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

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
                    spacing: Theme.scaled(8)
                    
                    // Large Clean Icon (No Background)
                    Text {
                        text: modelData.icon
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(42) // Big icons as requested
                        color: modelData.color
                        Layout.alignment: Qt.AlignHCenter
                        
                        // Subtle opacity shift when not hovering
                        opacity: m.containsMouse ? 1.0 : 0.8
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                    
                    Text {
                        text: modelData.label
                        font.pixelSize: Theme.scaled(14)
                        font.bold: true
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                        opacity: m.containsMouse ? 1.0 : 0.7
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }

    Process { id: powerProc }
}