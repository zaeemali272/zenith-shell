import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."

ColumnLayout {
    id: root
    spacing: Theme.scaled(25)
    Layout.fillWidth: true
    
    // Explicit sizing for ScrollView integration
    implicitHeight: mainLayout.implicitHeight

    property int selectedIndex: 5 

    // Reset selection every time the menu is opened
    onVisibleChanged: {
        if (visible) {
            selectedIndex = 5;
            mainLayout.forceActiveFocus();
        }
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        spacing: Theme.scaled(25)
        focus: true
        
        Keys.onPressed: (event) => {
            let cols = 2;
            let maxIdx = 5;
            if (event.key === Qt.Key_Right) selectedIndex = Math.min(selectedIndex + 1, maxIdx);
            else if (event.key === Qt.Key_Left) selectedIndex = Math.max(selectedIndex - 1, 0);
            else if (event.key === Qt.Key_Down) selectedIndex = Math.min(selectedIndex + cols, maxIdx);
            else if (event.key === Qt.Key_Up) selectedIndex = Math.max(selectedIndex - cols, 0);
            else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                let cmd = powerButtons.itemAt(selectedIndex).modelData.cmd;
                powerProc.command = ["sh", "-c", cmd];
                powerProc.running = true;
            }
        }

        Text {
            text: "SYSTEM SESSION"
            color: Theme.blue
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 2
            Layout.leftMargin: Theme.scaled(5)
        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            rowSpacing: Theme.scaled(12)
            columnSpacing: Theme.scaled(12)

            Repeater {
                id: powerButtons
                model: [
                    { icon: "󰌾", label: "LOCK",     cmd: "hyprlock --immediate-render --no-fade-in", color: Theme.lavender },
                    { icon: "󰒲", label: "BIOS",     cmd: "systemctl reboot --firmware-setup", color: Theme.mauve },
                    { icon: "󰗼", label: "LOGOUT",   cmd: "hyprctl dispatch exit", color: Theme.powerGreen },
                    { icon: "󰤄", label: "SUSPEND",  cmd: "systemctl suspend", color: Theme.lavender },
                    { icon: "󰑐", label: "REBOOT",   cmd: "reboot", color: Theme.blue },
                    { icon: "󰐥", label: "SHUTDOWN", cmd: "shutdown now", color: Theme.powerRed }
                ]

                delegate: Rectangle {
                    id: powerBtn
                    Layout.fillWidth: true
                    height: Theme.scaled(100)
                    anchors.margins: 2 
                    
                    property bool isSelected: index === root.selectedIndex
                    
                    color: isSelected ? Qt.rgba(1,1,1,0.1) : (m.containsMouse ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.2))
                    radius: Theme.scaled(20)
                    border.color: isSelected ? modelData.color : (m.containsMouse ? modelData.color : Theme.glassBorder)
                    border.width: 1
                    
                    scale: m.pressed ? 0.92 : (isSelected || m.containsMouse ? 1.00 : 0.95)
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    MouseArea {
                        id: m
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: root.selectedIndex = index
                        onClicked: { powerProc.command = ["sh", "-c", modelData.cmd]; powerProc.running = true; }
                    }

                    RowLayout {
                        anchors.centerIn: parent; spacing: 15
                        Rectangle {
                            width: 44; height: 44; radius: 12; color: Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.1)
                            Text { anchors.centerIn: parent; text: modelData.icon; font.family: Theme.iconFont; font.pixelSize: 22; color: modelData.color }
                        }
                        Text { text: modelData.label; font.pixelSize: 11; font.weight: Font.Black; color: Theme.text; opacity: 0.8 }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }

    Process { id: powerProc }
}
