import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    // Focus capture for the whole content area
    focus: true
    
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

    Connections {
        target: QuickSettingsService
        function onQsVisibleChanged() {
            if (!QuickSettingsService.qsVisible) {
                selectedSsid = "";
            }
        }
    }

    ColumnLayout {
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

                // Refresh Button
                Rectangle {
                    width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(22); color: (refreshMouse.containsMouse ? Theme.base : Theme.backgroundColor); border.color: wifiSvc.isTesting ? Theme.powerYellow : Theme.surface1; clip: true
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
                    width: Theme.scaled(44); height: Theme.scaled(44); radius: Theme.scaled(22); color: (airplaneMouse.containsMouse ? Theme.base : Theme.backgroundColor); border.color: root.isAirplane ? Theme.powerRed : Theme.surface1; clip: true
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
                Layout.fillWidth: true; height: Theme.scaled(60); color: Theme.backgroundColor; radius: Theme.scaled(16); visible: wifiSvc.currentSsid !== ""
                RowLayout {
                    anchors.fill: parent; anchors.margins: Theme.scaled(12); spacing: Theme.scaled(15)
                    Rectangle { width: Theme.scaled(36); height: Theme.scaled(36); radius: Theme.scaled(10); color: Theme.surface0
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
            id: list; Layout.fillWidth: true; Layout.fillHeight: true; model: wifiSvc.networks; spacing: Theme.scaled(10); clip: true
            
            delegate: FocusScope {
                id: delegateRoot
                width: list.width; height: (selectedSsid === modelData.ssid && !wifiSvc.knownNetworks[modelData.ssid]) ? Theme.scaled(170) : Theme.scaled(65)
                
                Rectangle {
                    id: backgroundRect
                    anchors.fill: parent
                    // Darker on hover: Theme.base instead of Theme.menuBackground
                    color: modelData.connected ? Theme.surface0 : (delegateMouse.containsMouse ? Theme.base : Theme.menuBackground)
                    radius: Theme.scaled(18)
                    border.color: modelData.connected ? Theme.powerGreen : (selectedSsid === modelData.ssid ? Theme.blue : (delegateMouse.containsMouse ? Theme.surface1 : Theme.surface1))
                    border.width: modelData.connected ? 1.5 : 1
                    clip: true
                    
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    
                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            QuickSettingsService.isSticky = true;
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
                            // Signal Icon
                            Rectangle { width: Theme.scaled(36); height: Theme.scaled(36); radius: Theme.scaled(10); color: Theme.backgroundColor
                                Text { 
                                    anchors.centerIn: parent
                                    text: {
                                        if (modelData.connected) return "󰤨";
                                        if (modelData.signal >= 4) return "󰤨";
                                        if (modelData.signal >= 3) return "󰤥";
                                        if (modelData.signal >= 2) return "󰤢";
                                        if (modelData.signal >= 1) return "󰤟";
                                        return "󰤯";
                                    }
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
                                // Disconnect Button (only for connected network)
                                Rectangle {
                                    visible: modelData.connected
                                    width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: Theme.surface0
                                    Text { anchors.centerIn: parent; text: "󰤄"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.powerRed }
                                    MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: wifiSvc.disconnect() }
                                }

                                // Forget Button
                                Rectangle {
                                    visible: !!wifiSvc.knownNetworks[modelData.ssid]
                                    width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8); color: (forgetMouse.containsMouse ? Theme.base : Theme.fontColor)
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Text { anchors.centerIn: parent; text: "󱘖"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.powerYellow }
                                    MouseArea { id: forgetMouse; anchors.fill: parent; hoverEnabled: true; onClicked: wifiSvc.forgetNetwork(modelData.ssid) }
                                }
                                
                                // Action Button
                                Rectangle {
                                    visible: !modelData.connected
                                    width: wifiSvc.knownNetworks[modelData.ssid] ? Theme.scaled(75) : Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8)
                                    color: wifiSvc.knownNetworks[modelData.ssid] ? (actionMouse.containsMouse ? Theme.blue : Theme.blue) : (actionMouse.containsMouse ? Theme.base : Theme.surface0)
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Text { 
                                        anchors.centerIn: parent; font.pixelSize: Theme.scaled(10); font.weight: Font.Black
                                        text: wifiSvc.knownNetworks[modelData.ssid] ? "CONNECT" : "󰅂"
                                        color: wifiSvc.knownNetworks[modelData.ssid] ? "black" : Theme.text
                                    }
                                    MouseArea { 
                                        id: actionMouse
                                        anchors.fill: parent; 
                                        hoverEnabled: true
                                        onClicked: {
                                            QuickSettingsService.isSticky = true;
                                            if(wifiSvc.knownNetworks[modelData.ssid]) wifiSvc.connect(modelData.ssid, "");
                                            else selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid;
                                        }
                                    }
                                }
                            }
                        }
                        
                        // --- Password Input Section ---
                        ColumnLayout {
                            Layout.fillWidth: true; visible: selectedSsid === modelData.ssid && !wifiSvc.knownNetworks[modelData.ssid]; spacing: Theme.scaled(10)
                            Rectangle { 
                                Layout.fillWidth: true; height: Theme.scaled(38); color: Theme.surface0; radius: Theme.scaled(10); 
                                border.color: lastFailedSsid === modelData.ssid ? Theme.powerRed : Theme.surface1
                                border.width: 1
                                
                                TextInput { 
                                    id: passInput; anchors.fill: parent; anchors.margins: Theme.scaled(10); color: Theme.text; echoMode: TextInput.Password; font.pixelSize: Theme.scaled(13)
                                    focus: true 
                                    onVisibleChanged: if (visible && selectedSsid === modelData.ssid) passFocusTimer.start();
                                    Timer { id: passFocusTimer; interval: 50; onTriggered: passInput.forceActiveFocus() }
                                    Text { text: "Password..."; color: Theme.surface1; visible: !passInput.text && !passInput.activeFocus }
                                    onAccepted: { wifiSvc.connect(modelData.ssid, passInput.text); passInput.text = ""; }
                                }
                            }
                            Rectangle { 
                                Layout.fillWidth: true; height: Theme.scaled(38); color: (joinMouse.containsMouse ? Theme.blue : Theme.blue); radius: Theme.scaled(10)
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Text { anchors.centerIn: parent; text: "JOIN NETWORK"; color: "black"; font.weight: Font.Black; font.pixelSize: Theme.scaled(10) }
                                MouseArea { 
                                    id: joinMouse
                                    anchors.fill: parent; 
                                    hoverEnabled: true
                                    onClicked: { 
                                        QuickSettingsService.isSticky = true;
                                        wifiSvc.connect(modelData.ssid, passInput.text); 
                                        passInput.text = ""; 
                                    } 
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- Footer (Speed Test) ---
        Rectangle {
            Layout.fillWidth: true; height: Theme.scaled(50); color: (speedMouse.containsMouse ? Theme.base : Theme.backgroundColor); radius: Theme.scaled(16); border.color: wifiSvc.isTesting ? Theme.powerYellow : Theme.surface1
            Behavior on color { ColorAnimation { duration: 200 } }
            RowLayout {
                anchors.centerIn: parent; spacing: Theme.scaled(15)
                Text { text: wifiSvc.isTesting ? "󱑔" : "󰓅"; font.family: Theme.iconFont; color: wifiSvc.isTesting ? Theme.powerYellow : Theme.blue; font.pixelSize: Theme.scaled(20) }
                ColumnLayout { spacing: 0
                    Text { text: wifiSvc.isTesting ? "TESTING MAX SPEED..." : "DOWNLOAD SPEED"; color: Theme.surface2; font.pixelSize: Theme.scaled(7); font.weight: Font.Black }
                    Text { 
                        text: {
                            if (wifiSvc.isTesting) return "TESTING...";
                            if (wifiSvc.currentSpeed === "0.0 Mbps") return speedMouse.containsMouse ? "CLICK TO RUN" : "0.0 MBPS";
                            return wifiSvc.currentSpeed.toUpperCase();
                        }
                        color: Theme.text; font.pixelSize: Theme.scaled(14); font.weight: Font.Black 
                    }
                }
            }
            MouseArea { id: speedMouse; anchors.fill: parent; hoverEnabled: true; onClicked: wifiSvc.runMaxSpeedTest() }
        }
    }

    Process { id: rfkillProc }
}
