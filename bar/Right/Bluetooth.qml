import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property var menuRef

    implicitHeight: Theme.pillHeight
    implicitWidth: pill.width

    Pill {
        id: pill

        implicitHeight: Theme.pillHeight
        width: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Theme.pillGap

            Text {
                text: BluetoothService.powered ? Theme.btIcon : "󰂲"
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                color: BluetoothService.connected ? Theme.bluetoothColor : (BluetoothService.powered ? Theme.fontColor : Theme.inactiveTextColor)
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            QuickSettingsService.open("bluetooth", root.mapToItem(null, 0, 0, root.width, root.height));
        }
        onExited: QuickSettingsService.startHideTimer();
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                QuickSettingsService.toggle("bluetooth", root.mapToItem(null, 0, 0, root.width, root.height));
        }
    }
}
