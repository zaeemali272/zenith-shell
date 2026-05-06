import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Window {
    id: root
    visible: true 
    width: 400
    height: 300
    color: "#11111b"
    
    property var colors: []
    
    Process {
        id: colorExtractor
        command: ["sh", "-c", "matugen image $(cat " + Quickshell.env("HOME") + "/.config/current_wallpaper.txt) --json | grep -oE '#[a-fA-F0-9]{6}' | head -n 4"]
        onExited: {
            let outputRaw = stdout || "";
            let output = outputRaw.trim().split('\n');
            if (output.length >= 4) {
                root.colors = output;
            } else {
                root.colors = ["#45371c", "#585e61", "#826362", "#1a241f"];
            }
        }
    }
    
    Component.onCompleted: colorExtractor.running = true
    
    Rectangle {
        anchors.fill: parent
        color: "#11111b"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            Text {
                text: "Select Source Color"
                color: "white"
                font.bold: true
                font.pixelSize: 18
                Layout.alignment: Qt.AlignHCenter
            }
            
            GridLayout {
                columns: 2
                Layout.alignment: Qt.AlignHCenter
                rowSpacing: 10
                columnSpacing: 10
                
                Repeater {
                    model: root.colors
                    delegate: Rectangle {
                        width: 120; height: 50; radius: 8
                        color: modelData
                        border.color: "white"
                        border.width: 1
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: "white"
                            font.pixelSize: 12
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("Clicked color: " + modelData);
                                runThemeScript.targetColor = modelData;
                                runThemeScript.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
    
    Process {
        id: runThemeScript
        property string targetColor: ""
        // Use absolute path and redirect explicitly
        command: ["/bin/bash", Quickshell.env("ZENITH_ROOT") + "/scripts/zenith-theme.sh", "$(cat " + Quickshell.env("HOME") + "/.config/current_wallpaper.txt)", targetColor]
        onRunningChanged: {
            if (!running) root.visible = false;
        }
    }
}
