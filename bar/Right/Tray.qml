// bar/Right/Tray.qml
import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

Rectangle {
    id: trayContainer

    property var menuRef

    implicitHeight: Theme.barHeight || 30
    implicitWidth: trayRow.implicitWidth + 20
    color: Theme.pillColor
    radius: Theme.pillRadius
    Layout.fillHeight: true
    Layout.preferredWidth: implicitWidth

    RowLayout {
        id: trayRow

        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: SystemTray.items

            // Do NOT put any logic here. Just pass modelData to the property.
            delegate: TrayItem {
                item: modelData
                menuRef: trayContainer.menuRef
            }

        }

        Text {
            text: "!"
            visible: SystemTray.items.length === 0
            color: "white"
        }

    }

}
