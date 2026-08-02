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
    readonly property bool isAirplane: wifiSvc.isAirplane
    property string selectedSsid: ""
    onSelectedSsidChanged: {
        WifiService.isUserTyping = (selectedSsid !== "");
    }
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
                    Text { text: "NETWORKS"; color: Theme.accentColor; font.pixelSize: Theme.scaled(14); font.letterSpacing: 2; font.weight: Font.Black }
                    Text {
                        text: root.isAirplane ? "AIRPLANE MODE" : (wifiSvc.networks.length + " IN RANGE")
                        color: Theme.subtext0; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold; font.letterSpacing: 1
                    }
                }

                // Speed Test
                Rectangle {
                    width: Theme.scaled(110); height: Theme.scaled(44); radius: Theme.scaled(22); color: (speedMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"); border.color: wifiSvc.isTesting ? Theme.powerYellow : Theme.glassBorder; clip: true
                    Behavior on color { ColorAnimation { duration: 200 } }
                    RowLayout {
                        anchors.centerIn: parent; spacing: 5
                        Text { text: wifiSvc.isTesting ? "󱐋" : "󰓅"; font.family: Theme.iconFont; color: wifiSvc.isTesting ? Theme.powerYellow : Theme.accentColor; font.pixelSize: Theme.scaled(16) }
                        Text { 
                            text: wifiSvc.isTesting ? "TESTING" : (wifiSvc.currentSpeed === "0.0 Mbps" ? "SPEED" : wifiSvc.currentSpeed.replace(" Mbps", " MB/s").toUpperCase())
                            color: "#ffffff"; font.pixelSize: Theme.scaled(9); font.weight: Font.Black 
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
                    Text { anchors.centerIn: parent; text: "󰀝"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(20); color: root.isAirplane ? Theme.powerRed : "#ffffff" }
                    MouseArea {
                        id: airplaneMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: wifiSvc.toggleAirplane(!wifiSvc.isAirplane)
                    }
                }
            }
            
            // Current Connection Detailed Info
            Rectangle {
                Layout.fillWidth: true; height: Theme.scaled(60); color: Qt.rgba(0,0,0,0.25); radius: Theme.scaled(16); visible: wifiSvc.currentSsid !== ""
                border.color: Theme.glassBorder
                RowLayout {
                    anchors.fill: parent; anchors.margins: Theme.scaled(12); spacing: Theme.scaled(15)
                    Rectangle { width: Theme.scaled(36); height: Theme.scaled(36); radius: Theme.scaled(10); color: Qt.rgba(1,1,1,0.05)
                        Text { anchors.centerIn: parent; text: "󰤨"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(18); color: Theme.powerGreen }
                    }
                    ColumnLayout { spacing: 0; Layout.fillWidth: true
                        Text { text: wifiSvc.currentSsid; color: "#ffffff"; font.weight: Font.Bold; font.pixelSize: Theme.scaled(13); elide: Text.ElideRight }
                        Text { 
                            text: wifiSvc.ipv4Address ? wifiSvc.ipv4Address : "Connecting..."
                            color: Theme.subtext0; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold 
                        }
                    }
                    ColumnLayout { spacing: 0; Layout.alignment: Qt.AlignRight
                        Text { text: wifiSvc.rssi; color: Theme.powerYellow; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; horizontalAlignment: Text.AlignRight }
                        Text { text: wifiSvc.txBitrate ? (parseInt(wifiSvc.txBitrate)/1000).toFixed(0) + " MB/S" : ""; color: Theme.subtext0; font.pixelSize: Theme.scaled(9); font.weight: Font.Black; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
        }

        // --- Network List ---
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            model: wifiSvc.networks; spacing: Theme.scaled(10); clip: true
            interactive: false

            delegate: FocusScope {
                id: delegateRoot
                width: list.width
                
                property bool isKnown: !!(modelData && wifiSvc.knownNetworks[modelData.ssid])
                property bool showSecrets: false
                
                height: (selectedSsid === modelData.ssid && (!isKnown || showSecrets)) ? (isKnown ? Theme.scaled(130) : Theme.scaled(140)) : Theme.scaled(65)
                
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

                Rectangle {
                    id: backgroundRect
                    anchors.fill: parent
                    color: modelData.connected ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.1) : (delegateMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.2))
                    radius: Theme.scaled(18)
                    border.color: modelData.connected ? Theme.powerGreen : (selectedSsid === modelData.ssid ? Theme.accentColor : Theme.glassBorder)
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
                                    color: modelData.connected ? Theme.powerGreen : "#ffffff" 
                                }
                            }
                            ColumnLayout { spacing: 0; Layout.fillWidth: true
                                Text { text: modelData.ssid; color: "#ffffff"; font.weight: Font.Bold; font.pixelSize: Theme.scaled(13); elide: Text.ElideRight }
                                Text { 
                                    text: modelData.connected ? "ACTIVE" : (isKnown ? "SAVED" : "AVAILABLE")
                                    color: modelData.connected ? Theme.powerGreen : Theme.subtext0
                                    font.pixelSize: Theme.scaled(9); font.weight: Font.Black 
                                }
                            }
                            RowLayout { spacing: Theme.scaled(6)
                                Rectangle {
                                    visible: !!(modelData && modelData.connected)
                                    width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: Qt.rgba(1,0.5,0,0.1)
                                    Text { anchors.centerIn: parent; text: "󰤄"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.powerYellow }
                                    MouseArea { id: disconnectMouse; anchors.fill: parent; onClicked: wifiSvc.disconnect() }
                                }
                                
                                Rectangle {
                                    visible: isKnown
                                    width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: Qt.rgba(1,0,0,0.1)
                                    Text { anchors.centerIn: parent; text: "󰆴"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.powerRed }
                                    MouseArea { id: forgetMouse; anchors.fill: parent; onClicked: wifiSvc.forgetNetwork(modelData.ssid) }
                                }

                                Rectangle {
                                    visible: isKnown
                                    width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: delegateRoot.showSecrets ? Theme.accentColor : Qt.rgba(1,1,1,0.05)
                                    Text { anchors.centerIn: parent; text: delegateRoot.showSecrets ? "󰈈" : "󰈉"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: delegateRoot.showSecrets ? Colors.on_primary : "#ffffff" }
                                    MouseArea { anchors.fill: parent; onClicked: { delegateRoot.showSecrets = !delegateRoot.showSecrets; selectedSsid = modelData.ssid; } }
                                }

                                Rectangle {
                                    visible: isKnown && !(modelData && modelData.connected)
                                    width: Theme.scaled(65); height: Theme.scaled(32); radius: Theme.scaled(8); color: Theme.accentColor
                                    Text { anchors.centerIn: parent; text: "CONNECT"; font.pixelSize: Theme.scaled(9); font.weight: Font.Black; color: Colors.on_primary }
                                    MouseArea { anchors.fill: parent; onClicked: wifiSvc.connect(modelData.ssid, "") }
                                }

                                Rectangle {
                                    visible: !isKnown && !(modelData && modelData.connected)
                                    width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: Qt.rgba(1,1,1,0.05)
                                    Text { anchors.centerIn: parent; text: "󰅂"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: "#ffffff" }
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
                                    border.color: lastFailedSsid === modelData.ssid ? Theme.powerRed : (passInput.activeFocus ? Theme.accentColor : Theme.glassBorder)
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: Theme.scaled(8)
                                        TextInput { 
                                            id: passInput; Layout.fillWidth: true; color: "#ffffff"; echoMode: delegateRoot.showSecrets ? TextInput.Normal : TextInput.Password; font.pixelSize: Theme.scaled(13)
                                            selectByMouse: true
                                            text: wifiSvc.savedSecrets[modelData.ssid] || ""
                                            Text { text: "Password..."; color: Theme.subtext0; visible: !passInput.text && !passInput.activeFocus }
                                            onAccepted: { wifiSvc.connect(modelData.ssid, passInput.text); selectedSsid = ""; }
                                            Keys.onEscapePressed: { selectedSsid = ""; }
                                        }
                                        Text {
                                            text: delegateRoot.showSecrets ? "󰈈" : "󰈉"
                                            font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: delegateRoot.showSecrets ? Theme.accentColor : Theme.subtext0
                                            MouseArea { anchors.fill: parent; onClicked: delegateRoot.showSecrets = !delegateRoot.showSecrets }
                                        }
                                    }
                                }
                                
                                Rectangle { 
                                    visible: !isKnown || (selectedSsid === modelData.ssid && !showSecrets)
                                    width: Theme.scaled(100); height: Theme.scaled(38); color: Theme.accentColor; radius: Theme.scaled(10)
                                    Text { anchors.centerIn: parent; text: "JOIN"; color: Colors.on_primary; font.weight: Font.Black; font.pixelSize: Theme.scaled(10) }
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
