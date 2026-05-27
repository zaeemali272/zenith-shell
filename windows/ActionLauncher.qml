import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

FloatingWindow {
    id: win
    title: "Zenith Action Launcher"
    
    // Position at center of screen
    anchors.center: true
    
    implicitWidth: Theme.scaled(500)
    implicitHeight: Theme.scaled(450)
    
    color: "transparent"
    
    readonly property string cmdPath: Quickshell.env("HOME") + "/.cache/zenith_command"

    function sendCommand(cmd) {
        ipcWriter.command = ["sh", "-c", "echo '" + cmd + "' > " + win.cmdPath];
        ipcWriter.running = true;
        win.visible = false;
        // Small delay before quitting to ensure file is written
        quitTimer.start();
    }
    
    Process { id: ipcWriter }
    
    Timer {
        id: quitTimer
        interval: 100
        onTriggered: Qt.quit()
    }

    Rectangle {
        id: root
        anchors.fill: parent
        color: Theme.glassBackground
        radius: Theme.menuRadius
        border.color: Theme.glassBorder
        border.width: 1
        
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) Qt.quit();
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.menuPadding
            spacing: Theme.menuSpacing

            // --- HEADER ---
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "󱗼 ZENITH ACTIONS"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(18)
                    font.weight: Font.Black
                    color: Theme.accentColor
                }
                Item { Layout.fillWidth: true }
                Button {
                    flat: true
                    contentItem: Text { text: "󰅖"; font.family: Theme.iconFont; color: Theme.subtext1; font.pixelSize: 18 }
                    onClicked: Qt.quit()
                }
            }

            // --- GRID ---
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: Theme.scaled(15)
                rowSpacing: Theme.scaled(15)

                // Dashboard Section
                Label { 
                    text: "DASHBOARD"; Layout.columnSpan: 2
                    color: Theme.subtext1; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 1 
                }
                
                ActionBtn { text: "󱗼 Default"; onClicked: sendCommand("dashboard:Default") }
                ActionBtn { text: "󱎫 Pomodoro"; onClicked: sendCommand("dashboard:Pomodoro") }
                ActionBtn { text: "󰸉 Wallpapers"; onClicked: sendCommand("dashboard:Wallpaper") }
                ActionBtn { text: "󰂚 Notifications"; onClicked: sendCommand("dashboard:Default") }

                // Quick Settings Section
                Label { 
                    text: "QUICK SETTINGS"; Layout.columnSpan: 2; Layout.topMargin: 10
                    color: Theme.subtext1; font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 1 
                }
                
                ActionBtn { text: "󰤨 Network"; onClicked: sendCommand("quicksettings:network") }
                ActionBtn { text: "󰂯 Bluetooth"; onClicked: sendCommand("quicksettings:bluetooth") }
                ActionBtn { text: "󰕾 Audio"; onClicked: sendCommand("quicksettings:volume") }
                ActionBtn { text: "󰐥 Power"; onClicked: sendCommand("quicksettings:power") }
            }
            
            // --- FOOTER / UTILS ---
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10
                
                ActionBtn { 
                    text: "󰖲 Overview"; Layout.fillWidth: true; color: Theme.surface1
                    onClicked: {
                        overviewProc.running = true;
                        Qt.quit();
                    }
                }
                ActionBtn { 
                    text: "󰌌 Cheatsheet"; Layout.fillWidth: true; color: Theme.surface1
                    onClicked: {
                        cheatProc.running = true;
                        Qt.quit();
                    }
                }
            }
        }
    }

    component ActionBtn : Rectangle {
        property alias text: btnText.text
        signal clicked()
        
        Layout.fillWidth: true
        height: Theme.scaled(45)
        radius: Theme.scaled(12)
        color: mouse.containsMouse ? Theme.accentColor : Theme.surface1
        border.color: Theme.glassBorder
        
        Behavior on color { ColorAnimation { duration: 200 } }

        Text {
            id: btnText
            anchors.centerIn: parent
            font.pixelSize: Theme.scaled(12)
            font.weight: Font.Bold
            color: mouse.containsMouse ? Theme.base : Theme.text
        }
        
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    Process { 
        id: overviewProc
        command: ["quickshell", "-p", Quickshell.env("ZENITH_ROOT") + "/windows/Overview.qml"]
    }
    
    Process { 
        id: cheatProc
        command: ["quickshell", "-p", Quickshell.env("ZENITH_ROOT") + "/windows/Cheatsheet.qml"]
    }
}
