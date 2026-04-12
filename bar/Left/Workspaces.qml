import ".."
import "../.."
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland

Item {
    id: workspaceBar
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.pillHeight
    
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(workspaceBar.QsWindow.window?.screen)
    property var activeWorkspaces: []

    function updateActiveWorkspaces() {
        activeWorkspaces = Hyprland.workspaces.values
            .filter(ws => ws)
            .sort((a, b) => a.id - b.id);
    }

    Component.onCompleted: updateActiveWorkspaces()

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { updateActiveWorkspaces(); }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { updateActiveWorkspaces(); }
    }
    Connections {
        target: monitor
        function onActiveWorkspaceChanged() { updateActiveWorkspaces(); }
    }
    
    // Background handling
    Rectangle {
        anchors.fill: row
        anchors.margins: -Theme.scaled(4)
        color: Theme.pillColor
        radius: Theme.pillRadius + Theme.scaled(20)
        visible: Theme.workspaceBackgroundStyle === "full"
        z: -1
    }

    Row {
        id: row
        spacing: Theme.scaled(Theme.pillSpacing)
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: activeWorkspaces.length

            delegate: Rectangle {
                width: Theme.scaled(25)
                implicitHeight: Theme.workspaceBackgroundStyle === "full" ? Theme.scaled(Theme.pillHeight - Theme.scaled(8)) : Theme.scaled(Theme.pillHeight)
                radius: Theme.pillRadius
                smooth: true

                property var workspace: activeWorkspaces[index]
                property bool isOccupied: workspace.windows > 0

                // Fill color logic
                color: Theme.workspaceBackgroundStyle === "full" ? "transparent" : (workspace.active ? Theme.wsActiveColor : (isOccupied ? Theme.wsOccupiedColor : Theme.wsEmptyColor))
                border.color: Theme.workspaceBackgroundStyle === "full" ? "transparent" : (workspace.active ? Theme.wsActiveColor : "transparent")
                border.width: Theme.scaled(1)

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch(`workspace ${workspace.id}`)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: workspace.id.toString()
                    font.pixelSize: Theme.scaled(12)
                    color: Theme.workspaceBackgroundStyle === "full" ? (workspace.active ? Theme.wsActiveColor : Theme.text) : (workspace.active ? Theme.wsActiveTextColor : Theme.inactiveTextColor)
                }
            }
        }
    }

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0) Hyprland.dispatch(`workspace r+1`)
            else if (event.angleDelta.y > 0) Hyprland.dispatch(`workspace r-1`)
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }
}
