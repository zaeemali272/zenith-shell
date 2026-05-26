import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../.."
import "../../../"

Item {
    id: root
    
    // Timer Slots Configuration
    GridLayout {
        anchors.fill: parent
        columns: 4
        columnSpacing: 20
        rowSpacing: 20
        Repeater {
            model: [3, 5, 8, 10, 15, 30, 45, 60, 90, 120, 150, 180]
            delegate: Rectangle {
                id: timerSlot
                width: 195; height: 155; radius: 24
                color: timerSlot.running ? Theme.blue : Theme.glassBackground
                border.color: timerSlot.running ? Theme.blue : Theme.glassBorder
                border.width: 2
                
                property int initialDuration: modelData * 60
                property int remaining: initialDuration
                property bool running: false
                
                Timer {
                    id: timerObj
                    interval: 1000; running: timerSlot.running; repeat: true
                    onTriggered: {
                        if (timerSlot.remaining > 0) {
                            timerSlot.remaining--;
                        } else {
                            timerSlot.running = false;
                            timerSlot.remaining = timerSlot.initialDuration;
                            // Notification is handled by background service or logic here if needed
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 20
                    Text { 
                        text: Math.floor(timerSlot.remaining / 60) + ":" + (timerSlot.remaining % 60).toString().padStart(2, '0')
                        font.pixelSize: 34; font.weight: Font.Black; color: timerSlot.running ? Theme.base : Theme.text 
                    }
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 60; height: 50; radius: 14; color: timerSlot.running ? Theme.base : Theme.surface1
                            Text { anchors.centerIn: parent; text: timerSlot.running ? "⏸" : "▶"; color: timerSlot.running ? Theme.blue : Theme.text; font.pixelSize: 22 }
                            MouseArea { anchors.fill: parent; onClicked: timerSlot.running = !timerSlot.running }
                        }
                        Rectangle {
                            width: 60; height: 50; radius: 14; color: Theme.surface1
                            Text { anchors.centerIn: parent; text: "↺"; color: Theme.text; font.pixelSize: 22 }
                            MouseArea { anchors.fill: parent; onClicked: { timerSlot.running = false; timerSlot.remaining = timerSlot.initialDuration } }
                        }
                    }
                }
            }
        }
    }
}
