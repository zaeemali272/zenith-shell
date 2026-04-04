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
    property color color: "white" 
    property color sliderColor: Theme.accentColor

    spacing: 8
    Layout.fillWidth: true

    RowLayout {
        spacing: 12
        Layout.fillWidth: true

        Rectangle {
            width: 36; height: 36
            radius: 18
            color: "#2a2a32"
            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.iconFont
                font.pixelSize: 18
                color: root.sliderColor
            }
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Text {
                text: root.label
                color: "white"
                font.bold: true
                font.pixelSize: 13
            }
            Text {
                text: root.value + "%"
                color: "#a6adc8"
                font.pixelSize: 11
            }
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
            // root.value = v; // Avoid binding loop if possible, but for simplicity:
            if (root.onChange)
                root.onChange(v);
        }

        // Modern thick slider (Android 12+ style)
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + (control.availableHeight - height) / 2
            implicitWidth: 20
            implicitHeight: 20
            radius: 10
            color: "white"
            border.color: root.sliderColor
            border.width: 2
            opacity: control.hovered || control.pressed ? 1 : 0
            
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        background: Rectangle {
            x: control.leftPadding
            y: control.topPadding + (control.availableHeight - height) / 2
            implicitWidth: 200
            implicitHeight: 12 // Thicker track
            width: control.availableWidth
            height: implicitHeight
            radius: 6
            color: "#2a2a32"

            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                color: root.sliderColor
                radius: 6
                
                // Add a subtle gradient or shine? Android is flat but let's keep it clean
            }
        }
    }
}
