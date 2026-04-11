import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 25
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
        Layout.fillWidth: true; spacing: 15
        ColumnLayout {
            spacing: 2; Layout.fillWidth: true
            Text { text: "BLUETOOTH"; color: "#89b4fa"; font.pixelSize: 14; font.letterSpacing: 2; font.weight: Font.Black; opacity: 0.8 }
            Text { 
                text: BluetoothService.powered ? (BluetoothService.scanning ? "SCANNING..." : "ACTIVE") : "DISABLED"
                color: "#585b70"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1
            }
        }

        // Scan Button
        Rectangle {
            width: 48; height: 48; radius: 24; color: (scanMouse.containsMouse ? "#0a0a0a" : "#11111b"); border.color: BluetoothService.scanning ? "#f9e2af" : "#313244"; clip: true
            visible: BluetoothService.powered
            Behavior on color { ColorAnimation { duration: 200 } }
            Text {
                id: scanIcon; anchors.centerIn: parent; text: "󰑐"; font.family: Theme.iconFont; font.pixelSize: 20
                color: BluetoothService.scanning ? "#f9e2af" : "#a6e3a1"
            }
            RotationAnimation { target: scanIcon; running: BluetoothService.scanning; from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
            MouseArea { id: scanMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.toggleScan() }
        }

        // Power Button
        Rectangle {
            width: 48; height: 48; radius: 24; 
            color: BluetoothService.powered ? (powerMouse.containsMouse ? "#74a2f7" : "#89b4fa") : (powerMouse.containsMouse ? "#0a0a0a" : "#11111b")
            border.color: BluetoothService.powered ? "#89b4fa" : "#313244"
            Behavior on color { ColorAnimation { duration: 200 } }
            Text {
                anchors.centerIn: parent; text: BluetoothService.powered ? "󰂯" : "󰂲"
                font.family: Theme.iconFont; font.pixelSize: 20; color: BluetoothService.powered ? "black" : "#f38ba8"
            }
            MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.togglePower() }
        }
    }

    // --- Device List ---
    ListView {
        id: deviceList; Layout.fillWidth: true; Layout.fillHeight: true
        model: BluetoothService.devices; visible: BluetoothService.powered; spacing: 12; clip: true

        delegate: Rectangle {
            id: delegateRoot
            width: deviceList.width; height: 75; color: connected ? "#1e1e2e" : (delegateMouse.containsMouse ? "#0a0a0a" : "#11111b")
            radius: 20; border.color: connected ? "#89b4fa" : (delegateMouse.containsMouse ? "#45475a" : "#313244")
            border.width: connected ? 2 : 1
            
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

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
                anchors.fill: parent; anchors.margins: 12; spacing: 15
                
                Rectangle {
                    width: 44; height: 44; radius: 12; color: connected ? "#89b4fa" : "#181825"
                    Text { anchors.centerIn: parent; text: getDeviceIcon(icon); font.family: Theme.iconFont; font.pixelSize: 22; color: connected ? "black" : "white" }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    Text { text: name; color: "white"; font.weight: Font.Bold; font.pixelSize: 14; elide: Text.ElideRight }
                    Text { 
                        text: connected ? "CONNECTED" : (paired ? "PAIRED" : "READY")
                        color: connected ? "#89b4fa" : "#585b70"; font.pixelSize: 9; font.weight: Font.Black 
                    }
                }

                // --- Action Buttons (Right Aligned) ---
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    // Forget/Remove
                    Rectangle {
                        width: 40; height: 40; radius: 12; color: (forgetMouse.containsMouse ? "#0a0a0a" : "#181825"); border.color: "#313244"
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text { anchors.centerIn: parent; text: "󰆴"; font.family: Theme.iconFont; color: "#f38ba8"; font.pixelSize: 18 }
                        MouseArea { id: forgetMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.action("remove", address) }
                    }

                    // Connect/Disconnect Toggle Icon
                    Rectangle {
                        width: 40; height: 40; radius: 12; 
                        color: connected ? (actionMouse.containsMouse ? "#d25a6d" : "#f38ba8") : (actionMouse.containsMouse ? "#74a2f7" : "#89b4fa")
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text { 
                            anchors.centerIn: parent
                            text: connected ? "󱘖" : "󱘖" 
                            font.family: Theme.iconFont; color: "black"; font.pixelSize: 20 
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
