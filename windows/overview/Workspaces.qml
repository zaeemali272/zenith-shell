import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../" as Shell
import "../components" as Components
import ".." as Windows

Item {
    id: root
    implicitHeight: (Shell.Theme && Shell.Theme.scaled) ? Shell.Theme.scaled(200) : 200
    
    property var activeWorkspaces: []
    property string currentWallpaper: ""
    property int refreshTick: 0
    property var clientData: ({})

    onVisibleChanged: if (visible) updateWorkspaces()

    Process {
        id: clientFetcher
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const clients = JSON.parse(text);
                    const map = {};
                    clients.forEach(c => {
                        let addr = c.address;
                        if (addr.startsWith("0x")) addr = addr.substring(2);
                        map[addr] = c;
                    });
                    root.clientData = map;
                    root.refreshTick++;
                } catch (e) {
                    console.error("[Overview] Failed to parse hyprctl clients:", e);
                }
            }
        }
    }

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
        // Trigger manual client fetch to ensure fresh data
        clientFetcher.running = false;
        clientFetcher.running = true;

        if (!Hyprland.workspaces) return;
        
        let wsValues = Hyprland.workspaces.values;
        if (!wsValues) return;

        let newList = [];
        for (let i = 0; i < wsValues.length; i++) {
            let ws = wsValues[i];
            if (ws && ws.id > 0) {
                newList.push(ws);
            }
        }
        
        newList.sort((a, b) => a.id - b.id);
        
        // Force a model refresh by assigning a new array reference
        activeWorkspaces = newList;
        root.refreshTick++;
    }

    Component.onCompleted: updateWorkspaces()

    Connections {
        target: Hyprland.workspaces
        ignoreUnknownSignals: true
        function onValuesChanged() { if (root.visible) updateWorkspaces(); }
    }
    
    Connections {
        target: Hyprland.toplevels
        ignoreUnknownSignals: true
        function onValuesChanged() { if (root.visible) updateWorkspaces(); }
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
                color: (Shell.Theme && Shell.Theme.mantle) ? Shell.Theme.mantle : "#a1232323"
                border.color: modelData.active ? ((Shell.Theme && Shell.Theme.mauve) ? Shell.Theme.mauve : '#a65e5e5e') : "transparent"
                border.width: 2
                
                readonly property var workspace: modelData
                readonly property var displayWindows: {
                    let _force = root.refreshTick;
                    if (!workspace || !workspace.toplevels) return [];
                    let list = workspace.toplevels.values || [];
                    let filtered = [];
                    for (let i = 0; i < list.length; i++) {
                        let w = list[i];
                        if (!w) continue;
                        let id = w.appId || w.initialClass || "";
                        let t = w.title || w.initialTitle || "";
                        if (!id && !t) continue;
                        if (Windows.IconsFetcher.isMainApp(id, t)) filtered.push(w);
                    }
                    return filtered;
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Rectangle {
                        id: previewArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: (Shell.Theme && Shell.Theme.crust) ? Shell.Theme.crust : '#a1000000'
                        radius: 12
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: root.currentWallpaper
                            fillMode: Image.PreserveAspectCrop
                            visible: source != "" && displayWindows.length === 0
                            opacity: 0.4
                        }

                        Repeater {
                            model: displayWindows
                            delegate: Rectangle {
                                id: winRect
                                readonly property var win: modelData
                                readonly property var mon: workspace.monitor || { width: 1920, height: 1080, x: 0, y: 0 }
                                
                                // Address matching logic
                                readonly property string winAddr: {
                                    let addr = win.address || "";
                                    if (addr.startsWith("0x")) return addr.substring(2);
                                    return addr;
                                }
                                
                                readonly property var ipcData: root.clientData[winAddr]
                                
                                readonly property real rawX: { 
                                    let _f = root.refreshTick; 
                                    if (ipcData && ipcData.at) return ipcData.at[0];
                                    return (win && win.x !== undefined) ? win.x : 0;
                                }
                                readonly property real rawY: { 
                                    let _f = root.refreshTick; 
                                    if (ipcData && ipcData.at) return ipcData.at[1];
                                    return (win && win.y !== undefined) ? win.y : 0;
                                }
                                readonly property real rawW: { 
                                    let _f = root.refreshTick; 
                                    if (ipcData && ipcData.size) return ipcData.size[0];
                                    return (win && win.width !== undefined) ? win.width : 400;
                                }
                                readonly property real rawH: { 
                                    let _f = root.refreshTick; 
                                    if (ipcData && ipcData.size) return ipcData.size[1];
                                    return (win && win.height !== undefined) ? win.height : 300;
                                }
                                
                                readonly property real barHeight: 40
                                x: ((rawX - (mon.x || 0)) / mon.width) * previewArea.width
                                y: ((rawY - (mon.y || 0) - barHeight) / (mon.height - barHeight)) * previewArea.height
                                width: Math.max(40, (rawW / mon.width) * previewArea.width)
                                height: Math.max(40, (rawH / (mon.height - barHeight)) * previewArea.height)
                                
                                color: (Shell.Theme && Shell.Theme.surface0) ? Shell.Theme.surface0 : '#41010101'
                                radius: 8
                                border.color: (win && win.active) ? ((Shell.Theme && Shell.Theme.mauve) ? Shell.Theme.mauve : '#00282828') : ((Shell.Theme && Shell.Theme.surface1) ? Shell.Theme.surface1 : '#94000000')
                                border.width: 1
                                opacity: 0.95

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    Item { Layout.fillHeight: true }

                                    Components.IconImage {
                                        id: appIcon
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: Math.min(parent.width * 0.85, 48)
                                        Layout.preferredHeight: Math.min(parent.height * 0.45, 48)
                                        appName: {
                                            if (!win) return "";
                                            let raw = win.appId || win.initialClass || "";
                                            if (!raw) return win.title || "";
                                            let parts = raw.split(".");
                                            return parts[parts.length - 1];
                                        }
                                        candidates: {
                                            if (!win) return [];
                                            let id = (win.appId && win.appId !== "") ? win.appId : (win.initialClass || "");
                                            let title = win.title || win.initialTitle || "";
                                            return Windows.IconsFetcher.getCandidates(id, id, title);
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: {
                                            if (!win) return "Unknown";
                                            let raw = win.appId || win.initialClass || "";
                                            if (!raw) return win.title || "Unknown";
                                            let parts = raw.split(".");
                                            let name = parts[parts.length - 1];
                                            if (!name) return win.title || "Unknown";
                                            name = name.replace(/[-_]/g, " ");
                                            return name.charAt(0).toUpperCase() + name.slice(1);
                                        }
                                        font.pixelSize: 10
                                        color: (Shell.Theme && Shell.Theme.text) ? Shell.Theme.text : '#9d9d9d'
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        visible: parent.height > 55
                                    }

                                    Item { Layout.fillHeight: true }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        
                        Text {
                            text: "WS " + workspace.id
                            font.bold: true
                            font.pixelSize: 12
                            color: workspace.active ? ((Shell.Theme && Shell.Theme.mauve) ? Shell.Theme.mauve : '#ffffff') : ((Shell.Theme && Shell.Theme.subtext0) ? Shell.Theme.subtext0 : "gray")
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
                            color: (Shell.Theme && Shell.Theme.overlay1) ? Shell.Theme.overlay1 : "#7f849c"
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
