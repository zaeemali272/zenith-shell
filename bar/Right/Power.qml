import ".."
import "../.."
import "../../services"
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    implicitHeight: Theme.pillHeight
    implicitWidth: pill.implicitWidth
    
    Pill {
        id: pill

        icon: " "
        text: ""
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                QuickSettingsService.toggle("power", root.mapToItem(null, 0, 0, root.width, root.height));
            else if (mouse.button === Qt.RightButton)
                powerExec.running = true;
        }

        Item {
            width: Theme.implicitWidth
            height: Theme.pillHeight
            anchors.centerIn: parent

            Text {
                anchors.centerIn: parent
                text: pill.icon
                color: pill.textColor
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                lineHeight: 1
                lineHeightMode: Text.FixedHeight
            }

        }
    }

    Process {
        id: powerExec

        command: ["sh", "-c", "pkill wlogout || wlogout -m 300px -p layer-shell"]
    }
}
