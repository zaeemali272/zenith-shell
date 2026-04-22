import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../" as Root

Item {
    id: root
    implicitHeight: Root.Theme.scaled ? Root.Theme.scaled(250) : 250
    
    property var activeWorkspaces: []
    property string currentWallpaper: ""

    Process {
        id: wallpaperReader
        command: ["cat", Quickshell.env("HOME") + "/.config/current_wallpaper.txt"]
        stdout: StdioCollector {
            onStreamFinished: {
                currentWallpaper = "file://" + text.trim();
            }
        }
        Component.onCompleted: running = true
    }

    function updateWorkspaces() {
        if (!Hyprland.workspaces) return;
        
        let wsValues = Hyprland.workspaces.values;
        if (!wsValues) return;

        activeWorkspaces = wsValues
            .filter(ws => ws && ws.id > 0)
            .sort((a, b) => a.id - b.id);
    }

    Component.onCompleted: updateWorkspaces()

    Connections {
        target: Hyprland.workspaces
        ignoreUnknownSignals: true
        function onValuesChanged() { updateWorkspaces(); }
    }
    
    Connections {
        target: Hyprland.toplevels
        ignoreUnknownSignals: true
        function onValuesChanged() { updateWorkspaces(); }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            spacing: 20

            Repeater {
                model: activeWorkspaces
                delegate: Rectangle {
                    id: wsDelegate
                    width: 250
                    height: 150
                    radius: 12
                    color: Root.Theme.mantle || "#181825"
                    border.color: modelData.active ? (Root.Theme.mauve || "#cba6f7") : (Root.Theme.surface0 || "#313244")
                    border.width: 2
                    
                    readonly property var workspace: modelData

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // Workspace Preview
                        Rectangle {
                            id: previewArea
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            color: Root.Theme.surface0 || "#313244"
                            radius: 8
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: root.currentWallpaper
                                fillMode: Image.PreserveAspectCrop
                                visible: source != ""
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: Root.Theme.surface0 || "#313244"
                                opacity: 0.3
                            }

                            // Tiled Windows / App Icons
                            Repeater {
                                model: {
                                    if (!workspace || !workspace.toplevels) return 0;
                                    return workspace.toplevels.values || workspace.toplevels;
                                }
                                delegate: Rectangle {
                                    readonly property var win: modelData
                                    readonly property var mon: workspace.monitor || { width: 1920, height: 1080, x: 0, y: 0 }
                                    
                                    // Calculate relative coordinates and scale to previewArea
                                    x: ((win.x - (mon.x || 0)) / mon.width) * previewArea.width
                                    y: ((win.y - (mon.y || 0)) / mon.height) * previewArea.height
                                    width: Math.max(20, (win.width / mon.width) * previewArea.width)
                                    height: Math.max(20, (win.height / mon.height) * previewArea.height)

                                    color: win.active ? (Root.Theme.surface2 || "#585b70") : (Root.Theme.surface1 || "#45475a")
                                    radius: 4
                                    border.color: win.active ? (Root.Theme.mauve || "#cba6f7") : "white"
                                    border.width: 1
                                    opacity: 0.8

                                    Image {
                                        anchors.centerIn: parent
                                        width: Math.min(parent.width * 0.8, 24)
                                        height: Math.min(parent.height * 0.8, 24)
                                        source: "image://icon/" + (win.initialClass || "").toLowerCase()
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        
                                        onStatusChanged: if (status === Image.Error) fallback.visible = true
                                        Text {
                                            id: fallback
                                            anchors.centerIn: parent
                                            visible: false
                                            text: "󰀻"
                                            color: "white"
                                            font.pixelSize: 12
                                        }
                                    }
                                }
                            }
                        }

                        // Bottom Info Row
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            
                            Text {
                                text: {
                                    let count = 0;
                                    if (workspace.toplevels) {
                                        count = workspace.toplevels.values ? workspace.toplevels.values.length : workspace.toplevels.length;
                                    }
                                    return count + (count === 1 ? " window" : " windows");
                                }
                                font.bold: true
                                font.pixelSize: 11
                                color: Root.Theme.text || "#cdd6f4"
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "WS " + workspace.id
                                font.bold: true
                                font.pixelSize: 11
                                color: workspace.active ? (Root.Theme.mauve || "#cba6f7") : (Root.Theme.subtext0 || "gray")
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("workspace " + workspace.id)
                    }
                }
            }
        }
    }
}
