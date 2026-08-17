import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."
import "../../../services"

Item {
    id: root
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: mainContentCol.implicitHeight

    Component.onCompleted: {
        WifiService.refresh();
    }

    // ---- LIVE REFRESH WHILE THE PANEL IS OPEN ----
    //
    // Component.onCompleted above runs once when the shell starts, not when
    // the panel opens -- this content item is built with the rest of the
    // quick-settings window and then just hidden. So opening the Wi-Fi panel
    // never triggered a scan at all: the list you saw was whatever the last
    // `nmcli monitor` event happened to leave behind, which is why it looked
    // stale or empty until you hit refresh by hand.
    //
    // `visible` alone is not enough to mean "the user is looking at this":
    // it tracks the StackLayout tab, but items in a hidden window still
    // report visible, so the panel must also be open.
    readonly property bool isShowing: root.visible && QuickSettingsService.qsVisible

    onIsShowingChanged: if (isShowing) WifiService.rescan()

    // Connection state, signal strength and IP are cheap (~70ms) so they can
    // poll briskly and keep the panel feeling live.
    Timer {
        running: root.isShowing && !WifiService.isUserTyping
        interval: 3000
        repeat: true
        onTriggered: WifiService.refresh(false)
    }

    // A full rescan drives the radio for ~5s, so it runs far less often --
    // often enough that networks appearing or disappearing show up on their
    // own, rarely enough that the adapter is not permanently scanning.
    Timer {
        running: root.isShowing && !WifiService.isUserTyping
        interval: 20000
        repeat: true
        onTriggered: WifiService.refresh(true)
    }

    property var wifiSvc: WifiService
    readonly property bool isAirplane: wifiSvc.isAirplane
    property string selectedSsid: ""
    onSelectedSsidChanged: {
        WifiService.isUserTyping = (selectedSsid !== "");
    }
    property string lastFailedSsid: ""

    property bool isInputActive: selectedSsid !== "" && !wifiSvc.knownNetworks[selectedSsid]
    onIsInputActiveChanged: WifiService.isUserTyping = isInputActive

    Connections {
        target: WifiService
        function onConnectionFailed(ssid) {
            if (ssid === selectedSsid) {
                lastFailedSsid = ssid;
            }
        }
        function onConnectionSuccess(ssid) {
            selectedSsid = "";
            lastFailedSsid = "";
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: selectedSsid = ""
    }

    ColumnLayout {
        id: mainContentCol
        anchors.fill: parent
        spacing: Theme.scaled(18)

        // --- Header & Actions ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(14)

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(12)

                ColumnLayout {
                    spacing: Theme.scaled(2)
                    Layout.fillWidth: true

                    Text {
                        text: "WIFI NETWORKS"
                        color: Theme.accentColor
                        font.pixelSize: Theme.scaled(14)
                        font.letterSpacing: 2
                        font.weight: Font.Black
                    }

                    Text {
                        text: root.isAirplane ? "AIRPLANE MODE ACTIVE" : (wifiSvc.networks.length + " NETWORKS IN RANGE")
                        color: Theme.subtext0
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                    }
                }

                // Speed Test Bubble
                Rectangle {
                    width: Theme.scaled(110)
                    height: Theme.scaled(42)
                    radius: Theme.bubbleRadiusMedium
                    color: speedMouse.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                    border.color: wifiSvc.isTesting ? Theme.powerYellow : Theme.glassBorder
                    clip: true

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Theme.scaled(6)

                        Text {
                            text: wifiSvc.isTesting ? "󱐋" : "󰓅"
                            font.family: Theme.iconFont
                            color: wifiSvc.isTesting ? Theme.powerYellow : Theme.accentColor
                            font.pixelSize: Theme.scaled(16)
                        }

                        Text {
                            text: wifiSvc.isTesting ? "TESTING" : (wifiSvc.currentSpeed === "0.0 Mbps" ? "SPEED" : wifiSvc.currentSpeed)
                            color: Theme.text
                            font.pixelSize: Theme.scaled(10)
                            font.weight: Font.Black
                        }
                    }

                    MouseArea {
                        id: speedMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: wifiSvc.runMaxSpeedTest()
                    }
                }

                // Refresh Button
                Rectangle {
                    width: Theme.scaled(42)
                    height: Theme.scaled(42)
                    radius: Theme.bubbleRadiusPill
                    color: refreshMouse.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                    border.color: Theme.glassBorder
                    clip: true

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        id: refreshIcon
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(18)
                        color: Theme.powerGreen
                    }

                    RotationAnimation {
                        target: refreshIcon
                        running: wifiSvc.isRefreshing
                        from: 0; to: 360
                        duration: 800
                        loops: Animation.Infinite
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: wifiSvc.rescan()
                    }
                }

                // Airplane Mode Toggle Button
                Rectangle {
                    width: Theme.scaled(42)
                    height: Theme.scaled(42)
                    radius: Theme.bubbleRadiusPill
                    color: root.isAirplane ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25) : (airplaneMouse.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow)
                    border.color: root.isAirplane ? Theme.powerRed : Theme.glassBorder
                    clip: true

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰀞"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(20)
                        color: root.isAirplane ? Theme.powerRed : Theme.text
                    }

                    MouseArea {
                        id: airplaneMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: wifiSvc.toggleAirplane(!root.isAirplane)
                    }
                }
            }

            // Current Active Connection Card
            Rectangle {
                Layout.fillWidth: true
                height: Theme.scaled(62)
                color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.1)
                radius: Theme.bubbleRadiusMedium
                border.color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.3)
                border.width: 1
                visible: wifiSvc.currentSsid !== ""

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.scaled(12)
                    spacing: Theme.scaled(14)

                    Rectangle {
                        width: Theme.scaled(38)
                        height: Theme.scaled(38)
                        radius: Theme.bubbleRadiusSmall
                        color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.2)

                        Text {
                            anchors.centerIn: parent
                            text: "󰤨"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(20)
                            color: Theme.powerGreen
                        }
                    }

                    ColumnLayout {
                        spacing: Theme.scaled(2)
                        Layout.fillWidth: true

                        Text {
                            text: wifiSvc.currentSsid
                            color: Theme.text
                            font.weight: Font.Bold
                            font.pixelSize: Theme.scaled(14)
                            elide: Text.ElideRight
                        }

                        Text {
                            text: wifiSvc.ipv4Address ? ("IP: " + wifiSvc.ipv4Address) : "Connected"
                            color: Theme.subtext0
                            font.pixelSize: Theme.scaled(10)
                            font.weight: Font.Bold
                        }
                    }

                    Rectangle {
                        width: Theme.scaled(85)
                        height: Theme.scaled(34)
                        radius: Theme.bubbleRadiusSmall
                        color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                        border.color: Theme.red
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "DISCONNECT"
                            font.pixelSize: Theme.scaled(9)
                            font.weight: Font.Black
                            color: Theme.powerRed
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: wifiSvc.disconnect()
                        }
                    }
                }
            }
        }

        // --- WiFi Networks List ---
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            model: wifiSvc.networks
            spacing: Theme.scaled(10)
            clip: true
            interactive: false

            delegate: FocusScope {
                id: delegateRoot
                width: list.width

                property bool isKnown: !!(modelData && modelData.isKnown)
                property bool isConnected: !!(modelData && modelData.connected)
                property bool showSecrets: false

                height: (selectedSsid === modelData.ssid && (!isKnown || showSecrets)) ? Theme.scaled(135) : Theme.scaled(62)

                Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

                Rectangle {
                    id: backgroundRect
                    anchors.fill: parent
                    color: isConnected ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.12) : (delegateMouse.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow)
                    radius: Theme.bubbleRadiusMedium
                    border.color: isConnected ? Theme.powerGreen : (selectedSsid === modelData.ssid ? Theme.accentColor : Theme.glassBorder)
                    border.width: 1
                    clip: true

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid;
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.scaled(12)
                        spacing: Theme.scaled(10)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.scaled(12)

                            Rectangle {
                                width: Theme.scaled(38)
                                height: Theme.scaled(38)
                                radius: Theme.bubbleRadiusSmall
                                color: Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    anchors.centerIn: parent
                                    text: isConnected ? "󰤨" : (modelData.signal >= 4 ? "󰤨" : (modelData.signal >= 3 ? "󰤥" : (modelData.signal >= 2 ? "󰤢" : (modelData.signal >= 1 ? "󰤟" : "󰤯"))))
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(18)
                                    color: isConnected ? Theme.powerGreen : Theme.text
                                }
                            }

                            ColumnLayout {
                                spacing: Theme.scaled(1)
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.ssid
                                    color: Theme.text
                                    font.weight: Font.Bold
                                    font.pixelSize: Theme.scaled(13)
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: isConnected ? "ACTIVE" : (isKnown ? "SAVED" : ("SIGNAL " + modelData.signalPct + "%"))
                                    color: isConnected ? Theme.powerGreen : Theme.subtext0
                                    font.pixelSize: Theme.scaled(9)
                                    font.weight: Font.Black
                                }
                            }

                            RowLayout {
                                spacing: Theme.scaled(6)

                                Rectangle {
                                    visible: isKnown
                                    width: Theme.scaled(34)
                                    height: Theme.scaled(34)
                                    radius: Theme.bubbleRadiusSmall
                                    color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                                    border.color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.4)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰆴"
                                        font.family: Theme.iconFont
                                        font.pixelSize: Theme.scaled(14)
                                        color: Theme.powerRed
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: wifiSvc.forgetNetwork(modelData.ssid)
                                    }
                                }

                                Rectangle {
                                    visible: isKnown && !isConnected
                                    width: Theme.scaled(72)
                                    height: Theme.scaled(34)
                                    radius: Theme.bubbleRadiusSmall
                                    color: Theme.accentColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: "CONNECT"
                                        font.pixelSize: Theme.scaled(9)
                                        font.weight: Font.Black
                                        color: Colors.on_primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: wifiSvc.connect(modelData.ssid, "")
                                    }
                                }

                                Rectangle {
                                    visible: !isKnown && !isConnected
                                    width: Theme.scaled(34)
                                    height: Theme.scaled(34)
                                    radius: Theme.bubbleRadiusSmall
                                    color: Qt.rgba(1, 1, 1, 0.08)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅂"
                                        font.family: Theme.iconFont
                                        font.pixelSize: Theme.scaled(14)
                                        color: Theme.text
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: selectedSsid = (selectedSsid === modelData.ssid) ? "" : modelData.ssid
                                    }
                                }
                            }
                        }

                        // Expanded Password Entry Area
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: selectedSsid === modelData.ssid && (!isKnown || showSecrets)
                            spacing: Theme.scaled(8)

                            onVisibleChanged: {
                                if (visible && !isKnown) {
                                    passInput.forceActiveFocus();
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.scaled(8)

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: Theme.scaled(38)
                                    color: Qt.rgba(0, 0, 0, 0.25)
                                    radius: Theme.bubbleRadiusSmall
                                    border.color: lastFailedSsid === modelData.ssid ? Theme.powerRed : (passInput.activeFocus ? Theme.accentColor : Theme.glassBorder)
                                    border.width: 1

                                    TextInput {
                                        id: passInput
                                        anchors.fill: parent
                                        anchors.margins: Theme.scaled(8)
                                        echoMode: showPassText.checked ? TextInput.Normal : TextInput.Password
                                        color: Theme.text
                                        font.pixelSize: Theme.scaled(12)
                                        verticalAlignment: TextInput.AlignVCenter

                                        Text {
                                            text: "Enter WiFi Password..."
                                            color: Theme.subtext0
                                            visible: !passInput.text
                                            font.pixelSize: Theme.scaled(11)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        onAccepted: {
                                            wifiSvc.connect(modelData.ssid, passInput.text);
                                        }
                                    }
                                }

                                CheckBox {
                                    id: showPassText
                                    checked: false
                                    visible: false
                                }

                                Rectangle {
                                    width: Theme.scaled(38)
                                    height: Theme.scaled(38)
                                    radius: Theme.bubbleRadiusSmall
                                    color: Qt.rgba(1, 1, 1, 0.08)

                                    Text {
                                        anchors.centerIn: parent
                                        text: showPassText.checked ? "󰈈" : "󰈉"
                                        font.family: Theme.iconFont
                                        font.pixelSize: Theme.scaled(16)
                                        color: Theme.text
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: showPassText.checked = !showPassText.checked
                                    }
                                }

                                Rectangle {
                                    width: Theme.scaled(80)
                                    height: Theme.scaled(38)
                                    radius: Theme.bubbleRadiusSmall
                                    color: Theme.accentColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: "JOIN"
                                        font.pixelSize: Theme.scaled(10)
                                        font.weight: Font.Black
                                        color: Colors.on_primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: wifiSvc.connect(modelData.ssid, passInput.text)
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
