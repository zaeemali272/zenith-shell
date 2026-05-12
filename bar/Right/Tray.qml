// bar/Right/Tray.qml
import ".."
import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

Pill {
    id: trayContainer

    property var menuRef

    implicitHeight: Theme.pillHeight
    width: trayRow.implicitWidth + (Theme.pillPadding * 2)
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
