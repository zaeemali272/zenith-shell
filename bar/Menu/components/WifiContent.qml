import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."
import "../../../services"

Item {
    id: root
    
    // Explicit sizing for ScrollView integration
    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: mainContentCol.implicitHeight

    Component.onCompleted: {
        WifiService.refresh();
    }

    property var wifiSvc: WifiService
    property bool isAirplane: false
    property string selectedSsid: ""
    property string lastFailedSsid: ""
    
    // Track if any password input is active
    property bool isInputActive: selectedSsid !== "" && !wifiSvc.knownNetworks[selectedSsid]

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

    // Transparent layer to detect clicks outside the input area but within the menu
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: selectedSsid = ""
    }

    ColumnLayout {
        id: mainContentCol
        anchors.fill: parent
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
                        anchors.centerIn: parent; text: wifiSvc.isTesting ? "󰑐" : "󰑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(18)
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
            // Use contentHeight for dynamic expansion
            Layout.preferredHeight: contentHeight
            model: wifiSvc.networks; spacing: Theme.scaled(10); clip: true
            interactive: false

            
            delegate: FocusScope {
                id: delegateRoot
                width: list.width
                
                property bool isKnown: wifiSvc.knownNetworks[modelData.ssid]
                property bool showSecrets: false
                
                // Height expands if selected AND (!known OR user wants to see secrets)
                height: (selectedSsid === modelData.ssid && (!isKnown || showSecrets)) ? (isKnown ? Theme.scaled(130) : Theme.scaled(140)) : Theme.scaled(65)
                
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

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
                            selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid;
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
                                    text: modelData.connected ? "ACTIVE" : (isKnown ? "SAVED" : "AVAILABLE")
                                    color: modelData.connected ? Theme.powerGreen : Theme.surface2
                                    font.pixelSize: Theme.scaled(9); font.weight: Font.Black 
                                }
                            }
                            RowLayout { spacing: Theme.scaled(6)
                                // Disconnect Button (Only if connected)
                                Rectangle {
                                    visible: modelData.connected
                                    width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: Qt.rgba(1,0.5,0,0.1)
                                    Text { anchors.centerIn: parent; text: "󰤄"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.powerYellow }
                                    MouseArea { id: disconnectMouse; anchors.fill: parent; onClicked: wifiSvc.disconnect() }
                                }
                                
                                // Forget Button (Only if known)
                                Rectangle {
                                    visible: isKnown
                                    width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: Qt.rgba(1,0,0,0.1)
                                    Text { anchors.centerIn: parent; text: "󰆴"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.powerRed }
                                    MouseArea { id: forgetMouse; anchors.fill: parent; onClicked: wifiSvc.forgetNetwork(modelData.ssid) }
                                }

                                // Show Secrets Toggle (Only if known)
                                Rectangle {
                                    visible: isKnown
                                    width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: delegateRoot.showSecrets ? Theme.blue : Qt.rgba(1,1,1,0.05)
                                    Text { anchors.centerIn: parent; text: delegateRoot.showSecrets ? "󰈈" : "󰈉"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: delegateRoot.showSecrets ? "black" : Theme.text }
                                    MouseArea { anchors.fill: parent; onClicked: { delegateRoot.showSecrets = !delegateRoot.showSecrets; selectedSsid = modelData.ssid; } }
                                }

                                // Connect Button (If not connected but known)
                                Rectangle {
                                    visible: isKnown && !modelData.connected
                                    width: Theme.scaled(65); height: Theme.scaled(32); radius: Theme.scaled(8); color: Theme.blue
                                    Text { anchors.centerIn: parent; text: "CONNECT"; font.pixelSize: Theme.scaled(9); font.weight: Font.Black; color: "black" }
                                    MouseArea { anchors.fill: parent; onClicked: wifiSvc.connect(modelData.ssid, "") }
                                }

                                // Selection Arrow (If not connected and not known)
                                Rectangle {
                                    visible: !isKnown && !modelData.connected
                                    width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: Qt.rgba(1,1,1,0.05)
                                    Text { anchors.centerIn: parent; text: "󰅂"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.text }
                                    MouseArea { anchors.fill: parent; onClicked: selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid }
                                }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true; visible: selectedSsid === modelData.ssid && (!isKnown || showSecrets); spacing: Theme.scaled(10)
                            
                            onVisibleChanged: {
                                if (visible && !isKnown) {
                                    passInput.forceActiveFocus();
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true; spacing: Theme.scaled(8)
                                Rectangle { 
                                    Layout.fillWidth: true; height: Theme.scaled(38); color: Qt.rgba(0,0,0,0.2); radius: Theme.scaled(10); 
                                    border.color: lastFailedSsid === modelData.ssid ? Theme.powerRed : (passInput.activeFocus ? Theme.blue : Theme.glassBorder)
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: Theme.scaled(8)
                                        TextInput { 
                                            id: passInput; Layout.fillWidth: true; color: Theme.text; echoMode: delegateRoot.showSecrets ? TextInput.Normal : TextInput.Password; font.pixelSize: Theme.scaled(13)
                                            selectByMouse: true
                                            text: wifiSvc.savedSecrets[modelData.ssid] || ""
                                            Text { text: "Password..."; color: Theme.surface2; visible: !passInput.text && !passInput.activeFocus }
                                            onAccepted: { wifiSvc.connect(modelData.ssid, passInput.text); selectedSsid = ""; }
                                            Keys.onEscapePressed: { selectedSsid = ""; }
                                        }
                                        Text {
                                            text: delegateRoot.showSecrets ? "󰈈" : "󰈉"
                                            font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: delegateRoot.showSecrets ? Theme.blue : Theme.surface2
                                            MouseArea { anchors.fill: parent; onClicked: delegateRoot.showSecrets = !delegateRoot.showSecrets }
                                        }
                                    }
                                }
                                
                                Rectangle { 
                                    visible: !isKnown || (selectedSsid === modelData.ssid && !showSecrets)
                                    width: Theme.scaled(100); height: Theme.scaled(38); color: Theme.blue; radius: Theme.scaled(10)
                                    Text { anchors.centerIn: parent; text: "JOIN"; color: "black"; font.weight: Font.Black; font.pixelSize: Theme.scaled(10) }
                                    MouseArea { anchors.fill: parent; onClicked: { wifiSvc.connect(modelData.ssid, passInput.text); } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Process { id: rfkillProc }
}
