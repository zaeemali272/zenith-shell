import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 20

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
        spacing: 15

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Text {
                text: "Bluetooth"
                color: "white"
                font.bold: true
                font.pixelSize: 22
            }
            Text {
                text: BluetoothService.powered ? (BluetoothService.scanning ? "Searching for devices..." : "Bluetooth is on") : "Bluetooth is off"
                color: "#a6adc8"
                font.pixelSize: 12
            }
        }

        // Scan Button
        Rectangle {
            width: 44; height: 44
            radius: 22
            color: "#1e1e2e"
            border.color: "#313244"
            visible: BluetoothService.powered
            
            Text {
                id: scanIcon
                anchors.centerIn: parent
                text: "󰑐"
                font.family: Theme.iconFont
                font.pixelSize: 20
                color: (BluetoothService.scanning || BluetoothService.busy) ? Theme.accentColor : "white"
                
                RotationAnimation on rotation {
                    duration: 1000
                    loops: Animation.Infinite
                    running: (BluetoothService.scanning || BluetoothService.busy)
                    from: 0
                    to: 360
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: BluetoothService.toggleScan()
            }
        }

        // Power Toggle
        Rectangle {
            width: 44; height: 44
            radius: 22
            color: BluetoothService.powered ? Theme.accentColor : "#1e1e2e"
            border.color: "#313244"
            
            Text {
                anchors.centerIn: parent
                text: BluetoothService.powered ? "󰂯" : "󰂲"
                font.family: Theme.iconFont
                font.pixelSize: 20
                color: BluetoothService.powered ? "black" : "#585b70"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: BluetoothService.togglePower()
            }
        }
    }

    // Status message when powered off
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !BluetoothService.powered

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 15
            
            Text {
                text: "󰂲"
                font.family: Theme.iconFont
                font.pixelSize: 64
                color: "#313244"
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "Bluetooth is disabled"
                color: "#6c7086"
                font.pixelSize: 16
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // Device List
    ListView {
        id: deviceList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: BluetoothService.devices
        visible: BluetoothService.powered
        spacing: 10
        clip: true

        delegate: Rectangle {
            width: deviceList.width
            height: 70
            color: "#1e1e2e"
            radius: 16
            border.color: connected ? Theme.accentColor : "#313244"
            border.width: connected ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 15

                Rectangle {
                    width: 46; height: 46
                    radius: 23
                    color: connected ? Theme.accentColor : "#2a2a32"
                    Text {
                        anchors.centerIn: parent
                        text: getDeviceIcon(icon)
                        font.family: Theme.iconFont
                        font.pixelSize: 22
                        color: connected ? "black" : "white"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: name
                        color: "white"
                        font.bold: true
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                    Text {
                        text: {
                            if (connected) return "Connected";
                            if (paired) return "Paired";
                            return "Available to pair";
                        }
                        color: connected ? Theme.accentColor : (paired ? "#a6adc8" : Theme.yellow)
                        font.pixelSize: 11
                    }
                }

                // Action Buttons
                RowLayout {
                    spacing: 8
                    
                    // Remove/Unpair Button
                    Rectangle {
                        width: 36; height: 36; radius: 18; color: "#313244"
                        Text { anchors.centerIn: parent; text: "󰆴"; font.family: Theme.iconFont; color: "#f38ba8"; font.pixelSize: 16 }
                        MouseArea { anchors.fill: parent; onClicked: BluetoothService.action("remove", address) }
                    }
                    
                    // Connect/Disconnect Toggle
                    Rectangle {
                        width: 100; height: 36; radius: 18
                        color: connected ? "#313244" : Theme.accentColor
                        Text { 
                            anchors.centerIn: parent; 
                            text: connected ? "Disconnect" : (paired ? "Connect" : "Pair"); 
                            color: connected ? "white" : "black"; 
                            font.bold: true; 
                            font.pixelSize: 11 
                        }
                        MouseArea { 
                            anchors.fill: parent; 
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
