import ".."
import "../.."
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland

Row {
    id: workspaceBar
    spacing: Theme.pillSpacing
    anchors.verticalCenter: parent.verticalCenter

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(workspaceBar.QsWindow.window?.screen)
    property var activeWorkspaces: []  // list of HyprlandWorkspace objects

    // Compute active workspace index in the Repeater
    property int activeWorkspaceIndex: 0

    // Update activeWorkspaces dynamically
    function updateActiveWorkspaces() {
        // Filter only existing workspaces
        activeWorkspaces = Hyprland.workspaces.values
            .filter(ws => ws) // ensure it's valid
            .sort((a, b) => a.id - b.id) // sort by id

        // Compute index of the active workspace
        activeWorkspaceIndex = activeWorkspaces.findIndex(ws => ws.active)
        if (activeWorkspaceIndex === -1) activeWorkspaceIndex = 0
    }

    Component.onCompleted: updateActiveWorkspaces()

    // Update dynamically when Hyprland workspaces change
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { updateActiveWorkspaces(); }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { updateActiveWorkspaces(); }
    }

    // Update active workspace when monitor signals change
    Connections {
        target: monitor
        function onActiveWorkspaceChanged() { updateActiveWorkspaces(); }
    }

    Repeater {
        model: activeWorkspaces.length

        delegate: Rectangle {
            width: 25
            implicitHeight: Theme.pillHeight
            radius: Theme.pillRadius
            smooth: true

            property var workspace: activeWorkspaces[index]

            // Fill color only for active workspace
            color: workspace.active ? Theme.activePillColor : Theme.pillColor
            border.color: workspace.active ? Theme.activeBorderColor : "transparent"
            border.width: 1

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Hyprland.dispatch(`workspace ${workspace.id}`)
                }
            }

            Text {
                anchors.centerIn: parent
                text: workspace.id.toString()
                font.pixelSize: 12
                color: workspace.active ? Theme.activeTextColor : Theme.inactiveTextColor
            }
        }
    }

    // Scroll to switch workspaces
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0) Hyprland.dispatch(`workspace r+1`)
            else if (event.angleDelta.y > 0) Hyprland.dispatch(`workspace r-1`)
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }
}
