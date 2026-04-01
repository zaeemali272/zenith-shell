import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 12

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

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
            text: "Bluetooth"
            color: Theme.fontColor
            font.bold: true
            font.pixelSize: 18
            Layout.fillWidth: true
        }

        // Scan Button
        MouseArea {
            width: 32; height: 32
            visible: BluetoothService.powered
            onClicked: BluetoothService.toggleScan()
            Text {
                id: scanIcon
                anchors.centerIn: parent
                text: "󰑐"
                font.family: Theme.iconFont
                color: (BluetoothService.scanning || BluetoothService.busy) ? Theme.accentColor : Theme.fontColor
                
                RotationAnimation on rotation {
                    duration: 1000
                    loops: Animation.Infinite
                    running: (BluetoothService.scanning || BluetoothService.busy)
                    from: 0
                    to: 360
                }
            }
        }

        // Power Toggle
        MouseArea {
            width: 32; height: 32
            onClicked: BluetoothService.togglePower()
            Text {
                anchors.centerIn: parent
                text: BluetoothService.powered ? "󰂯" : "󰂲"
                font.family: Theme.iconFont
                font.pixelSize: 20
                color: BluetoothService.powered ? Theme.accentColor : "#555"
            }
        }
    }

    // Status message when powered off
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !BluetoothService.powered

        Text {
            anchors.centerIn: parent
            text: "Bluetooth is powered off"
            color: "#666"
        }
    }

    // Device List
    ListView {
        id: deviceList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: BluetoothService.devices
        visible: BluetoothService.powered
        spacing: 8
        clip: true

        delegate: Rectangle {
            width: deviceList.width
            height: 55
            color: connected ? "#1a1a1a" : (hoverArea.containsMouse ? "#111" : "transparent")
            radius: 8
            border.color: connected ? Theme.accentColor : "transparent"
            border.width: 1

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (connected) BluetoothService.action("disconnect", address);
                    else if (paired) BluetoothService.action("connect", address);
                    else BluetoothService.action("pair", address);
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                Text {
                    text: getDeviceIcon(icon)
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                    color: connected ? Theme.accentColor : Theme.fontColor
                }

                Column {
                    Layout.fillWidth: true
                    Text {
                        text: name
                        color: Theme.fontColor
                        elide: Text.ElideRight
                        font.bold: connected
                    }
                    Text {
                        text: {
                            if (connected) return "Connected";
                            if (paired) return "Paired";
                            return "Available (Not Paired)";
                        }
                        color: connected ? Theme.accentColor : (paired ? "#888" : Theme.yellow)
                        font.pixelSize: 10
                    }
                }

                // Remove Button
                MouseArea {
                    width: 24; height: 24
                    onClicked: BluetoothService.action("remove", address)
                    Text {
                        anchors.centerIn: parent
                        text: "󰆴"
                        font.family: Theme.iconFont
                        color: "#ee99a0"
                    }
                }
            }
        }
    }
}
