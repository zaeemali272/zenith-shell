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

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Position (top-right)
    anchors {
        top: true
        right: true
    }

    WlrLayershell.margins {
        top: Theme.scaled(10)
        right: Theme.scaled(10)
    }

    implicitWidth: Theme.scaled(400)
    implicitHeight: osdWindow.isFullscreen ? Theme.scaled(65) : Theme.scaled(85)
    
    // Window stays visible if timer is running OR if the mouse is hovering/pressing
    visible: !LockService.locked && (osdTimer.running || content.opacity > 0 || mainMouseArea.containsMouse) && (!osdWindow.isFullscreen || osdWindow.useFullscreenLayout)
    color: "transparent"

    Rectangle {
        id: content
        anchors.fill: parent
        color: Theme.glassBackground
        radius: Theme.scaled(20)
        border.color: Theme.glassBorder
        border.width: 1
        antialiasing: true
        // Fade logic: Stay visible on hover
        opacity: (osdTimer.running || mainMouseArea.containsMouse) ? 1 : 0

        // This mouse area detects hover to keep the OSD alive
        MouseArea {
            id: mainMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: osdTimer.stop()
            onExited: osdTimer.restart()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: osdWindow.isFullscreen ? Theme.scaled(10) : Theme.scaled(16)
            anchors.rightMargin: osdWindow.isFullscreen ? Theme.scaled(10) : Theme.scaled(16)
            anchors.topMargin: osdWindow.isFullscreen ? Theme.scaled(8) : Theme.scaled(14)
            anchors.bottomMargin: osdWindow.isFullscreen ? Theme.scaled(8) : Theme.scaled(14)
            spacing: osdWindow.isFullscreen ? Theme.scaled(4) : Theme.scaled(8)
            z: 2 // Keep content above mouse area

            RowLayout {
                Layout.fillWidth: true
                spacing: osdWindow.isFullscreen ? Theme.scaled(8) : Theme.scaled(12)

                Rectangle {
                    width: osdWindow.isFullscreen ? Theme.scaled(20) : Theme.scaled(36); 
                    height: osdWindow.isFullscreen ? Theme.scaled(20) : Theme.scaled(36); 
                    radius: osdWindow.isFullscreen ? Theme.scaled(4) : Theme.bubbleRadiusSmall; 
                    color: "transparent"
                    border.width: 0
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.iconFont
                        font.pixelSize: osdWindow.isFullscreen ? Theme.scaled(18) : Theme.scaled(24)
                        color: (osdValue <= 0) ? Theme.powerRed : Theme.accentColor
                        text: {
                            if (osdType === "brightness") {
                                if (osdValue <= 0.33) return "󰃞"; if (osdValue <= 0.66) return "󰃟"; return "󰃠"
                            } 
                            if (osdType === "volume") {
                                if (osdValue <= 0) return "󰝟"; if (osdValue <= 0.33) return "󰕿"; 
                                if (osdValue <= 0.66) return "󰖀"; if (osdValue <= 1.0) return "󰕾"; return "󰓃"
                            }
                            if (osdType === "mic") {
                                return osdValue <= 0 ? "󰍭" : "󰍬";
                            }
                            return "󰋽"
                        }
                    }
                }

                Text {
                    text: osdType.toUpperCase()
                    color: Theme.accentColor
                    font.weight: Font.Black
                    font.pixelSize: Theme.scaled(12)
                    font.letterSpacing: 2
                    Layout.fillWidth: true
                }

                Text {
                    text: (osdType === "mic" && osdValue <= 0) ? "MUTED" : (Math.round(osdValue * 100) + "%")
                    color: (osdValue <= 0) ? Theme.powerRed : Theme.text
                    font.family: "JetBrains Mono"
                    font.weight: Font.Bold
                    font.pixelSize: osdWindow.isFullscreen ? Theme.scaled(11) : Theme.scaled(13)
                }
            }

            Slider {
                id: osdSlider
                Layout.fillWidth: true
                from: 0
                to: 1.0
                value: {
                    if (isVolume) {
                        if (osdWindow.osdValue <= 1.0) return (osdWindow.osdValue / 1.0) * 0.75;
                        return 0.75 + Math.min(0.25, ((osdWindow.osdValue - 1.0) / 0.5) * 0.25);
                    } else {
                        return Math.max(0, Math.min(1.0, osdWindow.osdValue));
                    }
                }
                hoverEnabled: true

                // Reset all paddings for pixel-perfect alignment
                padding: 0
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0

                readonly property real handleWidth: osdWindow.isFullscreen ? Theme.scaled(12) : Theme.scaled(14)
                readonly property bool isVolume: osdWindow.osdType === "volume"
                readonly property real line100X: isVolume ? (0.75 * (track.width - handleWidth) + handleWidth / 2) : track.width
                readonly property real currentFillX: Math.max(0, Math.min(track.width, visualPosition * (track.width - handleWidth) + handleWidth / 2))

                // --- Re-enabled functionality ---
                onMoved: {
                    osdTimer.restart();
                    let calculatedVol = value;
                    if (isVolume) {
                        if (value <= 0.75) calculatedVol = (value / 0.75) * 1.0;
                        else calculatedVol = 1.0 + ((value - 0.75) / 0.25) * 0.5;
                    }
                    osdWindow.osdValue = calculatedVol;
                    NotificationService.updateOSDValue(osdWindow.osdType, calculatedVol);
                }

                background: Rectangle {
                    id: track
                    x: 0
                    y: (osdSlider.availableHeight - height) / 2
                    implicitHeight: osdWindow.isFullscreen ? Theme.scaled(8) : Theme.scaled(10)
                    width: osdSlider.availableWidth
                    radius: height / 2
                    color: Qt.rgba(255, 255, 255, 0.08)
                    border.color: Theme.glassBorder
                    border.width: 1
                    antialiasing: true
                    clip: true

                    // 1. Single continuous solid slider fill (with rounded edge at start and end)
                    Rectangle {
                        id: baseFill
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: osdSlider.currentFillX
                        radius: parent.radius
                        color: (osdValue <= 0) ? Theme.powerRed : Theme.accentColor
                        antialiasing: true
                    }

                    // 2. Subtle brightened overlay ONLY on the part after the 100% line
                    Rectangle {
                        id: boostOverlay
                        visible: osdSlider.isVolume && (osdSlider.currentFillX > osdSlider.line100X)
                        x: osdSlider.line100X
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(0, osdSlider.currentFillX - osdSlider.line100X)
                        color: Qt.rgba(255, 255, 255, 0.22)
                    }

                    // 3. The 100% threshold marker line (placed at 75% of slider)
                    Rectangle {
                        id: line100
                        visible: osdSlider.isVolume
                        x: Math.round(osdSlider.line100X - width / 2)
                        width: Theme.scaled(2)
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        color: Qt.rgba(255, 255, 255, 0.55)
                        z: 4
                    }
                }

                handle: Rectangle {
                    x: osdSlider.visualPosition * (osdSlider.availableWidth - width)
                    y: (osdSlider.availableHeight - height) / 2
                    implicitWidth: osdSlider.handleWidth
                    implicitHeight: osdWindow.isFullscreen ? Theme.scaled(12) : Theme.scaled(14)
                    radius: width / 2
                    color: Theme.text
                    border.color: (osdValue <= 0) ? Theme.powerRed : Theme.accentColor
                    border.width: 1
                    antialiasing: true

                    scale: osdSlider.pressed ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                }
            }
        }

        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    }

    Timer {
        id: osdTimer
        interval: 2500 // Increased slightly for comfort
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
