import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: menuRoot

    property var wifiSvc: WifiService
    property var networks: wifiSvc.networks
    readonly property var knownNetworks: wifiSvc.knownNetworks
    property var anchorItem: null
    property string currentSpeed: "Scanning..."
    property bool isAirplane: false
    property string selectedSsid: ""
    property bool showPassword: false

    function connectTo(ssid, pass) {
        wifiSvc.connect(ssid, pass);
        selectedSsid = "";
    }

    function forgetNetwork(ssid) {
        console.log("MENU_DEBUG: Delegating forget request for " + ssid + " to Service.");
        wifiSvc.forgetNetwork(ssid);
        // UI state cleanup (NO STYLE CHANGES)
        if (selectedSsid === ssid)
            selectedSsid = "";

    }

    grabFocus: false

    HyprlandFocusGrab {
        active: menuRoot.visible
        // Include bar via anchorItem
        windows: [menuRoot, anchorItem ? anchorItem.QsWindow.window : null]
        onCleared: menuRoot.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            console.log("WIFI_DEBUG: Menu opened, refreshing focus and scan...");
            mainContent.forceActiveFocus();
            focusTimer.start();
            if (typeof WifiService !== "undefined")
                WifiService.scan();
        }
    }

    visible: false
    color: "transparent"
    implicitWidth: 320
    implicitHeight: 500
    anchor.window: anchorItem ? anchorItem.QsWindow.window : null
    anchor.rect: anchorItem ? anchorItem.mapToItem(null, 0, 0, anchorItem.width, anchorItem.height) : Qt.rect(0, 0, 0, 0)
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    Timer {
        id: autoScanTimer

        interval: 30000
        running: menuRoot.visible
        repeat: true
        onTriggered: wifiSvc.scan()
    }

    Timer {
        id: focusTimer

        interval: 50
        onTriggered: mainContent.forceActiveFocus()
    }

    Rectangle {
        id: mainContent

        anchors.fill: parent
        anchors.margins: 5
        radius: 12
        clip: true
        color: Theme.backgroundColor || "#111111"
        border.color: Theme.borderColor
        border.width: 1
        opacity: 0
        y: -40
        focus: true
        Component.onCompleted: openAnim.start()
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape)
                menuRoot.visible = false;
        }

        // Background area focus catch
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                mouse.accepted = true;
                mainContent.forceActiveFocus();
                console.log("WIFI_DEBUG: Click consumed by menu background");
            }
        }

        ParallelAnimation {
            id: openAnim

            NumberAnimation {
                target: mainContent
                property: "y"
                to: 0
                duration: 100
                easing.type: Easing.OutBack
            }

            NumberAnimation {
                target: mainContent
                property: "opacity"
                to: 1
                duration: 100
            }

        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
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
                    width: 30
                    height: 30
                    onClicked: {
                        menuRoot.isAirplane = !menuRoot.isAirplane;
                        rfkillProc.command = ["rfkill", menuRoot.isAirplane ? "block" : "unblock", "wifi"];
                        rfkillProc.running = true;
                    }

                    Text {
                        anchors.centerIn: parent
                        text: menuRoot.isAirplane ? "󰀝" : "󰤨"
                        font.family: Theme.iconFont
                        color: menuRoot.isAirplane ? "red" : Theme.accentColor
                        font.pixelSize: 18
                    }

                }

            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                model: menuRoot.networks
                spacing: 4
                clip: true

                delegate: Item {
                    width: list.width
                    // Dynamic height: expand if selected AND not already in knownNetworks
                    height: (selectedSsid === modelData.ssid && !knownNetworks[modelData.ssid]) ? 145 : 50

                    Column {
                        anchors.fill: parent
                        spacing: 4

                        // --- Main Network Row ---
                        Rectangle {
                            width: parent.width
                            height: 45
                            color: m.containsMouse || selectedSsid === modelData.ssid ? "#1a1a1a" : "transparent"
                            radius: 8

                            MouseArea {
                                id: m

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    mainContent.forceActiveFocus();
                                    if (knownNetworks[modelData.ssid]) {
                                        // LOGIC FIX: If we know it, just connect (pass "" to use stored pass)
                                        console.log("MENU_DEBUG: Connecting to known network: " + modelData.ssid);
                                        connectTo(modelData.ssid, "");
                                    } else {
                                        // Toggle expansion for new networks
                                        selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid;
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Text {
                                    text: modelData.security === "psk" ? "󰷛" : "󰤨"
                                    font.family: Theme.iconFont
                                    color: Theme.fontColor
                                }

                                Text {
                                    text: modelData.ssid
                                    color: Theme.fontColor
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Forget Button
                                MouseArea {
                                    id: forgetBtn

                                    width: 24
                                    height: 24
                                    hoverEnabled: true
                                    // Only show if the network is in our secrets file
                                    visible: !!knownNetworks[modelData.ssid]
                                    onClicked: {
                                        console.log("MENU_DEBUG: Forget clicked for: " + modelData.ssid);
                                        forgetNetwork(modelData.ssid);
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󱘖"
                                        font.family: Theme.iconFont
                                        color: forgetBtn.containsMouse ? "white" : "red"
                                    }

                                }

                            }

                        }

                        // --- Expanded Password Field ---
                        Rectangle {
                            width: parent.width
                            // Only show if selected and NOT known
                            height: (selectedSsid === modelData.ssid && !knownNetworks[modelData.ssid]) ? 90 : 0
                            visible: height > 0
                            clip: true
                            color: "#0a0a0a"
                            radius: 8

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                RowLayout {
                                    TextInput {
                                        id: passInput

                                        Layout.fillWidth: true
                                        color: "white"
                                        echoMode: showPassword ? TextInput.Normal : TextInput.Password
                                        focus: parent.visible && selectedSsid === modelData.ssid
                                        onVisibleChanged: {
                                            if (visible)
                                                forceActiveFocus();

                                        }

                                        Text {
                                            text: "Enter Password..."
                                            color: "#444"
                                            visible: !passInput.text
                                        }

                                    }

                                    MouseArea {
                                        width: 24
                                        height: 24
                                        onClicked: showPassword = !showPassword

                                        Text {
                                            anchors.centerIn: parent
                                            text: showPassword ? "󰈈" : "󰈉"
                                            font.family: Theme.iconFont
                                            color: Theme.accentColor
                                        }

                                    }

                                }

                                // Connect Button for New Networks
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 32
                                    color: Theme.accentColor
                                    radius: 6

                                    Text {
                                        anchors.centerIn: parent
                                        text: "CONNECT"
                                        color: "black"
                                        font.bold: true
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            // LOGIC FIX: Pass the actual typed password
                                            console.log("MENU_DEBUG: Connect clicked with manual password for: " + modelData.ssid);
                                            connectTo(modelData.ssid, passInput.text);
                                            passInput.text = ""; // Clear the field after click
                                        }
                                    }

                                }

                            }

                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                        }

                    }

                }

            }

            Rectangle {
                Layout.fillWidth: true
                height: 35
                color: "#111"
                radius: 8

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "󰓅"
                        font.family: Theme.iconFont
                        color: Theme.accentColor
                    }

                    Text {
                        text: "Speed: " + currentSpeed
                        color: Theme.fontColor
                        font.pixelSize: 11
                    }

                }

            }

        }

    }

    Process {
        id: rfkillProc
    }

    Process {
        id: speedTest

        command: ["sh", "-c", "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 - --simple | grep Download"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text)
                    menuRoot.currentSpeed = text.replace("Download: ", "").trim();

            }
        }

    }

}
