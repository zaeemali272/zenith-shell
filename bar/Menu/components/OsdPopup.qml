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
    anchor.rect.x: 4
    anchor.rect.y: bar.height + 10
    implicitWidth: 350
    implicitHeight: 80
    // Use visible for the window, but opacity for the content
    visible: osdTimer.running || content.opacity > 0
    color: "transparent"

    Rectangle {
        id: content

        anchors.fill: parent
        color: "#121212"
        radius: 12
        border.color: "#313244"
        border.width: 1
        // Apply the fade here instead of the PopupWindow
        opacity: osdTimer.running ? 1 : 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 5

          RowLayout {
                        Layout.fillWidth: true
                        spacing: 5 // Gives a nice gap between the icon and the label

                        // Fixed-width container for the icon prevents "pushing" the text
                        Item {
                            implicitWidth: 24
                            implicitHeight: 24

                            Text {
                                anchors.centerIn: parent
                                font.pixelSize: 22 // Boosted slightly for better visibility
                                
                                // COLOR LOGIC: Red for Muted, Peach/Red for Over-vol, Green for Normal
                                color: {
                                    if (osdValue <= 0) return "#f38ba8";    // Muted Red
                                    if (osdType === "volume" && osdValue > 1.0) return "#fab387"; // Over-vol Peach
                                    return "#a6e3a1";                       // Normal Green
                                }
                            
                                text: {
                                    if (osdType === "brightness") {
                                        if (osdValue <= 0.33) return "󰃞"; 
                                        if (osdValue <= 0.66) return "󰃟"; 
                                        return "󰃠";                       
                                    } 
                            
                                    if (osdType === "volume") {
                                        if (osdValue <= 0) return "󰝟";      // Muted
                                        if (osdValue <= 0.33) return "󰕿";   // Low
                                        if (osdValue <= 0.66) return "󰖀";   // Mid
                                        if (osdValue <= 1.0) return "󰕾";    // High (100%)
                                        return "󰓃";                        // Extra Vol / Over-amplified (Nerd Font: nf-md-volume_high_alert)
                                    }
                                    return "󰋽";
                                }
                            
                                // Add a subtle glow when over-volting
                                layer.enabled: osdType === "volume" && osdValue > 1.0
                            }
                        }

                        Text {
                            text: osdType.toUpperCase()
                            color: "white"
                            font.bold: true
                            font.letterSpacing: 1 // Makes it look a bit more "pro"
                            Layout.fillWidth: true
                        }

                        Text {
                            text: Math.round(osdValue * 100) + "%"
                            color: "#cad3f5"
                            font.family: "JetBrains Mono" // Use a mono font so the % doesn't jitter
                        }
                    }

            Slider {
                id: osdSlider

                Layout.fillWidth: true
                from: 0
                to: 1
                value: osdWindow.osdValue
                onMoved: {
                    osdTimer.restart();
                    osdWindow.osdValue = value;
                    NotificationService.updateOSDValue(osdWindow.osdType, value);
                }

                background: Rectangle {
                    // Lowered from 6 to 3 for a thinner bar
                    implicitHeight: 3
                    width: osdSlider.availableWidth
                    radius: 3
                    color: "#313244"

                    Rectangle {
                        width: osdSlider.visualPosition * parent.width
                        height: parent.height
                        color: "#a6e3a1"
                        radius: 3
                    }
                }

                handle: Rectangle {
                    // This math ensures the center of the handle is always 
                    // at the visual end of the progress bar.
                    x: osdSlider.leftPadding + (osdSlider.visualPosition * osdSlider.availableWidth) - (width / 2)
                    y: (osdSlider.availableHeight / 2) - (height / 2)
                    
                    implicitWidth: 10
                    implicitHeight: 10
                    radius: 5
                    color: osdSlider.pressed ? "#a6e3a1" : "white"
                    
                    scale: osdSlider.pressed ? 1.3 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }

        }

    }

    Timer {
        id: osdTimer

        interval: 2500
    }

    Connections {
        function onOsdReceived(type, value) {
            osdWindow.osdType = type;
            osdWindow.osdValue = value;
            osdTimer.restart();
        }

        target: NotificationService
    }

}
