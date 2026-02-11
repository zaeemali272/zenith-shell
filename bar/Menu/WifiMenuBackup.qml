// bar/Right/Menu/WifiMenu.qml
import ".."
import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: menuRoot

    property var networks: []
    property var knownNetworks: ({
    })
    property var anchorItem: null
    property string currentSpeed: "Scanning..."
    property bool isAirplane: false
    property string selectedSsid: ""
    property bool showPassword: false

    // Logic Functions
    function connectTo(ssid, pass) {
        let password = pass || knownNetworks[ssid] || "";
        if (password !== "") {
            executor.command = ["sh", "-c", `echo "${password}" | iwctl station wlan0 connect "${ssid}"`];
            if (!knownNetworks[ssid]) {
                let temp = Object.assign({
                }, knownNetworks);
                temp[ssid] = password;
                knownNetworks = temp;
                saveSecretsData();
            }
        } else {
            executor.command = ["iwctl", "station", "wlan0", "connect", ssid];
        }
        executor.running = true;
        selectedSsid = "";
    }

    function forgetNetwork(ssid) {
        let temp = Object.assign({
        }, knownNetworks);
        delete temp[ssid];
        knownNetworks = temp;
        saveSecretsData();
    }

    function saveSecretsData() {
        saveSecretsProc.command = ["sh", "-c", `echo '${JSON.stringify(knownNetworks)}' > ${Quickshell.configPath}/wifi_secrets.json`];
        saveSecretsProc.running = true;
    }

    // Loader handles creation, so we start visible
    visible: true
    color: "transparent"
    implicitWidth: 320
    implicitHeight: 500
    // POSITIONING
    anchor.window: anchorItem ? anchorItem.QsWindow.window : null
    anchor.rect: anchorItem ? anchorItem.mapToItem(null, 0, 0, anchorItem.width, anchorItem.height) : Qt.rect(0, 0, 0, 0)
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    Component.onCompleted: initSecrets.running = true
    onVisibleChanged: {
        if (visible)
            focusTimer.start();

    }

    // This destroys the window entirely when you click away, fixing the ghosting
    HyprlandFocusGrab {
        active: true
        onCleared: {
            if (wifiLoader)
                wifiLoader.active = false;

        }
    }

    Timer {
        id: focusTimer

        interval: 10
        onTriggered: mainContent.forceActiveFocus()
    }

    // UI CONTENT
    Rectangle {
        id: mainContent

        anchors.fill: parent
        anchors.margins: 5
        radius: 12
        clip: true
        color: Theme.backgroundColor || "#111111"
        border.color: Theme.borderColor
        border.width: 1
        // ANIMATION START POINT
        opacity: 0
        y: -40
        Component.onCompleted: {
            openAnim.start();
        }
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                if (wifiLoader)
                    wifiLoader.active = false;

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
                spacing: 8
                clip: true

                delegate: Item {
                    width: list.width
                    height: (selectedSsid === modelData.ssid && !knownNetworks[modelData.ssid]) ? 145 : 50

                    Column {
                        anchors.fill: parent
                        spacing: 4

                        Rectangle {
                            width: parent.width
                            height: 45
                            color: m.containsMouse || selectedSsid === modelData.ssid ? "#1a1a1a" : "transparent"
                            radius: 8

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

                                MouseArea {
                                    width: 20
                                    height: 20
                                    visible: !!knownNetworks[modelData.ssid]
                                    onClicked: forgetNetwork(modelData.ssid)

                                    Text {
                                        text: "󱘖"
                                        font.family: Theme.iconFont
                                        color: "red"
                                    }

                                }

                            }

                            MouseArea {
                                id: m

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    mainContent.forceActiveFocus();
                                    if (knownNetworks[modelData.ssid])
                                        connectTo(modelData.ssid);
                                    else
                                        selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid;
                                }
                            }

                        }

                        Rectangle {
                            width: parent.width
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
                                        onClicked: connectTo(modelData.ssid, passInput.text)
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

    // Backend Processes
    Process {
        id: rfkillProc
    }

    Process {
        id: executor
    }

    Process {
        id: saveSecretsProc
    }

    Process {
        id: initSecrets

        command: ["sh", "-c", `[ ! -f ${Quickshell.configPath}/wifi_secrets.json ] && echo "{}" > ${Quickshell.configPath}/wifi_secrets.json; cat ${Quickshell.configPath}/wifi_secrets.json`]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text.trim())
                        menuRoot.knownNetworks = JSON.parse(text);

                } catch (e) {
                }
            }
        }

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

    Process {
        id: listProcess

        command: ["sh", "-c", "iwctl station wlan0 get-networks | sed 's/\\x1b\\[[0-9;]*m//g' | awk 'NR>4 {print $0}'"]
        running: true // List networks as soon as window is created

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n");
                let temp = [];
                for (let line of lines) {
                    let clean = line.replace('>', '').trim();
                    let parts = clean.split(/\s\s+/);
                    if (parts.length >= 2)
                        temp.push({
                        "ssid": parts[0].trim(),
                        "security": parts[1].trim().toLowerCase()
                    });

                }
                menuRoot.networks = temp;
            }
        }

    }

}
