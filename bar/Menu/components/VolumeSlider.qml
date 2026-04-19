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
    property color sliderColor: "#89b4fa" // Default to a nice blue

    spacing: Theme.scaled(8)
    Layout.fillWidth: true

    // --- Header Section ---
    RowLayout {
        spacing: Theme.scaled(12)
        Layout.fillWidth: true

        Rectangle {
            width: Theme.scaled(38); height: Theme.scaled(38); radius: Theme.scaled(12)
            color: "#181825"; border.color: "#313244"
            Text {
                anchors.centerIn: parent
                text: root.icon; font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(18); color: root.sliderColor
            }
        }

        ColumnLayout {
            spacing: 0; Layout.fillWidth: true
            Text { 
                text: root.label.toUpperCase()
                color: "#89b4fa"; font.weight: Font.Black
                font.pixelSize: Theme.scaled(11); font.letterSpacing: 1.5 
            }
            Text { 
                text: root.value + "%"
                color: "white"; font.family: "JetBrains Mono"
                font.weight: Font.Bold; font.pixelSize: Theme.scaled(13) 
            }
        }
    }

    // --- Slider Section ---
    Slider {
        id: control
        Layout.fillWidth: true
        from: 0; to: 100
        value: root.value
        
        // Reset all paddings for pixel-perfect alignment
        padding: 0
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0

        readonly property real handleWidth: Theme.scaled(24)

        onMoved: {
            const v = Math.round(value);
            if (root.onChange) root.onChange(v);
        }

        // --- THE HANDLE ---
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + (control.availableHeight - height) / 2
            
            implicitWidth: control.handleWidth
            implicitHeight: control.handleWidth
            radius: width / 2
            color: "white"
            border.color: root.sliderColor
            border.width: Theme.scaled(3)
            
            // Interaction feedback
            scale: control.pressed ? 1.15 : (control.hovered ? 1.05 : 1.0)
            
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            
            // Subtle inner dot for that "pro" look
            Rectangle {
                anchors.centerIn: parent
                width: Theme.scaled(6); height: Theme.scaled(6); radius: Theme.scaled(3)
                color: root.sliderColor; opacity: control.pressed ? 1 : 0.5
            }
        }

        // --- THE TRACK ---
        background: Rectangle {
            id: bg
            x: control.leftPadding + control.handleWidth / 2
            y: control.topPadding + (control.availableHeight - height) / 2
            width: control.availableWidth - control.handleWidth
            height: Theme.scaled(12) 
            radius: Theme.scaled(6)
            color: "#181825"
            border.color: "#313244"; border.width: 1

            // The Progress Fill
            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                color: root.sliderColor
                radius: Theme.scaled(6)

                // Smoothly clip the right side of the fill to match handle center
                layer.enabled: true
            }
        }
    }
}