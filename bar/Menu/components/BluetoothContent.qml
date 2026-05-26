import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.scaled(20)
    Layout.fillWidth: true
    implicitHeight: BluetoothService.serviceActive ? (mainCol.implicitHeight + (emptyState.visible ? emptyState.implicitHeight : 0)) : 250

    property bool showUnnamed: false

    Component.onCompleted: {
        BluetoothService.refresh();
    }

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

    ColumnLayout {
        id: mainCol
        Layout.fillWidth: true
        spacing: Theme.scaled(20)
        visible: BluetoothService.serviceActive

        // --- Header ---
        ColumnLayout {
            Layout.fillWidth: true; spacing: Theme.scaled(15)
            visible: BluetoothService.serviceActive

            RowLayout {
                Layout.fillWidth: true; spacing: Theme.scaled(15)
                ColumnLayout {
                    spacing: Theme.scaled(2); Layout.fillWidth: true
                    Text { text: "BLUETOOTH"; color: Theme.blue; font.pixelSize: Theme.scaled(14); font.letterSpacing: 2; font.weight: Font.Black; opacity: 0.8 }
                    Text { 
                        text: BluetoothService.powered ? BluetoothService.state.toUpperCase() : "DISABLED"
                        color: Theme.subtext1; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold; font.letterSpacing: 1
                    }
                }

                // Refresh Button
                Rectangle {
                    width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(22); color: (refreshMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"); border.color: BluetoothService.busy ? Theme.powerYellow : Theme.glassBorder; clip: true
                    visible: BluetoothService.powered
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        id: refreshIcon; anchors.centerIn: parent; text: "󰑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(18)
                        color: BluetoothService.busy ? Theme.powerYellow : Theme.powerGreen
                    }
                    RotationAnimation { target: refreshIcon; running: BluetoothService.busy; from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
                    MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.refresh() }
                }

                // Scan Button
                Rectangle {
                    width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(22); color: (scanMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"); border.color: BluetoothService.scanning ? Theme.powerYellow : Theme.glassBorder; clip: true
                    visible: BluetoothService.powered
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        id: scanIcon; anchors.centerIn: parent; text: "󰂰"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(18)
                        color: BluetoothService.scanning ? Theme.powerYellow : Theme.text
                    }
                    MouseArea { id: scanMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.toggleScan() }
                }

                // Power Button
                Rectangle {
                    width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(22); color: (powerMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"); border.color: BluetoothService.powered ? Theme.blue : Theme.powerRed; clip: true
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        anchors.centerIn: parent; text: BluetoothService.powered ? "󰂯" : "󰂲"
                        font.family: Theme.iconFont; font.pixelSize: Theme.scaled(18); color: BluetoothService.powered ? Theme.blue : Theme.powerRed
                    }
                    MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.togglePower() }
                }
            }

            // --- Settings Toggles ---
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(10)
                visible: BluetoothService.powered

                // Show Unnamed Toggle
                Rectangle {
                    Layout.fillWidth: true; height: Theme.scaled(40); radius: Theme.scaled(12); color: (unnamedMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"); border.color: root.showUnnamed ? Theme.blue : Theme.glassBorder; clip: true
                    RowLayout {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: root.showUnnamed ? "󰈈" : "󰈉"; font.family: Theme.iconFont; color: root.showUnnamed ? Theme.blue : Theme.text; font.pixelSize: Theme.scaled(14) }
                        Text { text: "UNNAMED"; color: Theme.text; font.pixelSize: Theme.scaled(8); font.weight: Font.Black; font.letterSpacing: 1 }
                    }
                    MouseArea { id: unnamedMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.showUnnamed = !root.showUnnamed }
                }

                // Startup Status Toggle
                Rectangle {
                    Layout.fillWidth: true; height: Theme.scaled(40); radius: Theme.scaled(12); 
                    color: (startupMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"); 
                    border.color: BluetoothService.isServiceEnabled ? Theme.powerGreen : Theme.powerRed; clip: true
                    RowLayout {
                        anchors.centerIn: parent; spacing: 8
                        Text { 
                            text: BluetoothService.isServiceEnabled ? "󰄬" : "󰅖"; 
                            font.family: Theme.iconFont; 
                            color: BluetoothService.isServiceEnabled ? Theme.powerGreen : Theme.powerRed; 
                            font.pixelSize: Theme.scaled(14) 
                        }
                        Text { 
                            text: "STARTUP"; 
                            color: Theme.text; font.pixelSize: Theme.scaled(8); font.weight: Font.Black; font.letterSpacing: 1 
                        }
                    }
                    MouseArea { 
                        id: startupMouse; anchors.fill: parent; hoverEnabled: true; 
                        onClicked: BluetoothService.toggleStartup() 
                    }
                }
            }

            // Current Connection Status Bar
            Rectangle {
                Layout.fillWidth: true; height: Theme.scaled(60); color: Qt.rgba(0,0,0,0.2); radius: Theme.scaled(16); 
                visible: BluetoothService.powered && BluetoothService.connectedName !== ""
                border.color: Theme.glassBorder
                RowLayout {
                    anchors.fill: parent; anchors.margins: Theme.scaled(12); spacing: Theme.scaled(15)
                    Rectangle { width: Theme.scaled(36); height: Theme.scaled(36); radius: Theme.scaled(10); color: Qt.rgba(1,1,1,0.05)
                        Text { anchors.centerIn: parent; text: getDeviceIcon(BluetoothService.connectedIcon); font.family: Theme.iconFont; font.pixelSize: Theme.scaled(18); color: Theme.blue }
                    }
                    ColumnLayout { spacing: 0; Layout.fillWidth: true
                        Text { text: BluetoothService.connectedName; color: Theme.text; font.weight: Font.Bold; font.pixelSize: Theme.scaled(13); elide: Text.ElideRight }
                        Text { 
                            text: BluetoothService.connectedAddress; color: Theme.surface2; font.pixelSize: Theme.scaled(9); font.weight: Font.Bold 
                        }
                    }
                    
                    // Disconnect Button
                    Rectangle {
                        width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: Qt.rgba(1,0,0,0.1); border.color: Theme.powerRed; border.width: 1
                        visible: BluetoothService.connectedAddress !== ""
                        Text { anchors.centerIn: parent; text: "󰤄"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.powerRed }
                        MouseArea { anchors.fill: parent; onClicked: BluetoothService.action("disconnect", BluetoothService.connectedAddress) }
                    }

                    ColumnLayout { spacing: 0; Layout.alignment: Qt.AlignRight; visible: BluetoothService.connectedBattery !== -1
                        Text { text: BluetoothService.connectedBattery + "%"; color: Theme.powerGreen; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; horizontalAlignment: Text.AlignRight }
                        Text { text: "BATTERY"; color: Theme.surface2; font.pixelSize: Theme.scaled(8); font.weight: Font.Black; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
        }

        // --- Device List ---
        ListView {
            id: deviceList
            Layout.fillWidth: true
            
            property var displayDevices: BluetoothService.devices.filter(d => d.hasName || root.showUnnamed || d.connected)
            
            Layout.preferredHeight: contentHeight
            visible: BluetoothService.powered && BluetoothService.serviceActive && displayDevices.length > 0
            model: displayDevices
            spacing: Theme.scaled(12)
            clip: true
            interactive: false

            delegate: Rectangle {
                id: delegateRoot
                width: deviceList.width; height: Theme.scaled(75); color: modelData.connected ? Theme.surface0 : (delegateMouse.containsMouse ? Colors.background : Theme.menuBackground)
                radius: Theme.scaled(20); border.color: modelData.connected ? Theme.blue : (delegateMouse.containsMouse ? Theme.surface2 : Theme.surface1)
                border.width: modelData.connected ? 2 : 1
                scale: delegateMouse.pressed ? 0.98 : 1.0
                
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

                MouseArea {
                    id: delegateMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (modelData.connected) BluetoothService.action("disconnect", modelData.address);
                        else BluetoothService.action("connect", modelData.address);
                    }
                }

                RowLayout {
                    anchors.fill: parent; anchors.margins: Theme.scaled(12); spacing: Theme.scaled(15)
                    
                    Rectangle {
                        width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(12); color: modelData.connected ? Theme.blue : Theme.mantle
                        Text { anchors.centerIn: parent; text: getDeviceIcon(modelData.icon); font.family: Theme.iconFont; font.pixelSize: Theme.scaled(22); color: modelData.connected ? Colors.background : Theme.text }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: modelData.name; color: Theme.text; font.weight: Font.Bold; font.pixelSize: Theme.scaled(14); elide: Text.ElideRight }
                        Text { 
                            text: modelData.connected ? "CONNECTED" : (modelData.paired ? "PAIRED" : "READY")
                            color: modelData.connected ? Theme.blue : Theme.subtext1; font.pixelSize: Theme.scaled(9); font.weight: Font.Black 
                        }
                    }

                    // --- Action Buttons (Right Aligned) ---
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: Theme.scaled(8)

                        // Forget/Remove
                        Rectangle {
                            width: Theme.scaled(40); height: Theme.scaled(40); radius: Theme.scaled(12); color: (forgetMouse.containsMouse ? Colors.background : Theme.mantle); border.color: Theme.surface1
                            visible: modelData.paired
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Text { anchors.centerIn: parent; text: "󰆴"; font.family: Theme.iconFont; color: Theme.powerRed; font.pixelSize: Theme.scaled(18) }
                            MouseArea { id: forgetMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.action("remove", modelData.address) }
                        }

                        // Connect/Disconnect Toggle Icon
                        Rectangle {
                            width: Theme.scaled(40); height: Theme.scaled(40); radius: Theme.scaled(12); 
                            color: modelData.connected ? (actionMouse.containsMouse ? Theme.powerRed : Theme.powerRed) : (actionMouse.containsMouse ? Theme.blue : Theme.blue)
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Text { 
                                anchors.centerIn: parent
                                text: modelData.connected ? "󰂯" : "󰂴"
                                font.family: Theme.iconFont; color: Colors.background; font.pixelSize: Theme.scaled(20) 
                            }
                            MouseArea { 
                                id: actionMouse
                                anchors.fill: parent; 
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.connected) {
                                        BluetoothService.action("disconnect", modelData.address);
                                    } else {
                                        // Pair first if needed, then connect.
                                        if (!modelData.paired) {
                                            BluetoothService.action("pair", modelData.address);
                                        } else {
                                            BluetoothService.action("connect", modelData.address);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- Service Error View ---
    Rectangle {
        Layout.fillWidth: true; height: Theme.scaled(250); color: Qt.rgba(0.1, 0.05, 0.05, 0.3); radius: Theme.scaled(20); 
        visible: !BluetoothService.serviceActive
        border.color: Theme.powerRed; border.width: 1
        ColumnLayout {
            anchors.centerIn: parent; spacing: Theme.scaled(20); width: parent.width * 0.8
            Text { text: "󰂲"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(48); color: Theme.powerRed; Layout.alignment: Qt.AlignHCenter }
            ColumnLayout {
                spacing: Theme.scaled(5); Layout.alignment: Qt.AlignHCenter
                Text { text: "SERVICE ERROR"; color: Theme.text; font.pixelSize: Theme.scaled(16); font.weight: Font.Black; Layout.alignment: Qt.AlignHCenter }
                Text { text: "The Bluetooth daemon is not running or has crashed."; color: Theme.subtext1; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter; width: Theme.scaled(200); height: Theme.scaled(48); radius: Theme.scaled(14); color: (restartMouse.containsMouse ? Theme.powerRed : "transparent"); border.color: Theme.powerRed
                Text { anchors.centerIn: parent; text: "RESTART SERVICE"; color: (restartMouse.containsMouse ? Colors.background : Theme.powerRed); font.weight: Font.Black; font.pixelSize: Theme.scaled(11); font.letterSpacing: 1 }
                MouseArea { id: restartMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.restartService() }
            }
        }
    }

    // --- Empty State Message ---
    Rectangle {
        id: emptyState
        Layout.fillWidth: true; height: Theme.scaled(100); color: "transparent"
        visible: BluetoothService.powered && BluetoothService.serviceActive && deviceList.displayDevices.length === 0
        ColumnLayout {
            anchors.centerIn: parent; spacing: 10
            Text { text: "󰂲"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(32); color: Theme.surface2; Layout.alignment: Qt.AlignHCenter }
            Text { text: "NO DEVICES FOUND"; color: Theme.surface2; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; font.letterSpacing: 1; Layout.alignment: Qt.AlignHCenter }
        }
    }
}
