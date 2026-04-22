import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../" as Shell
import ".." as Windows

Item {
    id: root
    property string searchText: ""
    property int currentIndex: 0

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
        cellWidth: Math.floor(grid.width / (Shell.Theme.appMenuCol || 6))
        cellHeight: Shell.Theme.scaled ? Shell.Theme.scaled(120) : 120
        clip: true
        model: filteredModel
        snapMode: GridView.SnapToRow
        
        delegate: Item {
            width: grid.cellWidth
            height: grid.cellHeight
            
            Rectangle {
                anchors.fill: layout
                anchors.margins: -5
                color: (index === root.currentIndex) ? (Shell.Theme.surface1 || "#45475a") : "transparent"
                radius: 12
                z: -1
            }

            ColumnLayout {
                id: layout
                anchors.centerIn: parent
                spacing: 8
                width: grid.cellWidth - 20
                
                Rectangle {
                    width: Shell.Theme.scaled ? Shell.Theme.scaled(56) : 56
                    height: width
                    radius: 14
                    color: (index === root.currentIndex) ? (Shell.Theme.surface2 || "#585b70") : (Shell.Theme.surface0 || "#242532")
                    Layout.alignment: Qt.AlignHCenter
                    
                    Image {
                        anchors.centerIn: parent
                        width: parent.width * 0.7
                        height: parent.height * 0.7
                        source: Windows.IconsFetcher.getIconPath("", model.fileName, "")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        
                        onStatusChanged: {
                            if (status === Image.Error) {
                                source = "image://icon/application-x-executable"
                            }
                        }
                    }
                }

                Text {
                    text: model.displayName
                    color: (index === root.currentIndex) ? (Shell.Theme.mauve || "#cba6f7") : (Shell.Theme.text || "#cdd6f4")
                    font.pixelSize: 11
                    font.bold: index === root.currentIndex
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.currentIndex = index
                onClicked: { launchApp(model.fileName); }
            }
        }
    }

    function launchApp(fileName) {
        launchProcess.command = ["gtk-launch", fileName];
        launchProcess.running = true;
        
        let p = root.parent;
        while (p) {
            if (p.visible !== undefined && p.hasOwnProperty("active")) {
                p.active = false;
                break;
            }
            p = p.parent;
        }
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
        } else if (event.key === Qt.Key_Down) {
            root.currentIndex = Math.min(root.currentIndex + (Root.Theme.appMenuCol || 6), filteredModel.count - 1);
        } else if (event.key === Qt.Key_Up) {
            root.currentIndex = Math.max(root.currentIndex - (Root.Theme.appMenuCol || 6), 0);
        }
    }
    
    Process { id: launchProcess }
}
