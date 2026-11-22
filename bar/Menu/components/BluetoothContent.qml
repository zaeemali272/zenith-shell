import "../.."
import "../../../"
import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: BluetoothService.serviceActive ? (mainCol.implicitHeight + (emptyState.visible ? emptyState.implicitHeight : 0)) : (serviceErrorView.visible ? serviceErrorView.implicitHeight : 250)

    property bool showUnnamed: false
    property string selectedAddress: ""
    onSelectedAddressChanged: {
        BluetoothService.isInteracting = (selectedAddress !== "");
        if (selectedAddress !== "") {
            BluetoothService.stopScan();
        }
    }

    readonly property bool isShowing: root.visible && QuickSettingsService.qsVisible
    onIsShowingChanged: {
        if (isShowing) {
            BluetoothService.refresh(true);
            if (BluetoothService.powered) {
                BluetoothService.startScan();
            }
        } else {
            root.selectedAddress = "";
            BluetoothService.isInteracting = false;
            BluetoothService.stopScan();
        }
    }

    Connections {
        target: QuickSettingsService
        function onQsVisibleChanged() {
            if (!QuickSettingsService.qsVisible) {
                root.selectedAddress = "";
                BluetoothService.isInteracting = false;
                BluetoothService.stopScan();
            }
        }
        function onActiveTabChanged() {
            root.selectedAddress = "";
            BluetoothService.isInteracting = false;
            if (QuickSettingsService.activeTab !== "bluetooth") {
                BluetoothService.stopScan();
            }
        }
    }

    // Outer click background catcher to de-expand
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.selectedAddress = ""
    }

    Timer {
        running: root.isShowing && root.selectedAddress === "" && !BluetoothService.isInteracting
        interval: 3000
        repeat: true
        onTriggered: BluetoothService.refresh(true)
    }

    Component.onCompleted: {
        BluetoothService.refresh();
    }

    function getDeviceIcon(iconName) {
        if (!iconName) return "󰂯";
        let low = iconName.toLowerCase();
        if (low.includes("audio-card")) return "󰓃";
        if (low.includes("audio-headset") || low.includes("headphone")) return "󰋋";
        if (low.includes("keyboard")) return "󰌌";
        if (low.includes("mouse")) return "󰍽";
        if (low.includes("phone")) return "󰏲";
        if (low.includes("display")) return "󰍹";
        if (low.includes("computer")) return "󰟀";
        return "󰂯";
    }

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.scaled(14)
        visible: BluetoothService.serviceActive

        // --- Minimal Header Row (Buttons at start, device count on right) ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(8)

            // Refresh Button (Triggers full status update + discovery scan for devices in range)
            Rectangle {
                id: refreshBtn
                readonly property bool spinning: BluetoothService.userBusy || BluetoothService.scanning

                width: Theme.scaled(38)
                height: Theme.scaled(38)
                radius: Theme.bubbleRadiusPill
                color: refreshMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                border.color: spinning ? Theme.powerYellow : Theme.glassBorder
                border.width: 1
                visible: BluetoothService.powered

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Text {
                    id: refreshIcon
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(18)
                    color: refreshBtn.spinning ? Theme.powerYellow : Theme.powerGreen
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                RotationAnimation {
                    target: refreshIcon
                    running: refreshBtn.spinning
                    from: 0; to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) refreshIcon.rotation = 0
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedAddress = "";
                        BluetoothService.isInteracting = false;
                        BluetoothService.refresh(true, true);
                        if (BluetoothService.powered) {
                            BluetoothService.startScan();
                        }
                    }
                }
            }

            // Power Toggle Button
            Rectangle {
                width: Theme.scaled(38)
                height: Theme.scaled(38)
                radius: Theme.bubbleRadiusPill
                color: BluetoothService.powered
                       ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.18)
                       : (powerMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
                border.color: BluetoothService.powered ? Theme.accentColor : Theme.glassBorder
                border.width: 1
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: BluetoothService.powered ? "󰂯" : "󰂲"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(18)
                    color: BluetoothService.powered ? Theme.accentColor : Theme.powerRed
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothService.togglePower()
                }
            }

            Item { Layout.fillWidth: true }

            // Device Count on Right
            RowLayout {
                spacing: Theme.scaled(6)
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "󰑐"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(12)
                    color: Theme.accentColor
                    visible: BluetoothService.scanning || BluetoothService.isPerformingAction
                    RotationAnimator on rotation {
                        from: 0; to: 360; duration: 900; loops: Animation.Infinite
                        running: BluetoothService.scanning || BluetoothService.isPerformingAction
                    }
                }

                Text {
                    text: !BluetoothService.powered ? "Bluetooth Off"
                        : (BluetoothService.isPerformingAction ? "Connecting..."
                        : (BluetoothService.scanning ? "Scanning..."
                        : (deviceList.displayDevices.length + (deviceList.displayDevices.length === 1 ? " Device" : " Devices"))))
                    color: (BluetoothService.scanning || BluetoothService.isPerformingAction) ? Theme.accentColor : Theme.subtext0
                    font.pixelSize: Theme.scaled(11)
                    font.weight: Font.Bold
                }
            }
        }

        // --- Connector / Active Connecting Banner ---
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(44)
            radius: Theme.bubbleRadiusMedium
            color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.15)
            border.color: Theme.accentColor
            border.width: 1
            visible: BluetoothService.isPerformingAction

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(14)
                anchors.rightMargin: Theme.scaled(14)
                spacing: Theme.scaled(10)

                Text {
                    text: "󰂱"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(18)
                    color: Theme.accentColor

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: BluetoothService.isPerformingAction
                        NumberAnimation { from: 0.3; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.0; to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(2)

                    Text {
                        text: "Connecting to Bluetooth Device..."
                        color: Theme.text
                        font.pixelSize: Theme.scaled(12)
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Pairing and configuring audio/input profiles..."
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
                        running: BluetoothService.isPerformingAction
                    }
                }
            }
        }

        // --- Skeleton Bluetooth Items while scanning ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(10)
            visible: BluetoothService.powered && BluetoothService.serviceActive && BluetoothService.scanning && deviceList.displayDevices.length === 0

            Repeater {
                model: 3
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: Theme.scaled(62)
                    radius: Theme.bubbleRadiusMedium
                    color: Theme.cardBackground
                    border.color: Theme.glassBorder
                    border.width: 1

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.35; to: 0.75; duration: 800 + index * 120; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.75; to: 0.35; duration: 800 + index * 120; easing.type: Easing.InOutSine }
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
                                width: Theme.scaled(120 + (index * 30) % 50)
                                height: Theme.scaled(12)
                                radius: Theme.scaled(4)
                                color: Qt.rgba(255, 255, 255, 0.12)
                            }

                            Rectangle {
                                width: Theme.scaled(70 + (index * 20) % 40)
                                height: Theme.scaled(8)
                                radius: Theme.scaled(3)
                                color: Qt.rgba(255, 255, 255, 0.06)
                            }
                        }

                        Rectangle {
                            width: Theme.scaled(48)
                            height: Theme.scaled(24)
                            radius: Theme.scaled(6)
                            color: Qt.rgba(255, 255, 255, 0.08)
                        }
                    }
                }
            }
        }

        // --- Device List ---
        ListView {
            FastWheel {}
            id: deviceList
            Layout.fillWidth: true
            
            property var displayDevices: BluetoothService.devices.filter(d => Boolean(d.hasName || d.connected || d.isKnown || d.paired || d.trusted))
            
            implicitHeight: contentHeight
            Layout.preferredHeight: contentHeight
            visible: BluetoothService.powered && BluetoothService.serviceActive && displayDevices.length > 0
            model: displayDevices
            spacing: Theme.scaled(10)
            interactive: false

            delegate: Rectangle {
                id: delegateRoot
                width: deviceList.width

                readonly property bool isConnected: Boolean(modelData.connected)
                readonly property bool isKnown: Boolean(modelData.isKnown || modelData.paired || modelData.trusted)
                readonly property bool isExpanded: root.selectedAddress === modelData.address

                height: isExpanded ? Theme.scaled(112) : Theme.scaled(62)
                Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

                color: isConnected
                       ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.18)
                       : ((headerMouse.containsMouse || isExpanded) ? Theme.cardBackgroundHover : Theme.cardBackground)
                radius: Theme.bubbleRadiusMedium
                border.color: isConnected ? Theme.powerGreen : (isExpanded ? Theme.accentColor : Theme.glassBorder)
                border.width: 1
                clip: true

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: headerMouse
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Theme.scaled(62)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (isConnected) {
                            BluetoothService.action("disconnect", modelData.address);
                        } else if (isKnown) {
                            BluetoothService.action("connect", modelData.address);
                        } else {
                            BluetoothService.action("pair", modelData.address);
                        }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.scaled(12)
                    spacing: Theme.scaled(10)

                    // Row 1: Header (Icon + Name / Status + Arrow stuck to the far right)
                    RowLayout {
                        width: parent.width
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.width
                        spacing: Theme.scaled(12)

                        // Device Icon
                        Rectangle {
                            width: Theme.scaled(38)
                            height: Theme.scaled(38)
                            radius: Theme.bubbleRadiusSmall
                            color: "transparent"
                            border.width: 0

                            Text {
                                anchors.centerIn: parent
                                text: getDeviceIcon(modelData.icon)
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.scaled(22)
                                color: isConnected ? Theme.powerGreen : Theme.text
                            }
                        }

                        // Device Info Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.scaled(1)

                            Text {
                                text: modelData.name || modelData.address
                                color: Theme.text
                                font.weight: Font.Bold
                                font.pixelSize: Theme.scaled(13)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                spacing: Theme.scaled(6)
                                Layout.fillWidth: true

                                Text { 
                                    text: isConnected ? "Connected" : (isKnown ? "Saved" : "Available")
                                    color: isConnected ? Theme.powerGreen : Theme.subtext0
                                    font.pixelSize: Theme.scaled(9)
                                    font.weight: Font.Bold
                                }

                                Text {
                                    visible: isConnected && modelData.battery !== undefined && modelData.battery !== -1
                                    text: "•  " + modelData.battery + "%"
                                    color: Theme.powerGreen
                                    font.pixelSize: Theme.scaled(9)
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        // Sticky-to-the-right Arrow Button
                        Rectangle {
                            width: Theme.scaled(34)
                            height: Theme.scaled(34)
                            radius: Theme.bubbleRadiusSmall
                            color: arrowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                            border.width: 0
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                            Text {
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
                                onClicked: (mouse) => {
                                    mouse.accepted = true;
                                    root.selectedAddress = isExpanded ? "" : modelData.address;
                                }
                            }
                        }
                    }

                    // Row 2: Action Buttons (Sticky to the right)
                    RowLayout {
                        width: parent.width
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.width
                        visible: isExpanded
                        spacing: Theme.scaled(8)

                        Item { Layout.fillWidth: true }

                        // Forget / Unpair button (Shown on known/saved devices)
                        Rectangle {
                            visible: isKnown
                            height: Theme.scaled(34)
                            implicitWidth: devForgetRow.implicitWidth + Theme.scaled(20)
                            radius: Theme.bubbleRadiusSmall
                            color: devForgetMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.3) : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                            border.color: Theme.red
                            border.width: 1

                            RowLayout {
                                id: devForgetRow
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
                                id: devForgetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    BluetoothService.action("remove", modelData.address);
                                    root.selectedAddress = "";
                                    mouse.accepted = true;
                                }
                            }
                        }

                        // Connect button (Shown on known but NOT connected devices)
                        Rectangle {
                            visible: isKnown && !isConnected
                            height: Theme.scaled(34)
                            implicitWidth: devConnRow.implicitWidth + Theme.scaled(24)
                            radius: Theme.bubbleRadiusSmall
                            color: devConnMouse.containsMouse ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.85) : Theme.accentColor

                            RowLayout {
                                id: devConnRow
                                anchors.centerIn: parent
                                spacing: Theme.scaled(6)

                                Text {
                                    text: "CONNECT"
                                    font.pixelSize: Theme.scaled(9)
                                    font.weight: Font.Black
                                    color: Colors.on_primary
                                }
                            }

                            MouseArea {
                                id: devConnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    BluetoothService.action("connect", modelData.address);
                                    mouse.accepted = true;
                                }
                            }
                        }

                        // Disconnect button (Shown on connected devices)
                        Rectangle {
                            visible: isConnected
                            height: Theme.scaled(34)
                            implicitWidth: devDisconnRow.implicitWidth + Theme.scaled(24)
                            radius: Theme.bubbleRadiusSmall
                            color: devDisconnMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25) : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                            border.color: Theme.red
                            border.width: 1

                            RowLayout {
                                id: devDisconnRow
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
                                id: devDisconnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    BluetoothService.action("disconnect", modelData.address);
                                    mouse.accepted = true;
                                }
                            }
                        }

                        // Pair button (Shown on unknown / newly discovered devices)
                        Rectangle {
                            visible: !isKnown && !isConnected
                            height: Theme.scaled(34)
                            implicitWidth: devPairRow.implicitWidth + Theme.scaled(24)
                            radius: Theme.bubbleRadiusSmall
                            color: devPairMouse.containsMouse ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.85) : Theme.accentColor

                            RowLayout {
                                id: devPairRow
                                anchors.centerIn: parent
                                spacing: Theme.scaled(6)

                                Text {
                                    text: "PAIR"
                                    font.pixelSize: Theme.scaled(9)
                                    font.weight: Font.Black
                                    color: Colors.on_primary
                                }
                            }

                            MouseArea {
                                id: devPairMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    BluetoothService.action("pair", modelData.address);
                                    mouse.accepted = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- Empty State Message ---
        Rectangle {
            id: emptyState
            Layout.fillWidth: true
            height: Theme.scaled(120)
            color: "transparent"
            visible: BluetoothService.powered && BluetoothService.serviceActive && !BluetoothService.scanning && deviceList.displayDevices.length === 0
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.scaled(8)
                Text { text: "󰂲"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(32); color: Theme.surface2; Layout.alignment: Qt.AlignHCenter }
                Text { text: "NO DEVICES FOUND"; color: Theme.surface2; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; font.letterSpacing: 1; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: "Turn on your peripheral and set it to pairing mode, then click Scan above."
                    color: Theme.subtext0
                    font.pixelSize: Theme.scaled(10)
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Bottom spacer to hug top and capture outer clicks
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            MouseArea {
                anchors.fill: parent
                onClicked: root.selectedAddress = ""
            }
        }
    }

    // --- Service Error View ---
    Rectangle {
        id: serviceErrorView
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.scaled(250)
        implicitHeight: Theme.scaled(250)
        color: Qt.rgba(0.1, 0.05, 0.05, 0.3)
        radius: Theme.scaled(20)
        visible: !BluetoothService.serviceActive
        border.color: Theme.powerRed
        border.width: 1
        ColumnLayout {
            anchors.centerIn: parent; spacing: Theme.scaled(20); width: parent.width * 0.8
            Text { text: "󰂲"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(48); color: Theme.powerRed; Layout.alignment: Qt.AlignHCenter }
            ColumnLayout {
                spacing: Theme.scaled(5); Layout.alignment: Qt.AlignHCenter
                Text { text: "SERVICE ERROR"; color: Theme.text; font.pixelSize: Theme.scaled(16); font.weight: Font.Black; Layout.alignment: Qt.AlignHCenter }
                Text { text: "The Bluetooth daemon is not running or has crashed."; color: Theme.subtext1; font.pixelSize: Theme.scaled(10); font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter; width: Theme.scaled(200); height: Theme.scaled(48); radius: Theme.scaled(14); color: (restartMouse.containsMouse ? Theme.powerRed : "transparent"); border.color: Theme.powerRed
                Text { anchors.centerIn: parent; text: "RESTART SERVICE"; color: (restartMouse.containsMouse ? Colors.background : Theme.powerRed); font.weight: Font.Black; font.pixelSize: Theme.scaled(11); font.letterSpacing: 1 }
                MouseArea { id: restartMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BluetoothService.restartService() }
            }
        }
    }
}