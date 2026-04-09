import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    property var menuRef: null
    readonly property string currentProfile: PowerProfileService.currentProfile

    implicitHeight: Theme.pillHeight
    implicitWidth: pill.implicitWidth

    Pill {
        id: pill

        anchors.fill: parent
        implicitWidth: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                QuickSettingsService.toggle("powerprofile", root.mapToItem(null, 0, 0, root.width, root.height));
        }

        RowLayout {
            id: content

            anchors.centerIn: parent
            spacing: Theme.pillGap

            Text {
                text: {
                    switch (currentProfile) {
                    case "performance":
                        return "󰀦";
                    case "powersave":
                        return "󰍛";
                    case "balanced":
                        return "󰏤";
                    case "turbo":
                        return "󰞃";
                    default:
                        return "󰀄";
                    }
                }
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                color: Theme.activeTextColor
            }

        }

    }

}
