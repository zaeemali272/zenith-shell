import "../../../services"
import "../../../Settings"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../.."

PanelWindow {
    id: osdWindow

    readonly property bool useFullscreenLayout: NotificationSettings.fullscreenOSD
    readonly property bool isFullscreen: HyprlandService.isFullscreen

    property string osdType: ""
    property real osdValue: 0
    readonly property bool isVolume: osdType === "volume"

    readonly property real visualPosition: {
        if (isVolume) {
            if (osdValue <= 1.0) return (osdValue / 1.0) * 0.75;
            return 0.75 + Math.min(0.25, ((osdValue - 1.0) / 0.5) * 0.25);
        }
        return Math.max(0, Math.min(1.0, osdValue));
    }

    function setVisualPosition(pos) {
        let clamped = Math.max(0, Math.min(1.0, pos));
        let calculatedVal = clamped;
        if (isVolume) {
            if (clamped <= 0.75) calculatedVal = (clamped / 0.75) * 1.0;
            else calculatedVal = 1.0 + ((clamped - 0.75) / 0.25) * 0.5;
        }
        osdWindow.osdValue = calculatedVal;
        NotificationService.updateOSDValue(osdWindow.osdType, calculatedVal);
        osdTimer.restart();
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "osd"

    // Position (top-right floating capsule)
    anchors {
        top: true
        right: true
    }

    WlrLayershell.margins {
        top: Theme.scaled(12)
        right: Theme.scaled(14)
    }

    implicitWidth: Theme.scaled(280)
    implicitHeight: Theme.scaled(44)
    
    // Window stays visible if timer is running OR if the mouse is hovering/pressing
    visible: !LockService.locked && (osdTimer.running || content.opacity > 0 || mainMouseArea.containsMouse) && (!osdWindow.isFullscreen || osdWindow.useFullscreenLayout)
    color: "transparent"

    mask: Region {
        item: content
    }

    Rectangle {
        id: content
        anchors.fill: parent
        color: Theme.glassBackground
        radius: height / 2
        border.color: Theme.glassBorder
        border.width: 1
        antialiasing: true

        // Smooth drop & fade physics
        opacity: (osdTimer.running || mainMouseArea.containsMouse) ? 1.0 : 0.0
        transform: Translate {
            y: (osdTimer.running || mainMouseArea.containsMouse) ? 0 : -Theme.scaled(8)
            Behavior on y { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

        // Hover detection to keep OSD alive while interacting
        MouseArea {
            id: mainMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: osdTimer.stop()
            onExited: osdTimer.restart()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.scaled(14)
            anchors.rightMargin: Theme.scaled(14)
            spacing: Theme.scaled(10)
            z: 2

            // OSD Icon
            Text {
                id: iconText
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(18)
                color: (osdValue <= 0) ? Theme.powerRed : Theme.accentColor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: Theme.scaled(22)
                antialiasing: true

                text: {
                    if (osdType === "brightness") {
                        if (osdValue <= 0.33) return "󰃞"; 
                        if (osdValue <= 0.66) return "󰃟"; 
                        return "󰃠";
                    } 
                    if (osdType === "volume") {
                        if (osdValue <= 0) return "󰝟"; 
                        if (osdValue <= 0.33) return "󰕿"; 
                        if (osdValue <= 0.66) return "󰖀"; 
                        if (osdValue <= 1.0) return "󰕾"; 
                        return "󰓃";
                    }
                    if (osdType === "mic") {
                        return osdValue <= 0 ? "󰍭" : "󰍬";
                    }
                    return "󰋽";
                }
            }

            // Interactive Progress Bar
            Item {
                id: trackContainer
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: track
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: Theme.scaled(6)
                    radius: height / 2
                    color: Qt.rgba(255, 255, 255, 0.08)
                    border.color: Theme.glassBorder
                    border.width: 1
                    antialiasing: true
                    clip: true

                    // 1. Continuous solid fill
                    Rectangle {
                        id: baseFill
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(0, Math.min(track.width, osdWindow.visualPosition * track.width))
                        radius: parent.radius
                        color: (osdValue <= 0) ? Theme.powerRed : Theme.accentColor
                        antialiasing: true

                        Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
                    }

                    // 2. Brightened boost overlay beyond 100%
                    Rectangle {
                        id: boostOverlay
                        visible: osdWindow.isVolume && (osdWindow.visualPosition > 0.75)
                        x: Math.round(0.75 * track.width)
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(0, (osdWindow.visualPosition * track.width) - x)
                        color: Qt.rgba(255, 255, 255, 0.28)
                        z: 2
                    }

                    // 3. 100% threshold marker line
                    Rectangle {
                        id: line100
                        visible: osdWindow.isVolume
                        x: Math.round(0.75 * track.width - width / 2)
                        width: Theme.scaled(2)
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        color: Qt.rgba(255, 255, 255, 0.55)
                        z: 3
                    }
                }

                // Interactive click/drag/wheel area for track
                MouseArea {
                    id: trackMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function updatePos(mouseX) {
                        let clampedX = Math.max(0, Math.min(track.width, mouseX));
                        osdWindow.setVisualPosition(clampedX / track.width);
                    }

                    onPressed: (mouse) => updatePos(mouse.x)
                    onPositionChanged: (mouse) => {
                        if (pressed) updatePos(mouse.x);
                    }
                    onWheel: (wheel) => {
                        let step = wheel.angleDelta.y > 0 ? 0.02 : -0.02;
                        osdWindow.setVisualPosition(osdWindow.visualPosition + step);
                    }
                }
            }

            // Value Label
            Text {
                text: (osdType === "mic" && osdValue <= 0) ? "MUTED" : (Math.round(osdValue * 100) + "%")
                color: (osdValue <= 0) ? Theme.powerRed : Theme.text
                font.family: "JetBrains Mono"
                font.weight: Font.Bold
                font.pixelSize: Theme.scaled(12)
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Theme.scaled(38)
            }
        }
    }

    Timer {
        id: osdTimer
        interval: 2200
    }

    Connections {
        target: NotificationService
        function onOsdReceived(type, value) {
            osdWindow.osdType = type
            osdWindow.osdValue = value
            osdTimer.restart()
        }
    }
}
