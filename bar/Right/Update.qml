// bar/Right/Update.qml
import ".."
import "../.."
import "../../services"
import "../Menu"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    property var zenith: ({exists: false, updates: 0, commits: []})
    property var zenithShell: ({exists: false, updates: 0, commits: []})
    property int totalUpdates: (zenith?.updates || 0) + (zenithShell?.updates || 0)
    
    visible: totalUpdates > 0
    implicitHeight: Theme.pillHeight
    implicitWidth: pill.width

    function runUpdate(args) {
        updateMenu.logText.text = "Starting update for: " + args + "
";
        console.log("Starting update with args:", args);
        
        updateRunner.command = ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/run_update.sh", ...args.split(" ")];
        updateRunner.running = true;
    }

    Pill {
        id: pill
        anchors.fill: parent
        z: 999
        icon: "󰚰"
        text: root.totalUpdates.toString()
        textColor: Theme.accentColor
        
        implicitWidth: pillRow.implicitWidth + Theme.pillPadding + Theme.extraPillPadding

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                updateMenu.visible = !updateMenu.visible;
                console.log("Update menu visible set to: " + updateMenu.visible);
            } else if (mouse.button === Qt.RightButton) {
                updateProc.running = false;
                updateProc.running = true;
            }
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: Theme.pillGap

            Text {
                text: pill.icon
                color: pill.textColor
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: pill.text
                color: pill.textColor
                font.pixelSize: Theme.fontSize
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    PopupWindow {
        id: updateMenu
        property alias logText: logText
        visible: false
        color: "transparent"
        
        // Full screen capture for click-outside dismissal
        implicitWidth: screen ? screen.width : Theme.screenWidth
        implicitHeight: screen ? screen.height : Theme.screenHeight
        
        grabFocus: false 

        // --- DISMISS ON OUTER CLICK ---
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: updateMenu.visible = false
        }

        Rectangle {
            id: menuSurface
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Theme.barMarginTop + 4
            
            color: Theme.glassBackground
            border.color: Theme.glassBorder
            border.width: 1
            radius: Theme.scaled(16)
            
            implicitWidth: Theme.scaled(450)
            implicitHeight: updateMenuContent.implicitHeight + Theme.scaled(32)

            ColumnLayout {
                id: updateMenuContent
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
                        text: (root.zenith.updates + root.zenithShell.updates) + " total"
                        color: Theme.subtext1
                        font.pixelSize: Theme.scaled(12)
                    }
                }

                // --- Repository Details ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(12)

                    RepoSection {
                        title: "Zenith (Configs)"
                        repoData: root.zenith
                        icon: "󱂵"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.glassBorder
                    }

                    RepoSection {
                        title: "Zenith Shell"
                        repoData: root.zenithShell
                        icon: "󰓞"
                    }
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
                        color: Theme.text
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
                        btnColor: Theme.accentGlow
                        onClicked: root.runUpdate("--quickshell --configs --new-pkgs")
                    }

                    ActionButton {
                        text: "Zenith"
                        icon: "󱂵"
                        btnColor: Theme.surface1
                        onClicked: root.runUpdate("--configs")
                    }

                    ActionButton {
                        text: "Shell"
                        icon: "󰓞"
                        btnColor: Theme.surface1
                        onClicked: root.runUpdate("--quickshell")
                    }

                    ActionButton {
                        text: "Packages"
                        icon: "󰏖"
                        Layout.columnSpan: 2
                        btnColor: Theme.surface1
                        onClicked: root.runUpdate("--new-pkgs")
                    }
                }
            }
        }
    }

    Process {
        id: updateRunner
        stdout: StdioCollector {
            onRead: (text) => {
                updateMenu.logText.text += text;
                console.log("Update output:", text);
            }
        }
        stderr: StdioCollector {
            onRead: (text) => {
                updateMenu.logText.text += "ERR: " + text;
                console.log("Update error:", text);
            }
        }
        onExited: (code) => {
            updateMenu.logText.text += "
Update finished with code: " + code;
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

        Repeater {
            model: repoData.commits || []
            delegate: Text {
                text: "• " + modelData.title
                color: Theme.subtext1
                font.pixelSize: Theme.scaled(11)
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.leftMargin: Theme.scaled(18)
            }
        }
        
        Text {
            visible: !repoData.commits || repoData.commits.length === 0
            text: "Up to date"
            color: Theme.overlay1
            font.pixelSize: Theme.scaled(11)
            Layout.leftMargin: Theme.scaled(18)
        }
    }

    component ActionButton: Rectangle {
        property string text
        property string icon
        property color btnColor: Theme.surface1
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: Theme.scaled(36)
        radius: Theme.scaled(8)
        color: mouse.containsMouse ? Qt.lighter(btnColor, 1.1) : btnColor
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
                    root.zenith = data.zenith || {exists: false, updates: 0, commits: []};
                    root.zenithShell = data.zenith_shell || {exists: false, updates: 0, commits: []};
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
