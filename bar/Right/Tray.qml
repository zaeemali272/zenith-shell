// bar/Right/Tray.qml
import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

Rectangle {
    id: trayContainer

    property var menuRef

    implicitHeight: Theme.pillHeight
    implicitWidth: trayRow.implicitWidth + (Theme.pillPadding * 2)
    color: Theme.pillColor
    radius: Theme.pillRadius
    Layout.alignment: Qt.AlignVCenter

    RowLayout {
        id: trayRow

        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: SystemTray.items

            delegate: TrayItem {
                item: modelData
                menuRef: trayContainer.menuRef
            }
        }

        Text {
            text: "!"
            visible: SystemTray.items.length === 0
            color: "white"
            font.pixelSize: Theme.fontSize
        }
    }
}
