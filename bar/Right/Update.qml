import ".."
import "../.."
import "../../services"
import "../Menu"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property int totalUpdates: (updateMenu.zenithData?.updates || 0) + (updateMenu.shellData?.updates || 0)
    
    visible: totalUpdates > 0
    implicitHeight: Theme.pillHeight
    implicitWidth: pill.width

    UpdateMenu {
        id: updateMenu
    }

    Pill {
        id: pill
        anchors.fill: parent
        z: 999
        icon: "󰚰"
        text: root.totalUpdates.toString()
        textColor: Theme.accentColor
        
        implicitWidth: pillRow.implicitWidth + Theme.pillPadding + Theme.extraPillPadding

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                if (!updateMenu.visible) {
                    updateMenu.openAt(pill);
                } else {
                    updateMenu.visible = false;
                }
            } else if (mouse.button === Qt.RightButton) {
                // Trigger an update check
            }
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: Theme.pillGap

            Text {
                text: pill.icon
                color: pill.textColor
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: pill.text
                color: pill.textColor
                font.pixelSize: Theme.fontSize
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
