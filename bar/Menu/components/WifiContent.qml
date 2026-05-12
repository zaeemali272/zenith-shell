import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."
import "../../../services"

ColumnLayout {
    id: root
    spacing: Theme.scaled(20)
    
    // Explicit sizing for ScrollView integration
    Layout.fillWidth: true
    Layout.fillHeight: true

    Component.onCompleted: {
        WifiService.refresh();
    }

    property var wifiSvc: WifiService
    property bool isAirplane: false
    property string selectedSsid: ""
    property string lastFailedSsid: ""

    Connections {
        target: WifiService
        function onConnectionFailed(ssid) {
            if (ssid === selectedSsid) {
                lastFailedSsid = ssid;
                const timer = Qt.createQmlObject('import QtQuick; Timer { interval: 2000; onTriggered: destroy() }', root);
                timer.triggered.connect(() => { if (lastFailedSsid === ssid) lastFailedSsid = ""; });
                timer.start();
            }
        }
        function onConnectionSuccess(ssid) {
            selectedSsid = "";
            lastFailedSsid = "";
        }
    }

    ColumnLayout {
        id: mainContentCol
        Layout.fillWidth: true
        spacing: Theme.scaled(20)

        // --- Header & Status ---
        ColumnLayout {
            Layout.fillWidth: true; spacing: Theme.scaled(15)
            RowLayout {
                Layout.fillWidth: true; spacing: Theme.scaled(15)
                ColumnLayout {
                    spacing: Theme.scaled(2); Layout.fillWidth: true
                    Text { text: "NETWORKS"; color: Theme.blue; font.pixelSize: Theme.scaled(14); font.letterSpacing: 2; font.weight: Font.Black; opacity: 0.8 }
                    Text {
                        text: root.isAirplane ? "AIRPLANE MODE" : (wifiSvc.networks.length + " IN RANGE")
                        color: Theme.surface2; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold; font.letterSpacing: 1
                    }
                }

                // Speed Test
                Rectangle {
                    width: Theme.scaled(110); height: Theme.scaled(44); radius: Theme.scaled(22); color: (speedMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"); border.color: wifiSvc.isTesting ? Theme.powerYellow : Theme.glassBorder; clip: true
                    Behavior on color { ColorAnimation { duration: 200 } }
                    RowLayout {
                        anchors.centerIn: parent; spacing: 5
                        Text { text: wifiSvc.isTesting ? "󱐋" : "󰓅"; font.family: Theme.iconFont; color: wifiSvc.isTesting ? Theme.powerYellow : Theme.blue; font.pixelSize: Theme.scaled(16) }
                        Text { 
                            text: wifiSvc.isTesting ? "TESTING" : (wifiSvc.currentSpeed === "0.0 Mbps" ? "SPEED" : wifiSvc.currentSpeed.replace(" Mbps", " MB/s").toUpperCase())
                            color: Theme.text; font.pixelSize: Theme.scaled(9); font.weight: Font.Black 
                        }
                    }
                    MouseArea { id: speedMouse; anchors.fill: parent; hoverEnabled: true; onClicked: wifiSvc.runMaxSpeedTest() }
                }

                // Refresh Button
                Rectangle {
                    width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(22); color: (refreshMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"); border.color: wifiSvc.isTesting ? Theme.powerYellow : Theme.glassBorder; clip: true
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        id: refreshIcon
                        anchors.centerIn: parent; text: wifiSvc.isTesting ? "󱐋" : "󰑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(18)
                        color: wifiSvc.isTesting ? Theme.powerYellow : Theme.powerGreen
                    }
                    RotationAnimation { target: refreshIcon; running: wifiSvc.isTesting; from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
                    MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; onClicked: wifiSvc.refresh() }
                }

                // Airplane Mode
                Rectangle {
                    width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(22); color: (airplaneMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"); border.color: root.isAirplane ? Theme.powerRed : Theme.glassBorder; clip: true
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text { anchors.centerIn: parent; text: "󰀝"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(20); color: root.isAirplane ? Theme.powerRed : Theme.text }
                    MouseArea {
                        id: airplaneMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            root.isAirplane = !root.isAirplane;
                            rfkillProc.command = ["rfkill", root.isAirplane ? "block" : "unblock", "wifi"];
                            rfkillProc.running = true;
                        }
                    }
                }
            }
            
            // Current Connection Detailed Info
            Rectangle {
                Layout.fillWidth: true; height: Theme.scaled(60); color: Qt.rgba(0,0,0,0.2); radius: Theme.scaled(16); visible: wifiSvc.currentSsid !== ""
                border.color: Theme.glassBorder
                RowLayout {
                    anchors.fill: parent; anchors.margins: Theme.scaled(12); spacing: Theme.scaled(15)
                    Rectangle { width: Theme.scaled(36); height: Theme.scaled(36); radius: Theme.scaled(10); color: Qt.rgba(1,1,1,0.05)
                        Text { anchors.centerIn: parent; text: "󰤨"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(18); color: Theme.powerGreen }
                    }
                    ColumnLayout { spacing: 0; Layout.fillWidth: true
                        Text { text: wifiSvc.currentSsid; color: Theme.text; font.weight: Font.Bold; font.pixelSize: Theme.scaled(13); elide: Text.ElideRight }
                        Text { 
                            text: wifiSvc.ipv4Address ? wifiSvc.ipv4Address : "Connecting..."
                            color: Theme.surface2; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold 
                        }
                    }
                    ColumnLayout { spacing: 0; Layout.alignment: Qt.AlignRight
                        Text { text: wifiSvc.rssi; color: Theme.powerYellow; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; horizontalAlignment: Text.AlignRight }
                        Text { text: wifiSvc.txBitrate ? (parseInt(wifiSvc.txBitrate)/1000).toFixed(0) + " MB/S" : ""; color: Theme.surface2; font.pixelSize: Theme.scaled(9); font.weight: Font.Black; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
        }

        // --- Network List ---
        ListView {
            id: list
            Layout.fillWidth: true
            // Calculate total height: count * (delegate height + spacing)
            Layout.preferredHeight: wifiSvc.networks.length * Theme.scaled(75)
            model: wifiSvc.networks; spacing: Theme.scaled(10); clip: true
            interactive: false

            
            delegate: FocusScope {
                id: delegateRoot
                width: list.width; height: (selectedSsid === modelData.ssid && !wifiSvc.knownNetworks[modelData.ssid]) ? Theme.scaled(170) : Theme.scaled(65)
                
                Rectangle {
                    id: backgroundRect
                    anchors.fill: parent
                    color: modelData.connected ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.1) : (delegateMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.15))
                    radius: Theme.scaled(18)
                    border.color: modelData.connected ? Theme.powerGreen : (selectedSsid === modelData.ssid ? Theme.blue : Theme.glassBorder)
                    border.width: 1
                    clip: true
                    
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    
                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if(wifiSvc.knownNetworks[modelData.ssid]) {
                                wifiSvc.connect(modelData.ssid, "");
                            } else {
                                selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid;
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: Theme.scaled(12); spacing: Theme.scaled(12)
                        RowLayout {
                            Layout.fillWidth: true; spacing: Theme.scaled(12)
                            Rectangle { width: Theme.scaled(36); height: Theme.scaled(36); radius: Theme.scaled(10); color: Qt.rgba(1,1,1,0.05)
                                Text { 
                                    anchors.centerIn: parent
                                    text: modelData.connected ? "󰤨" : (modelData.signal >= 4 ? "󰤨" : (modelData.signal >= 3 ? "󰤥" : (modelData.signal >= 2 ? "󰤢" : (modelData.signal >= 1 ? "󰤟" : "󰤯"))))
                                    font.family: Theme.iconFont; font.pixelSize: Theme.scaled(18)
                                    color: modelData.connected ? Theme.powerGreen : Theme.text 
                                }
                            }
                            ColumnLayout { spacing: 0; Layout.fillWidth: true
                                Text { text: modelData.ssid; color: Theme.text; font.weight: Font.Bold; font.pixelSize: Theme.scaled(13); elide: Text.ElideRight }
                                Text { 
                                    text: modelData.connected ? "ACTIVE" : (wifiSvc.knownNetworks[modelData.ssid] ? "SAVED" : "AVAILABLE")
                                    color: modelData.connected ? Theme.powerGreen : Theme.surface2
                                    font.pixelSize: Theme.scaled(9); font.weight: Font.Black 
                                }
                            }
                            RowLayout { spacing: Theme.scaled(6)
                                Rectangle {
                                    visible: modelData.connected
                                    width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: Qt.rgba(1,0,0,0.1)
                                    Text { anchors.centerIn: parent; text: "󰤄"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.powerRed }
                                    MouseArea { anchors.fill: parent; onClicked: wifiSvc.disconnect() }
                                }
                                Rectangle {
                                    visible: !modelData.connected
                                    width: wifiSvc.knownNetworks[modelData.ssid] ? Theme.scaled(75) : Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8)
                                    color: wifiSvc.knownNetworks[modelData.ssid] ? Theme.blue : Qt.rgba(1,1,1,0.05)
                                    Text { 
                                        anchors.centerIn: parent; font.pixelSize: Theme.scaled(10); font.weight: Font.Black
                                        text: wifiSvc.knownNetworks[modelData.ssid] ? "CONNECT" : "󰅂"
                                        color: wifiSvc.knownNetworks[modelData.ssid] ? "black" : Theme.text
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: { if(wifiSvc.knownNetworks[modelData.ssid]) wifiSvc.connect(modelData.ssid, ""); else selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid; } }
                                }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true; visible: selectedSsid === modelData.ssid && !wifiSvc.knownNetworks[modelData.ssid]; spacing: Theme.scaled(10)
                            Rectangle { 
                                Layout.fillWidth: true; height: Theme.scaled(38); color: Qt.rgba(0,0,0,0.2); radius: Theme.scaled(10); 
                                border.color: lastFailedSsid === modelData.ssid ? Theme.powerRed : Theme.glassBorder
                                TextInput { 
                                    id: passInput; anchors.fill: parent; anchors.margins: Theme.scaled(10); color: Theme.text; echoMode: TextInput.Password; font.pixelSize: Theme.scaled(13)
                                    Text { text: "Password..."; color: Theme.surface2; visible: !passInput.text && !passInput.activeFocus }
                                    onAccepted: { wifiSvc.connect(modelData.ssid, passInput.text); passInput.text = ""; }
                                }
                            }
                            Rectangle { 
                                Layout.fillWidth: true; height: Theme.scaled(38); color: Theme.blue; radius: Theme.scaled(10)
                                Text { anchors.centerIn: parent; text: "JOIN NETWORK"; color: "black"; font.weight: Font.Black; font.pixelSize: Theme.scaled(10) }
                                MouseArea { anchors.fill: parent; onClicked: { wifiSvc.connect(modelData.ssid, passInput.text); passInput.text = ""; } }
                            }
                        }
                    }
                }
            }
        }
    }
    Process { id: rfkillProc }
}
