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

    property var controlCenterMenuRef: null

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
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

    Rectangle {
        id: barVisual

        anchors.fill: parent

        color: Theme.barColor
        radius: Theme.barRadius || 0
        clip: true
        opacity: GeneralSettings.barEntryAnimation ? 0 : 1
        y: GeneralSettings.barEntryAnimation ? -height : 0

        ParallelAnimation {
            id: barEntryAnim

            NumberAnimation {
                target: barVisual
                property: "y"
                to: 0
                duration: GeneralSettings.barAnimationDuration
                easing.type: Easing.OutExpo
            }

            NumberAnimation {
                target: barVisual
                property: "opacity"
                to: 1
                duration: GeneralSettings.barAnimationDuration * 0.75
            }
        }

        // --- DISMISS ON BAR CLICK ---
        MouseArea {
            anchors.fill: parent
            z: -1 // Bottom of stack, handles clicks on empty space
            onClicked: MenuService.closeAll()
        }

        Component.onCompleted: {
            if (GeneralSettings.barEntryAnimation) {
                barEntryAnim.start();
                contentFadeAnim.start();
            }
        }
        
        NumberAnimation {
            id: contentFadeAnim
            targets: [leftSide, centerSide, rightLayout]
            property: "opacity"
            from: 0; to: 1
            duration: GeneralSettings.barAnimationDuration * 1.5
        }

        // --- LEFT SIDE ---
        Left {
            id: leftSide
            anchors.left: parent.left
            anchors.leftMargin: Theme.barMarginLeft
            anchors.verticalCenter: parent.verticalCenter
            opacity: GeneralSettings.barEntryAnimation ? 0 : 1
        }

        // --- PERFECT CENTER ---
        Center {
            id: centerSide
            anchors.verticalCenter: parent.verticalCenter
            controlCenterMenuRef: bar.controlCenterMenuRef
            opacity: GeneralSettings.barEntryAnimation ? 0 : 1
            
            x: {
                let preferredX = (parent.width - width) / 2;
                let leftBound = leftSide.x + leftSide.width + Theme.pillGap;
                let rightBound = rightLayout.x - width - Theme.pillGap;
                
                // If it can fit in the center, put it there.
                // If the right side is pushing it, move it left.
                // But don't let it overlap the left side.
                return Math.max(leftBound, Math.min(preferredX, rightBound));
            }

            // Hide only if the available space is smaller than the widget itself
            visible: {
                let availableSpace = rightLayout.x - (leftSide.x + leftSide.width) - (Theme.pillGap * 2);
                return width <= availableSpace || !Theme.isSmallScreen;
            }
        }

        // --- RIGHT SIDE ---
        RowLayout {
            id: rightLayout
            anchors.right: parent.right
            anchors.rightMargin: Theme.barMarginRight
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.pillSpacing
            opacity: GeneralSettings.barEntryAnimation ? 0 : 1

            Tray { menuRef: trayPopup }

            Update { visible: !Theme.isSmallScreen }
            
            Network { 
                id: wifiWidget 
                visible: GeneralSettings.enableResources 
            }
            
            PowerProfile { 
                id: powerProfileWidget 
                visible: GeneralSettings.enablePowerProfiles && !Theme.isSmallScreen
            }
            
            Resources { 
                visible: GeneralSettings.enableResources && !Theme.isSmallScreen
            }
            
            Volume { 
                id: volumeWidget 
            }
            
            Bluetooth { 
                id: bluetoothWidget 
            }
            
            Battery { 
                id: batteryWidget 
            }
            
            Power { }
        }
    }

    TrayMenu {
        id: trayPopup
        anchor.window: bar
    }
}
