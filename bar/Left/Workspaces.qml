import ".."
import "../.."
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import "../../Settings"

Pill {
    id: workspaceRoot
    
    // Use the setting from GeneralSettings
    readonly property string displayStyle: GeneralSettings.workspaceDisplayStyle
    
    implicitHeight: Theme.pillHeight
    implicitWidth: row.width + (Theme.pillPadding * 2)
    anchors.verticalCenter: parent.verticalCenter
    clip: true 

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(workspaceRoot.QsWindow.window?.screen)
    property var activeWorkspaces: []
    property int activeIndex: 0

    function update() {
        let wsList = Hyprland.workspaces.values
            .filter(ws => ws && ws.id > 0)
            .sort((a, b) => a.id - b.id);
        activeWorkspaces = wsList;
        
        let focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
        activeIndex = wsList.findIndex(ws => ws.id === focusedId);
        if (activeIndex === -1) activeIndex = 0;
    }

    Component.onCompleted: update()
    Connections { target: Hyprland.workspaces; function onValuesChanged() { update(); } }
    Connections { target: Hyprland; function onFocusedWorkspaceChanged() { update(); } }

    // THE RUNNING INDICATOR (Layer 1)
    Rectangle {
        id: activeIndicator
        z: 1 // Lower than the row to not block clicks
        width: 32; height: parent.height - 8
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.pillRadius - 2
        color: Theme.activePillColor
        
        // Logical X: Tied to the row's position
        x: row.x + (activeIndex * (26 + row.spacing)) - ((width - 26) / 2)
        
        Behavior on x {
            SpringAnimation { spring: 4; damping: 0.4; mass: 0.8 }
        }

        // Active ID Text
        Text {
            anchors.centerIn: parent
            text: activeWorkspaces[activeIndex]?.id || ""
            font.pixelSize: 11; font.bold: true
            color: Theme.activeTextColor
        }
    }

    // THE TRACK (Layer 2)
    Row {
        id: row
        spacing: 6 // Reduced spacing
        anchors.centerIn: parent
        z: 10 // CRITICAL: Higher than Pill's internal MouseArea to receive clicks

        Repeater {
            model: activeWorkspaces.length
            delegate: Item {
                width: 26; height: 26
                
                // Content Switcher
                Rectangle {
                    visible: workspaceRoot.displayStyle === "dots"
                    anchors.centerIn: parent
                    width: 6; height: 6; radius: 3
                    color: Theme.fontColor || "#ffffff" 
                    opacity: activeIndex === index ? 0 : 0.5
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Text {
                    visible: workspaceRoot.displayStyle === "numbers"
                    anchors.centerIn: parent
                    text: activeWorkspaces[index].id
                    font.pixelSize: 10; font.bold: true
                    color: Theme.fontColor || "#ffffff" 
                    opacity: activeIndex === index ? 0 : 0.5
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        console.log(`[Workspaces] Clicked workspace ${activeWorkspaces[index].id}`)
                        Hyprland.dispatch(`workspace ${activeWorkspaces[index].id}`)
                    }
                }
            }
        }
    }

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0) Hyprland.dispatch(`workspace r+1`)
            else if (event.angleDelta.y > 0) Hyprland.dispatch(`workspace r-1`)
        }
    }
}
