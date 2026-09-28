// bar/Bar.qml
import ".."
import "./Menu"
import "./Right"
import "../services"
import "../Settings"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: bar


    WlrLayershell.keyboardFocus: DynamicIslandService.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Auto
    WlrLayershell.margins {
        top: Theme.barMarginTop
        bottom: Theme.barMarginBottom
        left: Theme.barMarginLeft
        right: Theme.barMarginRight
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    implicitWidth: screen ? screen.width : Theme.screenWidth
    color: "transparent"
    visible: !HyprlandService.isFullscreen

    Rectangle {
        id: barVisual

        anchors.fill: parent

        color: Theme.barColor
        radius: Theme.barRadius || 0
        clip: true
        opacity: BarSettings.entryAnimation ? 0 : 1
        y: BarSettings.entryAnimation ? -height : 0

        ParallelAnimation {
            id: barEntryAnim

            NumberAnimation {
                target: barVisual
                property: "y"
                to: 0
                duration: BarSettings.animationDuration
                easing.type: Easing.OutExpo
            }

            NumberAnimation {
                target: barVisual
                property: "opacity"
                to: 1
                duration: BarSettings.animationDuration * 0.75
            }
        }

        // --- DISMISS ON BAR CLICK ---
        MouseArea {
            anchors.fill: parent
            z: -1 // Bottom of stack, handles clicks on empty space
            // Ensure we capture clicks even on transparent background
            onPressed: (mouse) => mouse.accepted = true
            onClicked: {
                MenuService.closeAll();
            }
        }

        Component.onCompleted: {
            if (BarSettings.entryAnimation) {
                barEntryAnim.start();
                contentFadeAnim.start();
            }
        }
        
        SequentialAnimation {
            id: contentFadeAnim
            ParallelAnimation {
                NumberAnimation { target: leftSide; property: "opacity"; from: 0; to: 1; duration: BarSettings.animationDuration }
                NumberAnimation { target: centerSide; property: "opacity"; from: 0; to: 1; duration: BarSettings.animationDuration }
            }
            NumberAnimation { target: trayPill; property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { target: wifiWidget; property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { target: resourcesWidget; property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { target: quickSettingsCluster; property: "opacity"; from: 0; to: 1; duration: 180 }
        }

        // --- LEFT SIDE ---
        Left {
            id: leftSide
            anchors.left: parent.left
            anchors.leftMargin: Theme.barMarginLeft
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.pillHeight
            opacity: BarSettings.entryAnimation ? 0 : 1
        }

        // --- PERFECT CENTER ---
        Center {
            id: centerSide
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.pillHeight
            opacity: BarSettings.entryAnimation ? 0 : 1
        }

        // --- RIGHT SIDE ---
        RowLayout {
            id: rightLayout
            anchors.right: parent.right
            anchors.rightMargin: Theme.barMarginRight
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.pillHeight
            spacing: Theme.pillSpacing

            Tray { id: trayPill; menuRef: trayPopup; opacity: BarSettings.entryAnimation ? 0 : 1 }
            
            Network {
                id: wifiWidget
                visible: WidgetSettings.enableNetwork && HardwareService.hasNetworking
                opacity: BarSettings.entryAnimation ? 0 : 1
            }
            
            Resources { 
                id: resourcesWidget
                visible: WidgetSettings.enableResources && !Theme.isSmallScreen
                opacity: BarSettings.entryAnimation ? 0 : 1
            }
            
            QuickSettingsCluster {
                id: quickSettingsCluster
                opacity: BarSettings.entryAnimation ? 0 : 1
            }
        }
    }

    TrayMenu {
        id: trayPopup
        anchor.window: bar
    }
}
