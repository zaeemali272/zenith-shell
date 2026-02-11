import "../../.."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    // ===== API =====
    property string label: ""
    property string icon: ""
    property int value: 0
    property var onChange: null
    property color color: Theme.activeTextColor // This controls text & icons
    property color sliderColor: Theme.accentColor // This will control the slider track

    spacing: 6

    RowLayout {
        spacing: 6

        Text {
            text: root.icon
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
            color: root.color
        }

        Text {
            text: root.label
            Layout.fillWidth: true
            color: root.color
            font.pixelSize: Theme.fontSize
        }

        Text {
            text: root.value + "%"
            color: root.color
            font.pixelSize: Theme.fontSize
        }

    }

    Slider {
        id: control

        Layout.fillWidth: true
        from: 0
        to: 100
        value: root.value
        onMoved: {
            const v = Math.round(value);
            root.value = v;
            if (root.onChange)
                root.onChange(v);

        }

        // 1. Change the Handle (The Knob)
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 14
            implicitHeight: 14
            radius: 7
            color: root.sliderColor
            border.color: "#ffffff"
            border.width: 1
        }

        // 2. Change the Background (The Bar/Track)
        background: Rectangle {
            x: control.leftPadding
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 4
            width: control.availableWidth
            height: implicitHeight
            radius: 2
            color: "#333333" // Inactive track color

            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                color: root.sliderColor // Active (filled) track color
                radius: 2
            }

        }

    }

}
