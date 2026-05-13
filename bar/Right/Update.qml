// bar/Right/Update.qml
import ".."
import "../.."
import "../../services"
import "../Menu"
import QtQuick
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

    Pill {
        id: pill
        anchors.fill: parent
        icon: "󰚰"
        text: root.totalUpdates.toString()
        textColor: Theme.blue
        
        implicitWidth: pillRow.implicitWidth + Theme.pillPadding + Theme.extraPillPadding

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                updateMenu.anchor.window = pill.QsWindow.window;
                updateMenu.anchor.rect = pill.mapToItem(null, 0, 0, pill.width, pill.height);
                updateMenu.visible = !updateMenu.visible;
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
        visible: false
        color: "transparent"
        
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        
        implicitWidth: menuSurface.implicitWidth
        implicitHeight: menuSurface.implicitHeight + Theme.scaled(20)

        grabFocus: true 

        HyprlandFocusGrab {
            id: grab
            active: updateMenu.visible
            windows: [updateMenu]
            onCleared: updateMenu.visible = false
        }

        Rectangle {
            id: menuSurface
            y: Theme.scaled(8)
            color: Theme.glassBackground
            border.color: Theme.glassBorder
            border.width: 1
            radius: Theme.scaled(16)
            
            implicitWidth: Theme.scaled(350)
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
                        color: Theme.blue
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
                        icon: "󱓞"
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
                        btnColor: Theme.blue
                        onClicked: runUpdate("--quickshell --configs --new-pkgs")
                    }

                    ActionButton {
                        text: "Zenith"
                        icon: "󱂵"
                        btnColor: Theme.surface1
                        onClicked: runUpdate("--configs")
                    }

                    ActionButton {
                        text: "Shell"
                        icon: "󱓞"
                        btnColor: Theme.surface1
                        onClicked: runUpdate("--quickshell")
                    }

                    ActionButton {
                        text: "Packages"
                        icon: "󰏖"
                        Layout.columnSpan: 2
                        btnColor: Theme.surface1
                        onClicked: runUpdate("--new-pkgs")
                    }
                }
            }
        }

        function runUpdate(args) {
            updateRunner.command = ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/run_update.sh", ...args.split(" ")];
            updateRunner.running = true;
            updateMenu.visible = false;
        }

        Process {
            id: updateRunner
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
                    color: Theme.blue
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
                    color: (repoData.updates || 0) > 0 ? Theme.yellow : Theme.subtext1
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
