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

    // Cached list first so the panel is populated immediately, then the real
    // scan a moment later to pick up anything new. Same idea as the mail tab
    // painting its cache before the network answers.
    onIsShowingChanged: {
        if (isShowing) {
            WifiService.listCached();
            firstScan.restart();
        } else {
            selectedSsid = "";
        }
    }

    Connections {
        target: QuickSettingsService
        function onQsVisibleChanged() {
            if (!QuickSettingsService.qsVisible) {
                selectedSsid = "";
            }
        }
        function onActiveTabChanged() {
            selectedSsid = "";
        }
    }

    // Outer click background catcher to de-expand
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: selectedSsid = ""
    }

    Timer {
        id: firstScan
        interval: 400
        repeat: false
        onTriggered: if (root.isShowing) WifiService.rescan()
    }

    // Connection state, signal strength and IP are cheap (~14ms) so they can
    // poll briskly and keep the panel feeling live.
    Timer {
        running: root.isShowing && !WifiService.isUserTyping
        interval: 3000
        repeat: true
        onTriggered: WifiService.listCached()
    }

    // A full rescan drives the radio for ~5s, so it runs far less often --
    // often enough that networks appearing or disappearing show up on their
    // own, rarely enough that the adapter is not permanently scanning.
    Timer {
        running: root.isShowing && !WifiService.isUserTyping && root.selectedSsid === ""
        interval: 20000
        repeat: true
        onTriggered: WifiService.refresh(true)
    }

    property var wifiSvc: WifiService
    readonly property bool isAirplane: wifiSvc.isAirplane
    property string selectedSsid: ""
    onSelectedSsidChanged: {
        if (selectedSsid === "") {
            WifiService.isUserTyping = false;
        }
    }
    property string lastFailedSsid: ""

    property bool isInputActive: false
    onIsInputActiveChanged: WifiService.isUserTyping = isInputActive

    property int selectedIndex: 0

    function handleKeys(event) {
        if (isInputActive) return; // Typing password, don't hijack keys
        let nets = wifiSvc.networks || [];
        if (nets.length === 0) return;

        if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            selectedIndex = Math.min(nets.length - 1, selectedIndex + 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            selectedIndex = Math.max(0, selectedIndex - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (selectedIndex >= 0 && selectedIndex < nets.length) {
                let targetNet = nets[selectedIndex];
                if (targetNet) {
                    if (targetNet.isKnown && !targetNet.connected) {
                        wifiSvc.connect(targetNet.ssid, "");
                    } else {
                        selectedSsid = (selectedSsid === targetNet.ssid) ? "" : targetNet.ssid;
                    }
                    event.accepted = true;
                }
            }
        }
    }

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
        spacing: Theme.scaled(14)

        // --- Minimal Header Row (Buttons at start, network count on right) ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(8)

            // Refresh Button
            Rectangle {
                width: Theme.scaled(38)
                height: Theme.scaled(38)
                radius: Theme.bubbleRadiusPill
                color: refreshMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                border.color: wifiSvc.isRefreshing ? Theme.powerGreen : Theme.glassBorder
                border.width: 1

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
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedSsid = "";
                        wifiSvc.isUserTyping = false;
                        wifiSvc.rescan();
                    }
                }
            }

            // Speed Test Button
            Rectangle {
                height: Theme.scaled(38)
                implicitWidth: speedRow.implicitWidth + Theme.scaled(20)
                radius: Theme.bubbleRadiusPill
                color: speedMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                border.color: wifiSvc.isTesting ? Theme.powerYellow : Theme.glassBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    id: speedRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(6)

                    Text {
                        text: wifiSvc.isTesting ? "" : "󰓅"
                        font.family: Theme.iconFont
                        color: wifiSvc.isTesting ? Theme.powerYellow : Theme.accentColor
                        font.pixelSize: Theme.scaled(18)
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
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wifiSvc.runMaxSpeedTest()
                }
            }

            // Airplane Mode Toggle Button
            Rectangle {
                width: Theme.scaled(38)
                height: Theme.scaled(38)
                radius: Theme.bubbleRadiusPill
                color: root.isAirplane ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25) : (airplaneMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
                border.color: root.isAirplane ? Theme.powerRed : Theme.glassBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "󰀞"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(18)
                    color: root.isAirplane ? Theme.powerRed : Theme.text
                }

                MouseArea {
                    id: airplaneMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wifiSvc.toggleAirplane(!root.isAirplane)
                }
            }

            Item { Layout.fillWidth: true }

            // Network Count on Right
            RowLayout {
                spacing: Theme.scaled(6)
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "󰑐"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(12)
                    color: Theme.accentColor
                    visible: wifiSvc.isRefreshing || wifiSvc.isConnecting
                    RotationAnimator on rotation {
                        from: 0; to: 360; duration: 900; loops: Animation.Infinite
                        running: wifiSvc.isRefreshing || wifiSvc.isConnecting
                    }
                }

                Text {
                    text: root.isAirplane ? "Airplane Mode"
                        : (wifiSvc.isConnecting ? ("Connecting to " + wifiSvc.connectingSsid + "...")
                        : (wifiSvc.networks.length === 0 && wifiSvc.isRefreshing ? "Scanning..."
                        : (wifiSvc.networks.length + (wifiSvc.networks.length === 1 ? " Network" : " Networks"))))
                    color: wifiSvc.isConnecting ? Theme.accentColor : Theme.subtext0
                    font.pixelSize: Theme.scaled(11)
                    font.weight: Font.Bold
                }
            }
        }

        // --- Connector / Connecting State Banner ---
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(44)
            radius: Theme.bubbleRadiusMedium
            color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.15)
            border.color: Theme.accentColor
            border.width: 1
            visible: wifiSvc.isConnecting

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(14)
                anchors.rightMargin: Theme.scaled(14)
                spacing: Theme.scaled(10)

                Text {
                    text: "󱚵"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(18)
                    color: Theme.accentColor

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: wifiSvc.isConnecting
                        NumberAnimation { from: 0.3; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.0; to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(2)

                    Text {
                        text: "Connecting to " + wifiSvc.connectingSsid
                        color: Theme.text
                        font.pixelSize: Theme.scaled(12)
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Authenticating and acquiring IP configuration..."
                        color: Theme.subtext0
                        font.pixelSize: Theme.scaled(10)
                    }
                }

                Text {
                    text: "󰑐"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(14)
                    color: Theme.accentColor
                    RotationAnimator on rotation {
                        from: 0; to: 360; duration: 900; loops: Animation.Infinite
                        running: wifiSvc.isConnecting
                    }
                }
            }
        }

        // --- Skeleton Network Loaders while scanning ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(10)
            visible: wifiSvc.networks.length === 0 && wifiSvc.isRefreshing && !root.isAirplane

            Repeater {
                model: 4
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: Theme.scaled(62)
                    radius: Theme.bubbleRadiusMedium
                    color: Theme.cardBackground
                    border.color: Theme.glassBorder
                    border.width: 1

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.35; to: 0.75; duration: 800 + index * 100; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.75; to: 0.35; duration: 800 + index * 100; easing.type: Easing.InOutSine }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.scaled(14)
                        anchors.rightMargin: Theme.scaled(14)
                        spacing: Theme.scaled(12)

                        Rectangle {
                            width: Theme.scaled(32)
                            height: Theme.scaled(32)
                            radius: width / 2
                            color: Qt.rgba(255, 255, 255, 0.08)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.scaled(6)

                            Rectangle {
                                width: Theme.scaled(110 + (index * 25) % 60)
                                height: Theme.scaled(12)
                                radius: Theme.scaled(4)
                                color: Qt.rgba(255, 255, 255, 0.12)
                            }

                            Rectangle {
                                width: Theme.scaled(60 + (index * 15) % 40)
                                height: Theme.scaled(8)
                                radius: Theme.scaled(3)
                                color: Qt.rgba(255, 255, 255, 0.06)
                            }
                        }

                        Rectangle {
                            width: Theme.scaled(28)
                            height: Theme.scaled(12)
                            radius: Theme.scaled(3)
                            color: Qt.rgba(255, 255, 255, 0.08)
                        }
                    }
                }
            }
        }

        // --- Empty State & Helper Text ---
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(130)
            color: "transparent"
            visible: wifiSvc.networks.length === 0 && !wifiSvc.isRefreshing

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.scaled(8)

                Text {
                    text: root.isAirplane ? "󰀝" : "󰤮"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(34)
                    color: root.isAirplane ? Theme.powerRed : Theme.subtext0
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: root.isAirplane ? "AIRPLANE MODE ENABLED" : "NO WI-FI NETWORKS FOUND"
                    color: Theme.text
                    font.pixelSize: Theme.scaled(12)
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: root.isAirplane
                        ? "Wireless communication is turned off. Toggle airplane mode off to connect."
                        : "Ensure your Wi-Fi interface is on and in range, or click Refresh to scan again."
                    color: Theme.subtext0
                    font.pixelSize: Theme.scaled(10)
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // --- WiFi Networks List ---
        ListView {
            FastWheel {}
            id: list
            Layout.fillWidth: true
            implicitHeight: contentHeight
            Layout.preferredHeight: contentHeight
            model: wifiSvc.networks
            spacing: Theme.scaled(10)
            interactive: false

            delegate: FocusScope {
                id: delegateRoot
                width: list.width

                property bool isKnown: !!(modelData && modelData.isKnown)
                readonly property bool isConnected: (modelData && modelData.ssid === wifiSvc.currentSsid && wifiSvc.currentState === "connected") || !!(modelData && modelData.connected && wifiSvc.currentState === "connected")
                readonly property bool isExpanded: selectedSsid === modelData.ssid
                property string knownPass: (modelData && modelData.password) || (wifiSvc.knownPasswords && wifiSvc.knownPasswords[modelData.ssid]) || ""

                Process {
                    id: fetchPassProc
                    command: ["python3", wifiSvc.helperScript, "get_password", modelData.ssid]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let p = text.trim();
                            if (p) {
                                modelData.password = p;
                                if (!passInput.text) passInput.text = p;
                            }
                        }
                    }
                }

                onIsExpandedChanged: {
                    if (isExpanded && isKnown && !passInput.text) {
                        fetchPassProc.running = true;
                    }
                }

                height: isExpanded ? (isConnected ? Theme.scaled(156) : Theme.scaled(112)) : Theme.scaled(62)

                Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

                Rectangle {
                    id: backgroundRect
                    anchors.fill: parent
                    color: isConnected ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.18) : ((headerMouse.containsMouse || root.selectedIndex === index) ? Theme.cardBackgroundHover : Theme.cardBackground)
                    radius: Theme.bubbleRadiusMedium
                    border.color: isConnected ? Theme.powerGreen : ((isExpanded || root.selectedIndex === index) ? Theme.accentColor : Theme.glassBorder)
                    border.width: 1
                    clip: true

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    // Clicking the top header area expands/collapses the network card
                    MouseArea {
                        id: headerMouse
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Theme.scaled(62)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = index
                        onClicked: {
                            root.selectedIndex = index;
                            selectedSsid = isExpanded ? "" : modelData.ssid;
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.scaled(12)
                        spacing: Theme.scaled(10)

                        RowLayout {
                            width: parent.width
                            Layout.fillWidth: true
                            Layout.preferredWidth: parent.width
                            spacing: Theme.scaled(12)

                            Rectangle {
                                width: Theme.scaled(38)
                                height: Theme.scaled(38)
                                radius: Theme.bubbleRadiusSmall
                                color: "transparent"
                                border.width: 0

                                Text {
                                    anchors.centerIn: parent
                                    text: isConnected ? "󰤨" : (modelData.signal >= 4 ? "󰤨" : (modelData.signal >= 3 ? "󰤥" : (modelData.signal >= 2 ? "󰤢" : (modelData.signal >= 1 ? "󰤟" : "󰤯"))))
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(22)
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
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: isConnected
                                        ? "Connected"
                                        : (wifiSvc.isConnecting && modelData && modelData.ssid === wifiSvc.connectingSsid
                                            ? "Connecting..."
                                            : (isKnown ? "Saved" : ("Signal " + modelData.signalPct + "%")))
                                    color: isConnected ? Theme.powerGreen : (wifiSvc.isConnecting && modelData && modelData.ssid === wifiSvc.connectingSsid ? Theme.accentColor : Theme.subtext0)
                                    font.pixelSize: Theme.scaled(9)
                                    font.weight: Font.Bold
                                    Layout.fillWidth: true
                                }
                            }

                            // Sticky-to-the-right Arrow Button (only element on the right of device row)
                            Rectangle {
                                width: Theme.scaled(34)
                                height: Theme.scaled(34)
                                radius: Theme.bubbleRadiusSmall
                                color: arrowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                                border.width: 0
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                Text {
                                    id: arrowIcon
                                    anchors.centerIn: parent
                                    text: "󰅂"
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(15)
                                    color: isConnected ? Theme.powerGreen : Theme.text
                                    rotation: isExpanded ? 90 : 0
                                    Behavior on rotation { NumberAnimation { duration: Theme.animFast } }
                                }

                                MouseArea {
                                    id: arrowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        selectedSsid = isExpanded ? "" : modelData.ssid;
                                    }
                                }
                            }
                        }

                        // --- Expanded Content: Multiple Rows ---
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: isExpanded
                            spacing: Theme.scaled(10)

                            onVisibleChanged: {
                                if (visible && !isConnected && !isKnown) {
                                    passInput.forceActiveFocus();
                                }
                            }

                            // If Connected: Row 2 (IP info + Action buttons) & Row 3 (Password)
                            ColumnLayout {
                                width: parent.width
                                Layout.fillWidth: true
                                Layout.preferredWidth: parent.width
                                visible: isConnected
                                spacing: Theme.scaled(10)

                                // Row 2: Connection & IP info on left + Action buttons on right
                                RowLayout {
                                    width: parent.width
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: parent.width
                                    spacing: Theme.scaled(8)

                                    // IP & Security Capsule
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: Theme.scaled(34)
                                        radius: Theme.bubbleRadiusSmall
                                        color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.1)
                                        border.color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.25)
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Theme.scaled(10)
                                            anchors.rightMargin: Theme.scaled(10)
                                            spacing: Theme.scaled(8)

                                            Text {
                                                text: "󰩠"
                                                font.family: Theme.iconFont
                                                font.pixelSize: Theme.scaled(14)
                                                color: Theme.powerGreen
                                            }

                                            Text {
                                                text: wifiSvc.ipv4Address ? ("IP: " + wifiSvc.ipv4Address) : "Connected"
                                                color: Theme.text
                                                font.pixelSize: Theme.scaled(11)
                                                font.weight: Font.Bold
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: (modelData.security ? modelData.security.toUpperCase() : "WPA2") + " • " + modelData.signalPct + "%"
                                                color: Theme.subtext0
                                                font.pixelSize: Theme.scaled(10)
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }

                                    // Forget button
                                    Rectangle {
                                        visible: isKnown
                                        height: Theme.scaled(34)
                                        implicitWidth: connForgetRow.implicitWidth + Theme.scaled(20)
                                        radius: Theme.bubbleRadiusSmall
                                        color: connForgetMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.3) : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                                        border.color: Theme.red
                                        border.width: 1

                                        RowLayout {
                                            id: connForgetRow
                                            anchors.centerIn: parent
                                            spacing: Theme.scaled(6)

                                            Text {
                                                text: "󰆴"
                                                font.family: Theme.iconFont
                                                font.pixelSize: Theme.scaled(14)
                                                color: Theme.powerRed
                                            }

                                            Text {
                                                text: "FORGET"
                                                font.pixelSize: Theme.scaled(9)
                                                font.weight: Font.Black
                                                color: Theme.powerRed
                                            }
                                        }

                                        MouseArea {
                                            id: connForgetMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                wifiSvc.forgetNetwork(modelData.ssid);
                                                selectedSsid = "";
                                            }
                                        }
                                    }

                                    // Disconnect button
                                    Rectangle {
                                        height: Theme.scaled(34)
                                        implicitWidth: disconnRow.implicitWidth + Theme.scaled(24)
                                        radius: Theme.bubbleRadiusSmall
                                        color: disconnMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25) : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                                        border.color: Theme.red
                                        border.width: 1

                                        RowLayout {
                                            id: disconnRow
                                            anchors.centerIn: parent
                                            spacing: Theme.scaled(6)

                                            Text {
                                                text: "󰅖"
                                                font.family: Theme.iconFont
                                                font.pixelSize: Theme.scaled(12)
                                                color: Theme.powerRed
                                            }

                                            Text {
                                                text: "DISCONNECT"
                                                font.pixelSize: Theme.scaled(9)
                                                font.weight: Font.Black
                                                color: Theme.powerRed
                                            }
                                        }

                                        MouseArea {
                                            id: disconnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                wifiSvc.disconnect();
                                                selectedSsid = "";
                                            }
                                        }
                                    }
                                }

                                // Row 3: Connected Network Password Display
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: Theme.scaled(36)
                                    radius: Theme.bubbleRadiusSmall
                                    color: Qt.rgba(0, 0, 0, 0.22)
                                    border.color: Theme.glassBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.scaled(10)
                                        anchors.rightMargin: Theme.scaled(10)
                                        spacing: Theme.scaled(8)

                                        Text {
                                            text: "󰌆"
                                            font.family: Theme.iconFont
                                            font.pixelSize: Theme.scaled(14)
                                            color: Theme.accentColor
                                        }

                                        Text {
                                            text: "Password:"
                                            color: Theme.subtext0
                                            font.pixelSize: Theme.scaled(10)
                                            font.weight: Font.Bold
                                        }

                                        Text {
                                            property string psk: wifiSvc.currentPassword || (modelData && modelData.password) || ""
                                            text: psk ? (showConnPass.checked ? psk : "••••••••••••") : (modelData.security && modelData.security !== "open" ? "Unavailable" : "(Open / No Password)")
                                            color: Theme.text
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: Theme.scaled(11)
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        CheckBox {
                                            id: showConnPass
                                            checked: false
                                            visible: false
                                        }

                                        // Eye button to toggle visible password
                                        Rectangle {
                                            visible: !!(wifiSvc.currentPassword || (modelData && modelData.password))
                                            width: Theme.scaled(28)
                                            height: Theme.scaled(28)
                                            radius: Theme.scaled(6)
                                            color: eyeConnMouse.containsMouse ? Theme.cardBackgroundHover : "transparent"
                                            border.width: 0

                                            Text {
                                                anchors.centerIn: parent
                                                text: showConnPass.checked ? "󰈈" : "󰈉"
                                                font.family: Theme.iconFont
                                                font.pixelSize: Theme.scaled(15)
                                                color: showConnPass.checked ? Theme.accentColor : Theme.subtext0
                                            }

                                            MouseArea {
                                                id: eyeConnMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: showConnPass.checked = !showConnPass.checked
                                            }
                                        }

                                        // Copy password button
                                        Rectangle {
                                            id: copyBtn
                                            visible: !!(wifiSvc.currentPassword || (modelData && modelData.password))
                                            property bool copied: false
                                            width: Theme.scaled(28)
                                            height: Theme.scaled(28)
                                            radius: Theme.scaled(6)
                                            color: copyMouse.containsMouse ? Theme.cardBackgroundHover : "transparent"
                                            border.width: 0

                                            Text {
                                                anchors.centerIn: parent
                                                text: copyBtn.copied ? "󰄬" : "󰆏"
                                                font.family: Theme.iconFont
                                                font.pixelSize: Theme.scaled(14)
                                                color: copyBtn.copied ? Theme.powerGreen : Theme.subtext0
                                            }

                                            MouseArea {
                                                id: copyMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    let p = wifiSvc.currentPassword || (modelData && modelData.password) || "";
                                                    if (p) {
                                                        copyProc.command = ["wl-copy", "--", p];
                                                        copyProc.running = true;
                                                        copyBtn.copied = true;
                                                        copyTimer.restart();
                                                    }
                                                }
                                            }

                                            Timer {
                                                id: copyTimer
                                                interval: 2000
                                                onTriggered: copyBtn.copied = false
                                            }

                                            Process { id: copyProc }
                                        }
                                    }
                                }
                            }

                            // If NOT Connected: Row 2 (Password input & Action buttons in 1 row)
                            RowLayout {
                                width: parent.width
                                Layout.fillWidth: true
                                Layout.preferredWidth: parent.width
                                visible: !isConnected
                                spacing: Theme.scaled(8)

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: Theme.scaled(36)
                                    color: Qt.rgba(0, 0, 0, 0.25)
                                    radius: Theme.bubbleRadiusSmall
                                    border.color: lastFailedSsid === modelData.ssid ? Theme.powerRed : (passInput.activeFocus ? Theme.accentColor : Theme.glassBorder)
                                    border.width: 1

                                    TextInput {
                                        id: passInput
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.scaled(10)
                                        anchors.rightMargin: Theme.scaled(10)
                                        echoMode: showPassText.checked ? TextInput.Normal : TextInput.Password
                                        color: Theme.text
                                        font.pixelSize: Theme.scaled(12)
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: knownPass

                                        Text {
                                            text: isKnown ? (knownPass ? "" : "Saved network...") : "Enter WiFi Password..."
                                            color: Theme.subtext0
                                            visible: !passInput.text
                                            font.pixelSize: Theme.scaled(11)
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                        }

                                        onActiveFocusChanged: {
                                            WifiService.isUserTyping = passInput.activeFocus;
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

                                // Show Password Toggle Button
                                Rectangle {
                                    width: Theme.scaled(36)
                                    height: Theme.scaled(36)
                                    radius: Theme.bubbleRadiusSmall
                                    color: eyeMouse.containsMouse ? Theme.cardBackgroundHover : Qt.rgba(1, 1, 1, 0.08)
                                    border.color: showPassText.checked ? Theme.accentColor : Theme.glassBorder
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: showPassText.checked ? "󰈈" : "󰈉"
                                        font.family: Theme.iconFont
                                        font.pixelSize: Theme.scaled(16)
                                        color: showPassText.checked ? Theme.accentColor : Theme.text
                                    }

                                    MouseArea {
                                        id: eyeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: showPassText.checked = !showPassText.checked
                                    }
                                }

                                // Copy password button (Shown when there is a saved password)
                                Rectangle {
                                    id: expCopyBtn
                                    visible: isKnown && !!passInput.text
                                    property bool copied: false
                                    width: Theme.scaled(36)
                                    height: Theme.scaled(36)
                                    radius: Theme.bubbleRadiusSmall
                                    color: expCopyMouse.containsMouse ? Theme.cardBackgroundHover : Qt.rgba(1, 1, 1, 0.08)
                                    border.color: Theme.glassBorder
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: expCopyBtn.copied ? "󰄬" : "󰆏"
                                        font.family: Theme.iconFont
                                        font.pixelSize: Theme.scaled(15)
                                        color: expCopyBtn.copied ? Theme.powerGreen : Theme.subtext0
                                    }

                                    MouseArea {
                                        id: expCopyMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (passInput.text) {
                                                expCopyProc.command = ["wl-copy", "--", passInput.text];
                                                expCopyProc.running = true;
                                                expCopyBtn.copied = true;
                                                expCopyTimer.restart();
                                            }
                                        }
                                    }

                                    Timer {
                                        id: expCopyTimer
                                        interval: 2000
                                        onTriggered: expCopyBtn.copied = false
                                    }

                                    Process { id: expCopyProc }
                                }

                                // Forget button (if known/saved)
                                Rectangle {
                                    visible: isKnown
                                    height: Theme.scaled(36)
                                    implicitWidth: expForgetRow.implicitWidth + Theme.scaled(20)
                                    radius: Theme.bubbleRadiusSmall
                                    color: expForgetMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.3) : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                                    border.color: Theme.red
                                    border.width: 1

                                    RowLayout {
                                        id: expForgetRow
                                        anchors.centerIn: parent
                                        spacing: Theme.scaled(6)

                                        Text {
                                            text: "󰆴"
                                            font.family: Theme.iconFont
                                            font.pixelSize: Theme.scaled(14)
                                            color: Theme.powerRed
                                        }

                                        Text {
                                            text: "FORGET"
                                            font.pixelSize: Theme.scaled(9)
                                            font.weight: Font.Black
                                            color: Theme.powerRed
                                        }
                                    }

                                    MouseArea {
                                        id: expForgetMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            wifiSvc.forgetNetwork(modelData.ssid);
                                            selectedSsid = "";
                                        }
                                    }
                                }

                                // Connect / Join button
                                Rectangle {
                                    height: Theme.scaled(36)
                                    implicitWidth: expConnRow.implicitWidth + Theme.scaled(24)
                                    radius: Theme.bubbleRadiusSmall
                                    color: expConnMouse.containsMouse ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.85) : Theme.accentColor

                                    RowLayout {
                                        id: expConnRow
                                        anchors.centerIn: parent
                                        spacing: Theme.scaled(6)

                                        Text {
                                            text: "󰤨"
                                            font.family: Theme.iconFont
                                            font.pixelSize: Theme.scaled(14)
                                            color: Colors.on_primary
                                        }

                                        Text {
                                            text: (isKnown && !passInput.text) ? "CONNECT" : "JOIN"
                                            font.pixelSize: Theme.scaled(9)
                                            font.weight: Font.Black
                                            color: Colors.on_primary
                                        }
                                    }

                                    MouseArea {
                                        id: expConnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: wifiSvc.connect(modelData.ssid, passInput.text)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Takes whatever the page has left over, so the header and the list
        // hug the top. Without it a short list (or no list yet, on the first
        // open) was stretched out and the content floated in the middle.
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            MouseArea {
                anchors.fill: parent
                onClicked: selectedSsid = ""
            }
        }
    }
}
