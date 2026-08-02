import ".."
import "../.."
import "../../Settings"
import "../../services"
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland

Item {
    id: workspaceBar
    // Clean dynamic bounds scaling alongside inner element rows
    implicitWidth: row.implicitWidth + (Theme.scaled ? Theme.scaled(28) : 28)
    implicitHeight: Theme.pillHeight ? Theme.pillHeight : (Theme.scaled ? Theme.scaled(32) : 32)

    readonly property HyprlandMonitor monitor: QsWindow.window ? QsWindow.window.monitor : null

    // Balanced Solid Capsule Background Track
    Rectangle {
        anchors.fill: parent
        color: Theme.pillColor
        radius: Theme.pillRadius ? Theme.pillRadius : height / 2
        opacity: 1.0
        visible: true
        z: -1
    }

    Row {
        id: row
        // Well proportioned gap spacing to prevent overlapping
        spacing: Theme.scaled ? Theme.scaled(8) : 8
        anchors.centerIn: parent

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                id: wsDelegate

                visible: modelData && modelData.id > 0

                // --- CALIBRATED ELEMENT SIZING ---
                // Sizing handled explicitly via properties to keep layouts stable
                width: visible ? (isCurrentActive ? (WorkspaceSettings.displayStyle === "numbers" ? Theme.scaled(44) : Theme.scaled(36)) : Theme.scaled(22)) : 0
                height: Theme.scaled ? Theme.scaled(20) : 20
                radius: height / 2
                smooth: true
                anchors.verticalCenter: parent.verticalCenter

                readonly property bool isOccupied: modelData ? (modelData.toplevels.count > 0) : false
                readonly property bool isCurrentActive: (Hyprland.focusedWorkspace && modelData) ? (Hyprland.focusedWorkspace.id === modelData.id) : false

                color: isCurrentActive
                       ? (Theme.wsActiveColor ? Theme.wsActiveColor : Theme.accentColor)
                       : (isOccupied ? (Theme.wsOccupiedColor ? Theme.wsOccupiedColor : Theme.surface2) : Theme.surface1)

                opacity: isCurrentActive ? 1.0 : (isOccupied ? 0.85 : 0.6)

                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }

                // Kept at 1.0 default baseline to stop parent overflow clipping
                scale: wsMouse.containsMouse ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData) {
                            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${modelData.id}" })`)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData ? modelData.id.toString() : ""
                    font.pixelSize: Theme.scaled ? Theme.scaled(11) : 11
                    font.bold: true
                    color: isCurrentActive ? Colors.on_primary : "#ffffff"
                    opacity: isCurrentActive ? 1.0 : 0.75

                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
            }
        }
    }

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0) {
                Hyprland.dispatch("workspace e+1");
            } else if (event.angleDelta.y > 0) {
                Hyprland.dispatch("workspace e-1");
            }
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }
}