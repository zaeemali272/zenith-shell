// bar/Right/Resources.qml
import ".."
import "../.."
import "../../services"
import "../../Settings"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ================= TELEMETRY PROPERTIES =================
    // Network
    // netMode: 0 = Download (default), 1 = Upload, 2 = Dual (compact)
    property int netMode: 0
    readonly property int downSpeed: ResourceService.netDown
    readonly property int upSpeed: ResourceService.netUp

    readonly property bool wifiConnected: WifiService.currentState === "connected"
    readonly property string wifiSSID: WifiService.currentSsid
    readonly property bool airplaneMode: HardwareService.hasWifi && WifiService.isAirplane
    readonly property bool wiredOnly: !HardwareService.hasWifi && HardwareService.hasEthernet
    readonly property bool wiredUp: wiredOnly && WifiService.ipv4Address !== ""
    readonly property bool online: wifiConnected || wiredUp

    // Hover state: only show netspeed normally, show others on hover
    readonly property bool anyHovered: pillMouse.containsMouse || netMouse.containsMouse
                                       || (cpuItem.visible && cpuMouse.containsMouse)
                                       || (memItem.visible && memMouse.containsMouse)
                                       || (tempItem.visible && tempMouse.containsMouse)
    property bool isHovered: false

    onAnyHoveredChanged: {
        if (anyHovered) {
            collapseTimer.stop();
            isHovered = true;
        } else {
            collapseTimer.restart();
        }
    }

    Timer {
        id: collapseTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (!root.anyHovered)
                root.isHovered = false;
        }
    }

    readonly property bool showNetwork: WidgetSettings.enableNetwork && HardwareService.hasNetworking
    readonly property bool showResources: WidgetSettings.enableResources && isHovered

    // System Resources
    readonly property int cpu: ResourceService.cpu
    readonly property int mem: ResourceService.mem
    readonly property int temp: ResourceService.temp

    // User toggleable units (toggled via Right-Click)
    property bool ramShowGb: false
    property bool tempShowLoad: false

    function formatSpeed(kb) {
        if (kb <= 0) return "0K";
        if (kb < 1000) return kb + "K";
        if (kb < 1000000) return (kb / 1024).toFixed(1) + "M";
        return (kb / 1048576).toFixed(1) + "G";
    }

    function formatSpeedCompact(kb) {
        if (kb <= 0) return "0K";
        if (kb < 1000) return kb + "K";
        if (kb < 1000000) return (kb / 1024).toFixed(1) + "M";
        return (kb / 1048576).toFixed(1) + "G";
    }

    // High load warning color helpers
    function cpuColor(val) {
        if (val >= 85) return Theme.powerRed;
        if (val >= 65) return Theme.powerYellow;
        return Theme.barIconColor;
    }

    function memColor(val) {
        if (val >= 90) return Theme.powerRed;
        if (val >= 75) return Theme.powerYellow;
        return Theme.barIconColor;
    }

    function tempColor(val) {
        if (val >= 82) return Theme.powerRed;
        if (val >= 70) return Theme.powerYellow;
        return Theme.barIconColor;
    }

    // Launch btop system monitor
    Process {
        id: btopProc
        command: ["kitty", "-e", "btop"]
    }

    function launchBtop() {
        if (btopProc.running) return;
        btopProc.running = true;
    }

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: outerContainer.width

    // Outer Glass Container
    Rectangle {
        id: outerContainer
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: contentLayout.implicitWidth + Theme.scaled(20)
        implicitWidth: width
        radius: height / 2
        color: Theme.pillColor
        border.color: Theme.glassBorder
        border.width: 1
        antialiasing: true

        Behavior on width {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }

        // Pill background click handler
        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            z: -1
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    CenterState.focusTool = "Services";
                    CenterState.toggle("Pomodoro");
                } else if (mouse.button === Qt.MiddleButton) {
                    root.launchBtop();
                } else {
                    QuickSettingsService.toggle("main");
                }
            }
        }

        RowLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: Theme.scaled(4)

            // ================= NETWORK / NETSPEED =================
            Item {
                id: netItem
                visible: root.showNetwork
                implicitHeight: Theme.scaled(26)
                implicitWidth: netRow.implicitWidth + Theme.scaled(10)
                Layout.alignment: Qt.AlignVCenter

                scale: netMouse.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.scaled(6)
                    color: netMouse.containsMouse ? Theme.cardBackgroundHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                RowLayout {
                    id: netRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)

                    // Network Icon
                    Text {
                        text: root.airplaneMode ? "󰀞" : (!root.online ? "󰤮" : (root.wiredOnly ? "󰈀" : Theme.netIcon))
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize
                        color: (root.airplaneMode || !root.online) ? Theme.powerRed : Theme.barIconColor
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    // Network Reading
                    Text {
                        text: {
                            if (root.airplaneMode) return "OFF";
                            if (!root.online) return "DISC";
                            if (root.netMode === 0) return root.formatSpeed(root.downSpeed);
                            if (root.netMode === 1) return root.formatSpeed(root.upSpeed);
                            return root.formatSpeedCompact(root.downSpeed) + " " + root.formatSpeedCompact(root.upSpeed);
                        }
                        font.pixelSize: Theme.fontSize
                        font.family: "JetBrains Mono"
                        font.weight: Font.DemiBold
                        color: (root.airplaneMode || !root.online)
                               ? Theme.powerRed
                               : ((root.downSpeed < 5 && root.upSpeed < 5) ? Theme.subtext0 : Theme.fontColor)
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }

                MouseArea {
                    id: netMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            root.netMode = (root.netMode + 1) % 3;
                        } else if (mouse.button === Qt.MiddleButton) {
                            root.launchBtop();
                        } else {
                            QuickSettingsService.toggle("network");
                        }
                    }
                }
            }

            // Divider: Net | CPU
            Rectangle {
                visible: root.showNetwork && root.showResources
                width: 1
                height: Theme.scaled(12)
                color: Theme.glassBorder
                opacity: 0.5
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Theme.scaled(1)
                Layout.rightMargin: Theme.scaled(1)
            }

            // ================= CPU STATS (Shown on hover) =================
            Item {
                id: cpuItem
                visible: root.showResources
                implicitHeight: Theme.scaled(26)
                implicitWidth: cpuRow.implicitWidth + Theme.scaled(10)
                Layout.alignment: Qt.AlignVCenter

                scale: cpuMouse.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.scaled(6)
                    color: cpuMouse.containsMouse ? Theme.cardBackgroundHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                RowLayout {
                    id: cpuRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)

                    Text {
                        text: Theme.cpuIcon
                        color: root.cpuColor(root.cpu)
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    Text {
                        text: root.cpu + "%"
                        color: root.cpu >= 85 ? Theme.powerRed : (root.cpu >= 65 ? Theme.powerYellow : Theme.fontColor)
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }

                MouseArea {
                    id: cpuMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) {
                            root.launchBtop();
                        } else if (mouse.button === Qt.RightButton) {
                            CenterState.focusTool = "Services";
                            CenterState.toggle("Pomodoro");
                        } else {
                            QuickSettingsService.toggle("powerprofile");
                        }
                    }
                }
            }

            // Divider: CPU | RAM
            Rectangle {
                visible: root.showResources
                width: 1
                height: Theme.scaled(12)
                color: Theme.glassBorder
                opacity: 0.5
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Theme.scaled(1)
                Layout.rightMargin: Theme.scaled(1)
            }

            // ================= RAM STATS (Shown on hover) =================
            Item {
                id: memItem
                visible: root.showResources
                implicitHeight: Theme.scaled(26)
                implicitWidth: memRow.implicitWidth + Theme.scaled(10)
                Layout.alignment: Qt.AlignVCenter

                scale: memMouse.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.scaled(6)
                    color: memMouse.containsMouse ? Theme.cardBackgroundHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                RowLayout {
                    id: memRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)

                    Text {
                        text: Theme.memIcon
                        color: root.memColor(root.mem)
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    Text {
                        text: root.ramShowGb ? (ResourceService.memUsedGb.toFixed(1) + "G") : (root.mem + "%")
                        color: root.mem >= 90 ? Theme.powerRed : (root.mem >= 75 ? Theme.powerYellow : Theme.fontColor)
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }

                MouseArea {
                    id: memMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) {
                            root.launchBtop();
                        } else if (mouse.button === Qt.RightButton) {
                            root.ramShowGb = !root.ramShowGb;
                        } else {
                            QuickSettingsService.toggle("powerprofile");
                        }
                    }
                }
            }

            // Divider: RAM | Temp
            Rectangle {
                visible: root.showResources
                width: 1
                height: Theme.scaled(12)
                color: Theme.glassBorder
                opacity: 0.5
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Theme.scaled(1)
                Layout.rightMargin: Theme.scaled(1)
            }

            // ================= TEMP STATS (Shown on hover) =================
            Item {
                id: tempItem
                visible: root.showResources
                implicitHeight: Theme.scaled(26)
                implicitWidth: tempRow.implicitWidth + Theme.scaled(10)
                Layout.alignment: Qt.AlignVCenter

                scale: tempMouse.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.scaled(6)
                    color: tempMouse.containsMouse ? Theme.cardBackgroundHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                RowLayout {
                    id: tempRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)

                    Text {
                        text: Theme.tempIcon
                        color: root.tempColor(root.temp)
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    Text {
                        text: root.tempShowLoad ? (ResourceService.load.toFixed(1) + "L") : (root.temp + "°C")
                        color: root.temp >= 82 ? Theme.powerRed : (root.temp >= 70 ? Theme.powerYellow : Theme.fontColor)
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }

                MouseArea {
                    id: tempMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) {
                            root.launchBtop();
                        } else if (mouse.button === Qt.RightButton) {
                            root.tempShowLoad = !root.tempShowLoad;
                        } else {
                            QuickSettingsService.toggle("powerprofile");
                        }
                    }
                }
            }
        }
    }
}
