import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../" as Root
import "../../services" as Services

Item {
    id: root
    implicitHeight: (Root.Theme && Root.Theme.scaled) ? Root.Theme.scaled(200) : 200
    
    property var activeWorkspaces: []
    property string currentWallpaper: ""

    // Read wallpaper path reliably using cat via Process
    Process {
        id: wallpaperReader
        command: ["cat", Quickshell.env("HOME") + "/.config/current_wallpaper.txt"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.currentWallpaper = "file://" + text.trim();
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

    RowLayout {
        anchors.fill: parent
        spacing: 15

        Item { Layout.fillWidth: true }

        Repeater {
            model: activeWorkspaces
            delegate: Rectangle {
                id: wsDelegate
                Layout.preferredWidth: 280
                Layout.preferredHeight: 160
                radius: 16
                color: (Root.Theme && Root.Theme.mantle) ? Root.Theme.mantle : "#181825"
                border.color: modelData.active ? ((Root.Theme && Root.Theme.mauve) ? Root.Theme.mauve : "#cba6f7") : "transparent"
                border.width: 2
                
                readonly property var workspace: modelData

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    // Workspace Preview with Wallpaper
                    Rectangle {
                        id: previewArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: (Root.Theme && Root.Theme.crust) ? Root.Theme.crust : "#11111b"
                        radius: 12
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: root.currentWallpaper
                            fillMode: Image.PreserveAspectCrop
                            visible: source != ""
                            opacity: 0.4
                        }

                        // Windows / App Icons
                        Repeater {
                            model: {
                                if (!workspace || !workspace.toplevels) return 0;
                                return workspace.toplevels.values || workspace.toplevels;
                            }
                            delegate: Rectangle {
                                readonly property var win: modelData
                                readonly property var mon: workspace.monitor || { width: 1920, height: 1080, x: 0, y: 0 }
                                
                                readonly property real rawX: win.x !== undefined ? win.x : (win.lastIpcObject?.at?.[0] || 0)
                                readonly property real rawY: win.y !== undefined ? win.y : (win.lastIpcObject?.at?.[1] || 0)
                                readonly property real rawW: win.width !== undefined ? win.width : (win.lastIpcObject?.size?.[0] || 400)
                                readonly property real rawH: win.height !== undefined ? win.height : (win.lastIpcObject?.size?.[1] || 300)

                                x: ((rawX - (mon.x || 0)) / mon.width) * previewArea.width
                                y: ((rawY - (mon.y || 0)) / mon.height) * previewArea.height
                                width: Math.max(20, (rawW / mon.width) * previewArea.width)
                                height: Math.max(20, (rawH / mon.height) * previewArea.height)
                                
                                color: (Root.Theme && Root.Theme.surface0) ? Root.Theme.surface0 : "#313244"
                                radius: 4
                                border.color: (Root.Theme && Root.Theme.surface1) ? Root.Theme.surface1 : "#45475a"
                                border.width: 1
                                opacity: 0.9

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.9
                                    height: parent.height * 0.9
                                    spacing: 2

                                    Image {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: Math.min(parent.width, 32)
                                        Layout.preferredHeight: Math.min(parent.height * 0.6, 32)
                                        source: Services.IconsFetcher.getIconPath(win.appName, win.desktopEntry, win.initialClass || win.appId || win.title)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: win.title || ""
                                        font.pixelSize: 8
                                        color: (Root.Theme && Root.Theme.text) ? Root.Theme.text : "#cdd6f4"
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                        visible: parent.height > 30
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Info Row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        
                        Text {
                            text: "WS " + workspace.id
                            font.bold: true
                            font.pixelSize: 12
                            color: workspace.active ? ((Root.Theme && Root.Theme.mauve) ? Root.Theme.mauve : "#cba6f7") : ((Root.Theme && Root.Theme.subtext0) ? Root.Theme.subtext0 : "gray")
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: {
                                let count = 0;
                                if (workspace.toplevels) {
                                    count = workspace.toplevels.values ? workspace.toplevels.values.length : workspace.toplevels.length;
                                }
                                return count + (count === 1 ? " window" : " windows");
                            }
                            font.pixelSize: 10
                            color: (Root.Theme && Root.Theme.overlay1) ? Root.Theme.overlay1 : "#7f849c"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + workspace.id)
                }
            }
        }

        Item { Layout.fillWidth: true }
    }
}
