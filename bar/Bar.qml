// bar/Bar.qml
import ".."
import "./Menu"
import "./Right"
import "../services"
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
    implicitWidth: screen ? screen.width : 1920
    color: "transparent"

    // Removed generic anchors as they are not valid for PanelWindow positioning in Quickshell/Layershell


    Rectangle {
        id: barVisual

        anchors.fill: parent

        color: Theme.barColor
        radius: Theme.barRadius || 0
        clip: true
        opacity: 0
        y: -height

        ParallelAnimation {
            id: barEntryAnim

            NumberAnimation {
                target: barVisual
                property: "y"
                to: 0
                duration: 800
                easing.type: Easing.OutExpo
            }

            NumberAnimation {
                target: barVisual
                property: "opacity"
                to: 1
                duration: 600
            }
        }

        Component.onCompleted: {
            console.log("[Bar] Component.onCompleted: Starting barEntryAnim.");
            barEntryAnim.start();
        }

        // --- LEFT SIDE ---
        Left {
            id: leftSide
            anchors.left: parent.left
            anchors.leftMargin: Theme.barMarginLeft
            anchors.verticalCenter: parent.verticalCenter
        }

        // --- PERFECT CENTER ---
        Center {
            id: centerSide
            anchors.verticalCenter: parent.verticalCenter
            width: {
                let availableSpace = rightLayout.x - (leftSide.x + leftSide.width) - (Theme.pillGap * 2);
                return Math.max(100, Math.min(implicitWidth, availableSpace));
            }
            clip: true
            x: {
                let preferredX = (parent.width - width) / 2;
                let leftBound = leftSide.x + leftSide.width + Theme.pillGap;
                let rightBound = rightLayout.x - width - Theme.pillGap;
                if (rightLayout.x <= 0) {
                    console.log("[Bar] Center centering normally (rightLayout.x <= 0).");
                    return preferredX;
                }
                return Math.max(leftBound, Math.min(preferredX, rightBound));
            }
            controlCenterMenuRef: bar.controlCenterMenuRef
        }

        // --- RIGHT SIDE ---
        RowLayout {
            id: rightLayout
            anchors.right: parent.right
            anchors.rightMargin: Theme.barMarginRight
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.pillSpacing

            Tray { menuRef: trayPopup }
            Network { id: wifiWidget }
            PowerProfile { id: powerProfileWidget }
            Resources { }
            Volume { id: volumeWidget }
            Bluetooth { id: bluetoothWidget }
            Battery { id: batteryWidget }
            Power { }
        }
    }

    QuickSettingsMenu {
        id: quickSettingsMenu
        parentWindow: bar
    }

    TrayMenu {
        id: trayPopup
        parentWindow: bar
    }
    }