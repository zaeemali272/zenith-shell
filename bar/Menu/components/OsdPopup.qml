import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: osdWindow

    property string osdType: ""
    property real osdValue: 0

    anchor.window: bar
    anchor.edges: Edges.Top | Edges.Right
    anchor.rect.y: bar.height + 11
    anchor.rect.x: bar.width - implicitWidth - 7

    implicitWidth: 350
    implicitHeight: 85
    // Window stays visible if timer is running OR if the mouse is hovering/pressing
    visible: osdTimer.running || content.opacity > 0 || mainMouseArea.containsMouse
    color: "transparent"

    Rectangle {
        id: content
        anchors.fill: parent
        color: "#11111b"
        radius: 13
        border.color: "#313244"
        border.width: 1
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
            anchors.margins: 18
            spacing: 8
            z: 2 // Keep content above mouse area

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 32; height: 32; radius: 8; color: "#181825"
                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 18
                        color: (osdValue <= 0) ? "#f38ba8" : (osdType === "volume" && osdValue > 1.0 ? "#fab387" : "#a6e3a1")
                        text: {
                            if (osdType === "brightness") {
                                if (osdValue <= 0.33) return "󰃞"; if (osdValue <= 0.66) return "󰃟"; return "󰃠"
                            } 
                            if (osdType === "volume") {
                                if (osdValue <= 0) return "󰝟"; if (osdValue <= 0.33) return "󰕿"; 
                                if (osdValue <= 0.66) return "󰖀"; if (osdValue <= 1.0) return "󰕾"; return "󰓃"
                            }
                            return "󰋽"
                        }
                    }
                }

                Text {
                    text: osdType.toUpperCase()
                    color: "#89b4fa"; font.weight: Font.Black; font.pixelSize: 12; font.letterSpacing: 2
                    Layout.fillWidth: true
                }

                Text {
                    text: Math.round(osdValue * 100) + "%"
                    color: "white"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 13
                }
            }

            Slider {
                id: osdSlider
                Layout.fillWidth: true
                from: 0; to: 1
                value: osdWindow.osdValue
                hoverEnabled: true

                // Reset all paddings for pixel-perfect alignment
                padding: 0
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0

                readonly property real handleWidth: 14
                
                // --- Re-enabled functionality ---
                onMoved: {
                    osdTimer.restart();
                    osdWindow.osdValue = value;
                    NotificationService.updateOSDValue(osdWindow.osdType, value);
                }

                background: Rectangle {
                    x: osdSlider.leftPadding + osdSlider.handleWidth / 2
                    y: osdSlider.topPadding + (osdSlider.availableHeight - height) / 2
                    implicitHeight: 10
                    width: osdSlider.availableWidth - osdSlider.handleWidth
                    radius: 3; color: "#181825"
                    Rectangle {
                        width: osdSlider.visualPosition * parent.width
                        height: parent.height
                        color: osdValue > 1.0 ? "#fab387" : "#a6e3a1"
                        radius: 30
                    }
                }

                handle: Rectangle {
                    x: osdSlider.leftPadding + osdSlider.visualPosition * (osdSlider.availableWidth - width)
                    y: osdSlider.topPadding + (osdSlider.availableHeight - height) / 2
                    implicitWidth: osdSlider.handleWidth; implicitHeight: 14; radius: 7
                    color: "white"; border.color: "#313244"

                    scale: osdSlider.pressed ? 1.2 : (osdSlider.hovered ? 1.1 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }
        }

        Behavior on opacity { NumberAnimation { duration: 200 } }
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