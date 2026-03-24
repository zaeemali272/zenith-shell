// bar/Bar.qml
import ".."
import "./Menu"
import "./Right"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: bar

    property var controlCenterMenuRef: null

    WlrLayershell.keyboardFocus: WlrLayershell.None
    implicitHeight: Theme.barHeight
    color: "transparent"

    anchors {
        left: true
        top: true
        right: true
    }

    margins {
        top: Theme.barMarginTop
        bottom: Theme.barMarginBottom
        left: Theme.barMarginLeft
        right: Theme.barMarginRight
    }

    Rectangle {
        id: barVisual

        width: bar.width
        height: bar.height

        color: Theme.barColor
        radius: Theme.barRadius || 0
        clip: true
        opacity: 0
        y: -height
        Component.onCompleted: barEntryAnim.start()

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

        // --- LEFT SIDE ---
        // Just anchor the module directly. No need for a container width loop.
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
            // --- SAFE DYNAMIC WIDTH ---
            // We add a Math.max(100, ...) so it never shrinks below 100px
            width: {
                let availableSpace = rightLayout.x - (leftSide.x + leftSide.width) - (Theme.pillGap * 2);
                return Math.max(100, Math.min(implicitWidth, availableSpace));
            }
            clip: true // Keeps the text from bleeding into other icons if it's too long
            x: {
                let preferredX = (parent.width - width) / 2;
                let leftBound = leftSide.x + leftSide.width + Theme.pillGap;
                let rightBound = rightLayout.x - width - Theme.pillGap;
                // If the bar is still loading (rightLayout.x is 0), just center it normally
                if (rightLayout.x <= 0)
                    return preferredX;

                return Math.max(leftBound, Math.min(preferredX, rightBound));
            }
            controlCenterMenuRef: bar.controlCenterMenuRef
        }

        // --- RIGHT SIDE ---
        // Using RowLayout directly with anchors.
        // RowLayout calculates its own width based on children automatically.
        RowLayout {
            id: rightLayout

            anchors.right: parent.right
            anchors.rightMargin: Theme.barMarginRight
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.pillSpacing

            Tray {
                menuRef: trayPopup
            }

            Network {
                id: wifiWidget

                menuRef: wifiLoader
            }

            PowerProfile {
                id: powerProfileWidget

                menuRef: powerProfilePopup
            }

            Resources {
            }

            Volume {
                id: volumeWidget

                menuRef: volumePopup
            }

            Bluetooth {
                id: bluetoothWidget

                menuRef: bluetoothLoader
            }

            Battery {
                id: batteryWidget
            }

            Power {
            }

        }

    }

    // Update your FocusGrab to include the Bluetooth menu
    HyprlandFocusGrab {
        active: wifiLoader.active || bluetoothLoader.active
        windows: {
            let winList = [bar.QsWindow.window];
            if (wifiLoader.item)
                winList.push(wifiLoader.item.QsWindow.window);

            if (bluetoothLoader.item)
                winList.push(bluetoothLoader.item.QsWindow.window);

            return winList;
        }
    }

    Loader {
        id: wifiLoader

        active: false
        source: "Menu/WifiMenu.qml"
        onLoaded: {
            item.anchorItem = wifiWidget;
        }
    }

    Loader {
        id: bluetoothLoader

        active: false
        source: "Menu/BluetoothMenu.qml"
        onLoaded: {
            // Position it relative to the bluetooth widget
            item.anchorItem = bluetoothWidget;
        }
    }

    TrayMenu {
        id: trayPopup
    }

    PowerProfilePopup {
        id: powerProfilePopup

        visible: false
        anchor.window: bar
    }

    VolumeMenu {
        id: volumePopup

        visible: false
        anchor.window: bar
    }

}
