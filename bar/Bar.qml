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

        width: parent.width
        height: parent.height
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
            anchors.left: parent.left
            anchors.leftMargin: Theme.barMarginLeft
            anchors.verticalCenter: parent.verticalCenter
        }

        // --- PERFECT CENTER ---
        Center {
            anchors.centerIn: parent
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

            Resources {
            }

            Volume {
                id: volumeWidget

                menuRef: volumePopup
            }

            Battery {
            }

            Power {
            }

        }

    }

    HyprlandFocusGrab {
        active: wifiLoader.active
        // Including 'bar.QsWindow.window' is what prevents the 'cleared' error
        // when clicking the icon that triggers the menu.
        windows: wifiLoader.item ? [wifiLoader.item.QsWindow.window, bar.QsWindow.window] : [bar.QsWindow.window]
    }

    Loader {
        id: wifiLoader

        active: false
        source: "Menu/WifiMenu.qml"
        onLoaded: {
            item.anchorItem = wifiWidget;
        }
    }

    TrayMenu {
        id: trayPopup
    }

    VolumeMenu {
        id: volumePopup

        visible: false
        anchor.window: bar
    }

}
