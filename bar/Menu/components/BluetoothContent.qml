import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.scaled(25)
    Layout.fillWidth: true

    function getDeviceIcon(iconName) {
        if (!iconName) return "󰂯";
        let low = iconName.toLowerCase();
        if (low.includes("audio-card")) return "󰓃";
        if (low.includes("audio-headset") || low.includes("headphone")) return "󰋋";
        if (low.includes("keyboard")) return "󰌌";
        if (low.includes("mouse")) return "󰍽";
        if (low.includes("phone")) return "󰏲";
        if (low.includes("display")) return "󰍹";
        if (low.includes("computer")) return "󰟀";
        return "󰂯";
    }

    // --- Header ---
    RowLayout {
        Layout.fillWidth: true; spacing: Theme.scaled(15)
        ColumnLayout {
            spacing: Theme.scaled(2); Layout.fillWidth: true
            Text { text: "BLUETOOTH"; color: Theme.blue; font.pixelSize: Theme.scaled(14); font.letterSpacing: 2; font.weight: Font.Black; opacity: 0.8 }
            Text { 
                text: BluetoothService.powered ? (BluetoothService.scanning ? "SCANNING..." : "ACTIVE") : "DISABLED"
                color: Theme.subtext1; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold; font.letterSpacing: 1
            }
        }

        // Scan Button
        Rectangle {
            width: Theme.scaled(48); height: Theme.scaled(48); radius: Theme.scaled(24); color: (scanMouse.containsMouse ? Colors.background : Theme.menuBackground); border.color: BluetoothService.scanning ? Theme.powerYellow : Theme.surface1; clip: true
            visible: BluetoothService.powered
            Behavior on color { ColorAnimation { duration: 200 } }
            Text {
                id: scanIcon; anchors.centerIn: parent; text: "󰑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(20)
                color: BluetoothService.scanning ? Theme.powerYellow : Theme.powerGreen
            }
            RotationAnimation { target: scanIcon; running: BluetoothService.scanning; from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
            MouseArea { id: scanMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.toggleScan() }
        }

        // Power Button
        Rectangle {
            width: Theme.scaled(48); height: Theme.scaled(48); radius: Theme.scaled(24); 
            color: BluetoothService.powered ? (powerMouse.containsMouse ? Theme.blue : Theme.blue) : (powerMouse.containsMouse ? Colors.background : Theme.menuBackground)
            border.color: BluetoothService.powered ? Theme.blue : Theme.surface1
            Behavior on color { ColorAnimation { duration: 200 } }
            Text {
                anchors.centerIn: parent; text: BluetoothService.powered ? "󰂯" : "󰂲"
                font.family: Theme.iconFont; font.pixelSize: Theme.scaled(20); color: BluetoothService.powered ? Colors.background : Theme.powerRed
            }
            MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.togglePower() }
        }
    }

    // --- Device List ---
    ListView {
        id: deviceList; Layout.fillWidth: true; Layout.fillHeight: true
        model: BluetoothService.devices; visible: BluetoothService.powered; spacing: Theme.scaled(12); clip: true

        delegate: Rectangle {
            id: delegateRoot
            width: deviceList.width; height: Theme.scaled(75); color: connected ? Theme.surface0 : (delegateMouse.containsMouse ? Colors.background : Theme.menuBackground)
            radius: Theme.scaled(20); border.color: connected ? Theme.blue : (delegateMouse.containsMouse ? Theme.surface2 : Theme.surface1)
            border.width: connected ? 2 : 1
            scale: delegateMouse.pressed ? 0.98 : 1.0
            
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            MouseArea {
                id: delegateMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (connected) BluetoothService.action("disconnect", address);
                    else if (paired) BluetoothService.action("connect", address);
                    else BluetoothService.action("pair", address);
                }
            }

            RowLayout {
                anchors.fill: parent; anchors.margins: Theme.scaled(12); spacing: Theme.scaled(15)
                
                Rectangle {
                    width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(12); color: connected ? Theme.blue : Theme.mantle
                    Text { anchors.centerIn: parent; text: getDeviceIcon(icon); font.family: Theme.iconFont; font.pixelSize: Theme.scaled(22); color: connected ? Colors.background : Theme.text }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    Text { text: name; color: Theme.text; font.weight: Font.Bold; font.pixelSize: Theme.scaled(14); elide: Text.ElideRight }
                    Text { 
                        text: connected ? "CONNECTED" : (paired ? "PAIRED" : "READY")
                        color: connected ? Theme.blue : Theme.subtext1; font.pixelSize: Theme.scaled(9); font.weight: Font.Black 
                    }
                }

                // --- Action Buttons (Right Aligned) ---
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: Theme.scaled(8)

                    // Forget/Remove
                    Rectangle {
                        width: Theme.scaled(40); height: Theme.scaled(40); radius: Theme.scaled(12); color: (forgetMouse.containsMouse ? Colors.background : Theme.mantle); border.color: Theme.surface1
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text { anchors.centerIn: parent; text: "󰆴"; font.family: Theme.iconFont; color: Theme.powerRed; font.pixelSize: Theme.scaled(18) }
                        MouseArea { id: forgetMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.action("remove", address) }
                    }

                    // Connect/Disconnect Toggle Icon
                    Rectangle {
                        width: Theme.scaled(40); height: Theme.scaled(40); radius: Theme.scaled(12); 
                        color: connected ? (actionMouse.containsMouse ? Theme.powerRed : Theme.powerRed) : (actionMouse.containsMouse ? Theme.blue : Theme.blue)
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text { 
                            anchors.centerIn: parent
                            text: connected ? "󱘖" : "󱘖" 
                            font.family: Theme.iconFont; color: Colors.background; font.pixelSize: Theme.scaled(20) 
                        }
                        MouseArea { 
                            id: actionMouse
                            anchors.fill: parent; 
                            hoverEnabled: true
                            onClicked: {
                                if (connected) BluetoothService.action("disconnect", address);
                                else if (paired) BluetoothService.action("connect", address);
                                else BluetoothService.action("pair", address);
                            }
                        }
                    }
                }
            }
        }
    }
}
