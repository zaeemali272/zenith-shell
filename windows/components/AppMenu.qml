import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../" as Root

Item {
    id: root
    property string searchText: ""
    property int currentIndex: 0

    // Filtered model management
    ListModel { id: filteredModel }
    
    FolderListModel {
        id: folderModel
        folder: "file:///usr/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        
        onCountChanged: updateList()
    }

    function updateList() {
        filteredModel.clear();
        let arr = [];
        for (let i = 0; i < folderModel.count; i++) {
            let fn = folderModel.get(i, "fileName");
            let name = fn.replace(".desktop", "").replace(/-/g, " ");
            name = name.charAt(0).toUpperCase() + name.slice(1);
            if (root.searchText === "" || name.toLowerCase().includes(root.searchText.toLowerCase())) {
                arr.push({ fileName: fn, displayName: name });
            }
        }
        arr.sort((a, b) => a.displayName.localeCompare(b.displayName));
        for (let item of arr) filteredModel.append(item);
        root.currentIndex = 0;
    }

    onSearchTextChanged: updateList()

    GridView {
        id: grid
        anchors.fill: parent
        cellWidth: Math.floor(grid.width / 6)
        cellHeight: Root.Theme.scaled ? Root.Theme.scaled(150) : 150
        clip: true
        model: filteredModel
        // Snap movement
        snapMode: GridView.SnapToRow
        
        delegate: Item {
            width: grid.cellWidth
            height: grid.cellHeight
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                width: grid.cellWidth - 20
                // Visual selection indicator
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -5
                    color: (index === root.currentIndex) ? (Root.Theme.surface1 || "#45475a") : "transparent"
                    radius: 15
                }

                Rectangle {
                    width: 60; height: 60; radius: 15
                    color: Root.Theme.surface0 || "#242532"
                    Layout.alignment: Qt.AlignHCenter
                    Text {
                        anchors.centerIn: parent
                        text: getIconForApp(model.displayName)
                        font.family: Root.Theme.iconFont || "monospace"
                        font.pixelSize: 30
                        color: getIconColorForApp(model.displayName)
                    }
                }
                Text {
                    text: model.displayName
                    color: Root.Theme.text || "#cdd6f4"
                    font.pixelSize: 12
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: { root.currentIndex = index; launchApp(model.fileName); }
            }
        }
    }

    function launchApp(fileName) {
        launchProcess.command = ["gtk-launch", fileName];
        launchProcess.running = true;
        if (win) win.active = false;
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (root.currentIndex < filteredModel.count) {
                launchApp(filteredModel.get(root.currentIndex).fileName);
            }
        } else if (event.key === Qt.Key_Right) {
            root.currentIndex = Math.min(root.currentIndex + 1, filteredModel.count - 1);
        } else if (event.key === Qt.Key_Left) {
            root.currentIndex = Math.max(root.currentIndex - 1, 0);
        }
    }
    
    Process { id: launchProcess }

    function getIconForApp(name) {
        let n = name.toLowerCase();
        if (n.includes("youtube")) return "󰗃";
        if (n.includes("term") || n.includes("kitty")) return "󰆍";
        if (n.includes("browser") || n.includes("firefox")) return "󰈹";
        return "󰀻";
    }

    function getIconColorForApp(name) {
        let n = name.toLowerCase();
        if (n.includes("youtube")) return "#ff0000";
        return "#89b4fa";
    }
}
