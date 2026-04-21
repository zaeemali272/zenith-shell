import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../" as Root

Item {
    id: root
    implicitHeight: Root.Theme.scaled ? Root.Theme.scaled(250) : 250
    
    property var activeWorkspaces: []

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
                    width: 250
                    height: 150
                    radius: 12
                    color: Root.Theme.mantle || "#181825"
                    border.color: modelData.active ? (Root.Theme.mauve || "#cba6f7") : (Root.Theme.surface0 || "#313244")
                    border.width: 2
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        // Workspace Preview Placeholder
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            color: Root.Theme.surface0 || "#313244"
                            radius: 8
                            Text { 
                                anchors.centerIn: parent
                                text: "WS " + modelData.id
                                color: "white"
                                font.pixelSize: 30
                                opacity: 0.3
                            }
                        }

                        // Window Count using 'toplevels'
                        Text {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            text: {
                                let count = 0;
                                if (modelData.toplevels) {
                                    // Handle both Map (values.length) and List (.length) structures
                                    count = modelData.toplevels.values ? modelData.toplevels.values.length : modelData.toplevels.length;
                                }
                                return count + (count === 1 ? " window" : " windows");
                            }
                            font.bold: true
                            color: Root.Theme.text || "#cdd6f4"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        // Optional: Show the title of the first window
                        Text {
                             Layout.fillWidth: true
                             text: {
                                 if (modelData.toplevels) {
                                     let tls = modelData.toplevels.values || modelData.toplevels;
                                     return tls.length > 0 ? (tls[0].title || "Untitled") : "";
                                 }
                                 return "";
                             }
                             color: Root.Theme.subtext0 || "gray"
                             font.pixelSize: 11
                             horizontalAlignment: Text.AlignHCenter
                             clip: true
                             elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                    }
                }
            }
        }
    }
}
