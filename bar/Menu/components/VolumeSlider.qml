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

    spacing: 8
    Layout.fillWidth: true

    // --- Header Section ---
    RowLayout {
        spacing: 12
        Layout.fillWidth: true

        Rectangle {
            width: 38; height: 38; radius: 12
            color: "#181825"; border.color: "#313244"
            Text {
                anchors.centerIn: parent
                text: root.icon; font.family: Theme.iconFont
                font.pixelSize: 18; color: root.sliderColor
            }
        }

        ColumnLayout {
            spacing: 0; Layout.fillWidth: true
            Text { 
                text: root.label.toUpperCase()
                color: "#89b4fa"; font.weight: Font.Black
                font.pixelSize: 11; font.letterSpacing: 1.5 
            }
            Text { 
                text: root.value + "%"
                color: "white"; font.family: "JetBrains Mono"
                font.weight: Font.Bold; font.pixelSize: 13 
            }
        }
    }

    // --- Slider Section ---
    Slider {
        id: control
        Layout.fillWidth: true
        from: 0; to: 100
        value: root.value
        
        // Reset paddings for pixel-perfect math
        padding: 0
        leftPadding: 0
        rightPadding: 0

        onMoved: {
            const v = Math.round(value);
            if (root.onChange) root.onChange(v);
        }

        // --- THE HANDLE ---
        handle: Rectangle {
            // MATH: Center the handle on the visual position, 
            // then clamp it so it doesn't clip out of the slider bounds.
            x: Math.max(0, Math.min(control.visualPosition * control.availableWidth - width / 2, control.availableWidth - width))
            y: (control.availableHeight - height) / 2
            
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: "white"
            border.color: root.sliderColor
            border.width: 3
            
            // Interaction feedback
            scale: control.pressed ? 1.15 : (control.hovered ? 1.05 : 1.0)
            
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            
            // Subtle inner dot for that "pro" look
            Rectangle {
                anchors.centerIn: parent
                width: 6; height: 6; radius: 3
                color: root.sliderColor; opacity: control.pressed ? 1 : 0.5
            }
        }

        // --- THE TRACK ---
        background: Rectangle {
            id: bg
            x: control.leftPadding
            y: (control.availableHeight - height) / 2
            width: control.availableWidth
            height: 12 
            radius: 6
            color: "#181825"
            border.color: "#313244"; border.width: 1

            // The Progress Fill
            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                color: root.sliderColor
                radius: 6

                // Smoothly clip the right side of the fill to match handle center
                layer.enabled: true
            }
        }
    }
}