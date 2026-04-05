import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: 25
    Layout.fillWidth: true
    
    // Focus capture for the whole content area
    focus: true
    
    Component.onCompleted: {
        WifiService.refresh();
        // Ensure the parent window is focusable (Restoring your working logic)
        if (Quickshell.window) Quickshell.window.focusable = true;
    }

    property var wifiSvc: WifiService
    property bool isAirplane: false
    property string selectedSsid: ""

    // CRITICAL: The "Grab Shield" from your previous version
    // This prevents clicks from dropping focus back to the desktop/Hyprland
    MouseArea {
        anchors.fill: parent
        z: -1 // Keep behind other elements
        onPressed: (mouse) => {
            mouse.accepted = true;
            root.forceActiveFocus();
        }
    }

    // --- Header ---
    RowLayout {
        Layout.fillWidth: true; spacing: 15
        
        ColumnLayout {
            spacing: 2; Layout.fillWidth: true
            Text { text: "NETWORKS"; color: "#89b4fa"; font.pixelSize: 14; font.letterSpacing: 2; font.weight: Font.Black; opacity: 0.8 }
            Text {
                text: root.isAirplane ? "AIRPLANE MODE" : (wifiSvc.networks.length + " IN RANGE")
                color: "#585b70"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1
            }
        }

        // Refresh Button
        Rectangle {
            width: 48; height: 48; radius: 24; color: "#11111b"; border.color: wifiSvc.isTesting ? "#f9e2af" : "#313244"; clip: true
            Text {
                id: refreshIcon
                anchors.centerIn: parent; text: wifiSvc.isTesting ? "󱐋" : "󰑐"; font.family: Theme.iconFont; font.pixelSize: 20
                color: wifiSvc.isTesting ? "#f9e2af" : "#a6e3a1"
            }
            RotationAnimation { target: refreshIcon; running: wifiSvc.isTesting; from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
            MouseArea { anchors.fill: parent; onClicked: wifiSvc.refresh() }
        }

        // Airplane Mode
        Rectangle {
            width: 48; height: 48; radius: 24; color: "#11111b"; border.color: root.isAirplane ? "#f38ba8" : "#313244"; clip: true
            Text { anchors.centerIn: parent; text: "󰀝"; font.family: Theme.iconFont; font.pixelSize: 22; color: root.isAirplane ? "#f38ba8" : "#cdd6f4" }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.isAirplane = !root.isAirplane;
                    rfkillProc.command = ["rfkill", root.isAirplane ? "block" : "unblock", "wifi"];
                    rfkillProc.running = true;
                }
            }
        }
    }

    // --- Network List ---
    ListView {
        id: list; Layout.fillWidth: true; Layout.fillHeight: true; model: wifiSvc.networks; spacing: 12; clip: true
        
        delegate: Rectangle {
            id: card
            width: list.width; height: (selectedSsid === modelData.ssid && !wifiSvc.knownNetworks[modelData.ssid]) ? 180 : 70
            color: "#11111b"; radius: 20; border.color: selectedSsid === modelData.ssid ? "#89b4fa" : "#313244"; clip: true
            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 15; spacing: 15
                RowLayout {
                    Layout.fillWidth: true; spacing: 15
                    Rectangle { width: 40; height: 40; radius: 12; color: "#181825"
                        Text { anchors.centerIn: parent; text: modelData.security === "psk" ? "󰷛" : "󰤨"; font.family: Theme.iconFont; font.pixelSize: 20; color: "#cdd6f4" }
                    }
                    ColumnLayout { spacing: 0; Layout.fillWidth: true
                        Text { text: modelData.ssid; color: "white"; font.weight: Font.Bold; font.pixelSize: 14 }
                        Text { text: wifiSvc.knownNetworks[modelData.ssid] ? "SAVED" : "AVAILABLE"; color: "#585b70"; font.pixelSize: 9; font.weight: Font.Black }
                    }
                    RowLayout { spacing: 8
                        Rectangle {
                            visible: !!wifiSvc.knownNetworks[modelData.ssid]
                            width: 36; height: 36; radius: 10; color: "#181825"
                            Text { anchors.centerIn: parent; text: "󱘖"; font.family: Theme.iconFont; color: "#f38ba8" }
                            MouseArea { anchors.fill: parent; onClicked: wifiSvc.forgetNetwork(modelData.ssid) }
                        }
                        Rectangle {
                            width: wifiSvc.knownNetworks[modelData.ssid] ? 80 : 36; height: 36; radius: 10
                            color: wifiSvc.knownNetworks[modelData.ssid] ? "#89b4fa" : "#181825"
                            Text { 
                                anchors.centerIn: parent; font.pixelSize: 11; font.weight: Font.Black
                                text: wifiSvc.knownNetworks[modelData.ssid] ? "CONNECT" : "󰅂"; color: wifiSvc.knownNetworks[modelData.ssid] ? "black" : "#cdd6f4" 
                            }
                            MouseArea { 
                                anchors.fill: parent; 
                                onClicked: {
                                    root.forceActiveFocus(); // Restored focus grab
                                    if(wifiSvc.knownNetworks[modelData.ssid]) wifiSvc.connect(modelData.ssid, "");
                                    else selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid;
                                }
                            }
                        }
                    }
                }
                
                // --- Password Input Section ---
                ColumnLayout {
                    Layout.fillWidth: true; visible: selectedSsid === modelData.ssid && !wifiSvc.knownNetworks[modelData.ssid]; spacing: 12
                    Rectangle { 
                        Layout.fillWidth: true; height: 44; color: "#181825"; radius: 12; border.color: "#313244"
                        TextInput { 
                            id: passInput; anchors.fill: parent; anchors.margins: 12; color: "white"; echoMode: TextInput.Password; font.pixelSize: 14
                            
                            // RESTORED FOCUS LOGIC
                            focus: true 
                            onVisibleChanged: { if (visible) forceActiveFocus(); }
                            
                            Text { text: "Password..."; color: "#45475a"; visible: !passInput.text && !passInput.activeFocus }
                            onAccepted: { wifiSvc.connect(modelData.ssid, passInput.text); passInput.text = ""; }
                        }
                    }
                    Rectangle { 
                        Layout.fillWidth: true; height: 44; color: "#89b4fa"; radius: 12
                        Text { anchors.centerIn: parent; text: "JOIN"; color: "black"; font.weight: Font.Black }
                        MouseArea { anchors.fill: parent; onClicked: { wifiSvc.connect(modelData.ssid, passInput.text); passInput.text = ""; } }
                    }
                }
            }
        }
    }

    // --- Footer ---
    Rectangle {
        Layout.fillWidth: true; height: 55; color: "#11111b"; radius: 20; border.color: wifiSvc.isTesting ? "#f9e2af" : "#313244"
        RowLayout {
            anchors.centerIn: parent; spacing: 15
            Text { text: wifiSvc.isTesting ? "󱑔" : "󰓅"; font.family: Theme.iconFont; color: wifiSvc.isTesting ? "#f9e2af" : "#89b4fa"; font.pixelSize: 22 }
            ColumnLayout { spacing: 0
                Text { text: wifiSvc.isTesting ? "TESTING MAX SPEED..." : "DOWNLOAD SPEED"; color: "#585b70"; font.pixelSize: 8; font.weight: Font.Black }
                Text { text: wifiSvc.currentSpeed.toUpperCase(); color: "white"; font.pixelSize: 16; font.weight: Font.Black }
            }
        }
    }

    Process { id: rfkillProc }
}