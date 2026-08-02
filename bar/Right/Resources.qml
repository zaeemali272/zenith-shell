import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    readonly property int cpu: ResourceService.cpu
    readonly property int mem: ResourceService.mem
    readonly property int temp: ResourceService.temp

    implicitHeight: Theme.pillHeight
    implicitWidth: pill.width

    Pill {
        id: pill
        implicitHeight: Theme.pillHeight
        width: content.implicitWidth + Theme.pillPadding + Theme.extraPillPadding
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                QuickSettingsService.toggle("powerprofile");
        }

        Behavior on color { ColorAnimation { duration: 300 } }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Theme.pillSpacing

            ResourceItem { icon: ""; value: root.cpu; iconColor: Theme.powerRed }
            ResourceItem { icon: "|  "; value: root.mem; showAbove: 60; iconColor: Theme.powerGreen }
            ResourceItem { icon: "|  "; value: root.temp; suffix: "°C"; showAbove: 85; iconColor: Theme.powerYellow }
        }
    }

    component ResourceItem: RowLayout {
        property string icon
        property int value
        property string suffix: "%"
        property color iconColor
        property int showAbove: -1
        readonly property bool active: showAbove < 0 || value > showAbove

        spacing: Theme.pillGap
        visible: active
        Layout.preferredWidth: active ? -1 : 0
        opacity: active ? 1 : 0

        Text {
            text: icon
            color: iconColor
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: value.toString().padStart(2, '0') + suffix
            color: Theme.fontColor
            font.pixelSize: Theme.fontSize
            Layout.alignment: Qt.AlignVCenter
        }

        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
}
