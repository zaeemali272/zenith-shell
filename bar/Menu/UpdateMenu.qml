import "../.."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

PopupWindow {
    id: root

    property var zenithData: ({exists: false, updates: 0, commits: []})
    property var shellData: ({exists: false, updates: 0, commits: []})

    visible: false
    color: "transparent"
    
    implicitWidth: menuSurface.implicitWidth
    implicitHeight: menuSurface.implicitHeight + Theme.scaled(20)

    grabFocus: true 

    HyprlandFocusGrab {
        id: grab
        active: root.visible
        windows: [root]
        onCleared: root.visible = false
    }

    function openAt(visualParent) {
        root.anchor.window = visualParent.QsWindow.window;
        root.anchor.rect = visualParent.mapToItem(null, 0, 0, visualParent.width, visualParent.height);
        root.anchor.edges = Edges.Bottom;
        root.anchor.gravity = Edges.Bottom;
        root.visible = true;
    }

    function runUpdate(args) {
        logText.text = "Starting update for: " + args + "\n";
        console.log("Starting update with args:", args);
        
        // Directly call the script, capturing output to the log viewer
        updateRunner.command = ["bash", "-c", Quickshell.env("HOME") + "/.config/quickshell/scripts/run_update.sh " + args];
        updateRunner.running = true;
    }

    Rectangle {
        id: menuSurface
        y: Theme.scaled(8)
        color: Theme.glassBackground
        border.color: Theme.glassBorder
        border.width: 1
        radius: Theme.scaled(16)
        
        implicitWidth: Theme.scaled(450)
        implicitHeight: content.implicitHeight + Theme.scaled(32)

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Theme.scaled(16)
            spacing: Theme.scaled(16)

            // --- Header ---
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Updates Available"
                    color: Theme.accentColor
                    font.pixelSize: Theme.scaled(16)
                    font.weight: Font.Bold
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: (zenithData.updates + shellData.updates) + " total"
                    color: Theme.subtext1
                    font.pixelSize: Theme.scaled(12)
                }
            }

            // --- Repository Details ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(12)
                RepoSection { title: "Zenith (Configs)"; repoData: zenithData; icon: "󱂵" }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.glassBorder }
                RepoSection { title: "Zenith Shell"; repoData: shellData; icon: "󰚰" }
            }

            // --- Log Viewer ---
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.scaled(200)
                clip: true
                background: Rectangle { color: Qt.rgba(0,0,0,0.3); radius: Theme.scaled(8) }
                
                Text {
                    id: logText
                    text: "Ready to update..."
                    color: Text.text
                    font.family: "monospace"
                    font.pixelSize: Theme.scaled(11)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }

            // --- Actions ---
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                rowSpacing: Theme.scaled(8)
                columnSpacing: Theme.scaled(8)

                ActionButton {
                    text: "Update All"
                    icon: "󰚰"
                    Layout.columnSpan: 2
                    color: Theme.blue
                    onClicked: root.runUpdate("--quickshell --configs --new-pkgs --skip-xdg")
                }

                ActionButton {
                    text: "Zenith"
                    icon: "󱂵"
                    color: Theme.surface1
                    onClicked: root.runUpdate("--configs --skip-xdg")
                }

                ActionButton {
                    text: "Shell"
                    icon: "󰓞"
                    color: Theme.surface1
                    onClicked: root.runUpdate("--quickshell")
                }

                ActionButton {
                    text: "Packages"
                    icon: "󰏖"
                    Layout.columnSpan: 2
                    color: Theme.surface1
                    onClicked: root.runUpdate("--new-pkgs")
                }
            }
        }
    }

    // Capture process output
    Process {
        id: updateRunner
        stdout: StdioCollector {
            onRead: (text) => {
                logText.text += text;
                console.log("Update output:", text);
            }
        }
        stderr: StdioCollector {
            onRead: (text) => {
                logText.text += "ERR: " + text;
                console.log("Update error:", text);
            }
        }
        onExited: (code) => {
            logText.text += "\nUpdate finished with code: " + code;
            console.log("Update finished with code:", code);
        }
    }

    component RepoSection: ColumnLayout {
        property string title
        property string icon
        property var repoData
        
        Layout.fillWidth: true
        spacing: Theme.scaled(4)

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: icon
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(14)
                color: Theme.accentColor
            }
            Text {
                text: title
                color: Theme.text
                font.weight: Font.Medium
                font.pixelSize: Theme.scaled(13)
            }
            Item { Layout.fillWidth: true }
            Text {
                text: (repoData.updates || 0) + " updates"
                color: (repoData.updates || 0) > 0 ? Theme.accentColor : Theme.subtext1
                font.pixelSize: Theme.scaled(11)
            }
        }
    }

    component ActionButton: Rectangle {
        property string text
        property string icon
        property color color: Theme.surface1
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: Theme.scaled(36)
        radius: Theme.scaled(8)
        color: mouse.containsMouse ? Qt.lighter(parent.color, 1.1) : parent.color
        border.color: Theme.glassBorder
        border.width: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: Theme.scaled(8)
            Text {
                text: icon
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(14)
                color: Theme.text
            }
            Text {
                text: parent.parent.text
                color: Theme.text
                font.pixelSize: Theme.scaled(12)
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    Process {
        id: updateProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/check_updates.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    zenithData = data.zenith || {exists: false, updates: 0, commits: []};
                    shellData = data.zenith_shell || {exists: false, updates: 0, commits: []};
                } catch (e) {
                    console.log("Update check failed:", e);
                }
            }
        }
    }

    Timer {
        interval: 3600000 // Check every hour
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateProc.running = false;
            updateProc.running = true;
        }
    }
}
