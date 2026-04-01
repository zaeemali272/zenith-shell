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

    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Wi-Fi Settings"
            color: Theme.fontColor
            font.bold: true
            font.pixelSize: 18
            Layout.fillWidth: true
        }
        MouseArea {
            width: 30; height: 30
            onClicked: {
                root.isAirplane = !root.isAirplane;
                rfkillProc.command = ["rfkill", root.isAirplane ? "block" : "unblock", "wifi"];
                rfkillProc.running = true;
            }
            Text {
                anchors.centerIn: parent
                text: root.isAirplane ? "󰀝" : "󰤨"
                font.family: Theme.iconFont
                color: root.isAirplane ? "red" : Theme.accentColor
                font.pixelSize: 18
            }
        }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: root.networks
        spacing: 4
        clip: true
        delegate: Item {
            width: list.width
            height: (selectedSsid === modelData.ssid && !knownNetworks[modelData.ssid]) ? 145 : 50
            Column {
                anchors.fill: parent
                spacing: 4
                Rectangle {
                    width: parent.width; height: 45
                    color: m.containsMouse || selectedSsid === modelData.ssid ? "#1a1a1a" : "transparent"
                    radius: 8
                    MouseArea {
                        id: m
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (knownNetworks[modelData.ssid]) connectTo(modelData.ssid, "");
                            else selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid;
                        }
                    }
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 12
                        Text { text: modelData.security === "psk" ? "󰷛" : "󰤨"; font.family: Theme.iconFont; color: Theme.fontColor }
                        Text { text: modelData.ssid; color: Theme.fontColor; Layout.fillWidth: true; elide: Text.ElideRight }
                        MouseArea {
                            id: forgetBtn
                            width: 24; height: 24; hoverEnabled: true
                            visible: !!knownNetworks[modelData.ssid]
                            onClicked: forgetNetwork(modelData.ssid)
                            Text { anchors.centerIn: parent; text: "󱘖"; font.family: Theme.iconFont; color: forgetBtn.containsMouse ? "white" : "red" }
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: (selectedSsid === modelData.ssid && !knownNetworks[modelData.ssid]) ? 90 : 0
                    visible: height > 0; clip: true; color: "#0a0a0a"; radius: 8
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 8
                        RowLayout {
                            TextInput {
                                id: passInput
                                Layout.fillWidth: true; color: "white"
                                echoMode: showPassword ? TextInput.Normal : TextInput.Password
                                focus: parent.visible && selectedSsid === modelData.ssid
                                Text { text: "Enter Password..."; color: "#444"; visible: !passInput.text }
                            }
                            MouseArea {
                                width: 24; height: 24; onClicked: showPassword = !showPassword
                                Text { anchors.centerIn: parent; text: showPassword ? "󰈈" : "󰈉"; font.family: Theme.iconFont; color: Theme.accentColor }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; height: 32; color: Theme.accentColor; radius: 6
                            Text { anchors.centerIn: parent; text: "CONNECT"; color: "black"; font.bold: true; font.pixelSize: 11 }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { connectTo(modelData.ssid, passInput.text); passInput.text = ""; }
                            }
                        }
                    }
                }
            }
            Behavior on height { NumberAnimation { duration: 200 } }
        }
    }

    Rectangle {
        Layout.fillWidth: true; height: 35; color: "#111"; radius: 8
        RowLayout {
            anchors.centerIn: parent; spacing: 8
            Text { text: "󰓅"; font.family: Theme.iconFont; color: Theme.accentColor }
            Text { text: "Speed: " + currentSpeed; color: Theme.fontColor; font.pixelSize: 11 }
        }
    }

    Process { id: rfkillProc }
}
