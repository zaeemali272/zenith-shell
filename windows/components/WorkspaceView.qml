import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../" as Root

Item {
    id: root
    implicitHeight: Root.Theme.scaled ? Root.Theme.scaled(200) : 200
    
    // Binding directly to Hyprland.workspaces for auto-updates
    RowLayout {
        anchors.centerIn: parent
        spacing: 20

        Repeater {
            model: Hyprland.workspaces
            delegate: Rectangle {
                readonly property var ws: modelData
                
                // Only show if the workspace actually exists
                visible: ws && ws.id > 0
                width: visible ? 250 : 0
                height: visible ? 150 : 0
                
                radius: 12
                color: Root.Theme.mantle || "#181825"
                border.color: ws.active ? (Root.Theme.mauve || "#cba6f7") : (Root.Theme.surface0 || "#313244")
                border.width: 2
                
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: parent.visible
                    Text {
                        text: "Workspace " + ws.id
                        font.bold: true
                        color: Root.Theme.text || "#cdd6f4"
                    }
                    Text {
                        text: (ws.windows || 0) + " windows"
                        font.pixelSize: 12
                        color: Root.Theme.subtext0 || "#a6adc8"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + ws.id)
                }
            }
        }
    }
}
