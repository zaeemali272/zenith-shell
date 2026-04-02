import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    
    property var wifiSvc: WifiService
    property var networks: wifiSvc.networks
    readonly property var knownNetworks: wifiSvc.knownNetworks
    property string currentSpeed: "Scanning..."
    property bool isAirplane: false
    property string selectedSsid: ""
    property bool showPassword: false

    function connectTo(ssid, pass) {
        wifiSvc.connect(ssid, pass);
        selectedSsid = "";
    }

    function forgetNetwork(ssid) {
        wifiSvc.forgetNetwork(ssid);
        if (selectedSsid === ssid) selectedSsid = "";
    }

    spacing: 20

    // Header with Airplane Mode and Scanning status
    RowLayout {
        Layout.fillWidth: true
        spacing: 15
        
        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Text {
                text: "Wi-Fi"
                color: "white"
                font.bold: true
                font.pixelSize: 22
            }
            Text {
                text: root.isAirplane ? "Airplane mode is on" : (networks.length + " networks found")
                color: "#a6adc8"
                font.pixelSize: 12
            }
        }

        // Airplane Mode Toggle
        Rectangle {
            width: 44; height: 44
            radius: 22
            color: root.isAirplane ? Theme.accentColor : "#1e1e2e"
            border.color: "#313244"
            
            Text {
                anchors.centerIn: parent
                text: "󰀝"
                font.family: Theme.iconFont
                font.pixelSize: 20
                color: root.isAirplane ? "black" : "white"
            }
            
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

    // Network List
    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: root.networks
        spacing: 10
        clip: true
        
        // Use a ScrollView-like behavior if possible, or just standard list
        delegate: Rectangle {
            width: list.width
            height: (selectedSsid === modelData.ssid && !knownNetworks[modelData.ssid]) ? 160 : 64
            color: "#1e1e2e"
            radius: 16
            border.color: selectedSsid === modelData.ssid ? Theme.accentColor : "#313244"
            border.width: selectedSsid === modelData.ssid ? 2 : 1
            clip: true

            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    
                    Rectangle {
                        width: 40; height: 40
                        radius: 20
                        color: "#2a2a32"
                        Text {
                            anchors.centerIn: parent
                            text: modelData.security === "psk" ? "󰷛" : "󰤨"
                            font.family: Theme.iconFont
                            font.pixelSize: 18
                            color: "white"
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text { 
                            text: modelData.ssid; 
                            color: "white"; 
                            font.bold: true; 
                            font.pixelSize: 14; 
                            elide: Text.ElideRight 
                        }
                        Text { 
                            text: knownNetworks[modelData.ssid] ? "Saved" : (modelData.security === "psk" ? "Secured" : "Open")
                            color: "#a6adc8"; 
                            font.pixelSize: 11 
                        }
                    }

                    // Forget/Connect Actions
                    RowLayout {
                        spacing: 8
                        visible: !!knownNetworks[modelData.ssid]
                        
                        Rectangle {
                            width: 32; height: 32; radius: 16; color: "#313244"
                            Text { anchors.centerIn: parent; text: "󱘖"; font.family: Theme.iconFont; color: "#f38ba8" }
                            MouseArea { anchors.fill: parent; onClicked: forgetNetwork(modelData.ssid) }
                        }
                        
                        Rectangle {
                            width: 80; height: 32; radius: 16; color: Theme.accentColor
                            Text { anchors.centerIn: parent; text: "Connect"; color: "black"; font.bold: true; font.pixelSize: 11 }
                            MouseArea { anchors.fill: parent; onClicked: connectTo(modelData.ssid, "") }
                        }
                    }
                    
                    // Toggle Password Input for unknown networks
                    Rectangle {
                        width: 32; height: 32; radius: 16; color: "#313244"
                        visible: !knownNetworks[modelData.ssid]
                        Text { 
                            anchors.centerIn: parent; 
                            text: selectedSsid === modelData.ssid ? "󰅖" : "󰅂"; 
                            font.family: Theme.iconFont; 
                            color: "white" 
                        }
                        MouseArea { 
                            anchors.fill: parent; 
                            onClicked: selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid 
                        }
                    }
                }

                // Password Input Section
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: selectedSsid === modelData.ssid && !knownNetworks[modelData.ssid]
                    spacing: 12
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        color: "#2a2a32"
                        radius: 12
                        border.color: "#45475a"
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: { left: 15; right: 10 }
                            
                            TextInput {
                                id: passInput
                                Layout.fillWidth: true
                                color: "white"
                                font.pixelSize: 14
                                echoMode: showPassword ? TextInput.Normal : TextInput.Password
                                focus: parent.visible && selectedSsid === modelData.ssid
                                
                                Text {
                                    text: "Password"
                                    color: "#585b70"
                                    visible: !passInput.text
                                    font.pixelSize: 14
                                }
                            }
                            
                            Rectangle {
                                width: 32; height: 32; radius: 16; color: "transparent"
                                Text { 
                                    anchors.centerIn: parent; 
                                    text: showPassword ? "󰈈" : "󰈉"; 
                                    font.family: Theme.iconFont; 
                                    color: "#a6adc8" 
                                }
                                MouseArea { anchors.fill: parent; onClicked: showPassword = !showPassword }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        color: Theme.accentColor
                        radius: 12
                        Text { 
                            anchors.centerIn: parent; 
                            text: "Connect to " + modelData.ssid; 
                            color: "black"; 
                            font.bold: true; 
                            font.pixelSize: 14 
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { connectTo(modelData.ssid, passInput.text); passInput.text = ""; }
                        }
                    }
                }
            }
            
            MouseArea {
                anchors.fill: parent
                enabled: !knownNetworks[modelData.ssid] && selectedSsid !== modelData.ssid
                onClicked: selectedSsid = modelData.ssid
                z: -1
            }
        }
    }

    // Speed Footer
    Rectangle {
        Layout.fillWidth: true
        height: 50
        color: "#1e1e2e"
        radius: 16
        border.color: "#313244"
        
        RowLayout {
            anchors.centerIn: parent
            spacing: 10
            Text { text: "󰓅"; font.family: Theme.iconFont; color: Theme.accentColor; font.pixelSize: 18 }
            Text { text: "Network Speed: " + currentSpeed; color: "#a6adc8"; font.pixelSize: 13; font.bold: true }
        }
    }

    Process { id: rfkillProc }
}
