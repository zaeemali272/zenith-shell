import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../.."
import "../../../"
import "../../../services"

Item {
    id: root
    
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.scaled(30)
        width: parent.width * 0.9

        // --- MAIN TIMER DISPLAY ---
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.scaled(10)

            Text {
                text: {
                    let m = Math.floor(ProductivityService.remaining / 60);
                    let s = ProductivityService.remaining % 60;
                    return m + ":" + s.toString().padStart(2, '0');
                }
                font.pixelSize: Theme.scaled(84)
                font.weight: Font.Black
                color: ProductivityService.running ? Theme.blue : Theme.text
                Layout.alignment: Qt.AlignHCenter
                
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            // --- ADJUSTMENT CONTROLS ---
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.scaled(20)
                visible: !ProductivityService.running

                ControlBtn { 
                    text: "-1m"; icon: "󰐊"; 
                    onClicked: ProductivityService.adjustDuration(-60) 
                }
                ControlBtn { 
                    text: "+1m"; icon: "󰐊"; 
                    onClicked: ProductivityService.adjustDuration(60) 
                }
                ControlBtn { 
                    text: "+5m"; icon: "󰐊"; 
                    onClicked: ProductivityService.adjustDuration(300) 
                }
            }
        }

        // --- QUICK PRESETS ---
        Flow {
            Layout.fillWidth: true
            spacing: Theme.scaled(10)
            Layout.alignment: Qt.AlignHCenter
            
            Repeater {
                model: [
                    { label: "5m",  secs: 300 },
                    { label: "10m", secs: 600 },
                    { label: "15m", secs: 900 },
                    { label: "25m", secs: 1500 },
                    { label: "30m", secs: 1800 },
                    { label: "1h",  secs: 3600 }
                ]

                delegate: Rectangle {
                    width: (parent.width - Theme.scaled(50)) / (Theme.isSmallScreen ? 3 : 6)
                    height: Theme.scaled(45)
                    radius: Theme.scaled(12)
                    color: ProductivityService.duration === modelData.secs ? Theme.blue : Theme.surface1
                    
                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: Theme.scaled(12)
                        font.weight: Font.Bold
                        color: ProductivityService.duration === modelData.secs ? Theme.base : Theme.text
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: ProductivityService.setDuration(modelData.secs)
                    }
                }
            }
        }

        // --- PLAYBACK CONTROLS ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.scaled(25)

            // Start / Pause
            Rectangle {
                width: Theme.scaled(70); height: Theme.scaled(70); radius: width/2
                color: ProductivityService.running ? Theme.powerRed : Theme.blue
                
                Text {
                    anchors.centerIn: parent
                    text: ProductivityService.running ? "󰏤" : "󰐊"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(32)
                    color: Theme.base
                    // Manual offset for better visual centering of the play icon
                    anchors.horizontalCenterOffset: ProductivityService.running ? 0 : 3
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: ProductivityService.toggleTimer()
                }
            }

            // Reset
            Rectangle {
                width: Theme.scaled(55); height: Theme.scaled(55); radius: width/2
                color: Theme.surface1
                
                Text {
                    anchors.centerIn: parent
                    text: "󰜉"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(24)
                    color: Theme.text
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: ProductivityService.resetTimer()
                }
            }
        }
    }

    // --- Helper Component ---
    component ControlBtn: Rectangle {
        property string text
        property string icon
        signal clicked()

        width: Theme.scaled(60); height: Theme.scaled(35); radius: Theme.scaled(10)
        color: Theme.surface1
        
        Text {
            anchors.centerIn: parent
            text: parent.text
            font.pixelSize: Theme.scaled(11)
            font.weight: Font.Black
            color: Theme.subtext1
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }
}
