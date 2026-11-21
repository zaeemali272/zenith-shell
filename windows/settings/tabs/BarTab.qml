import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Settings"
import "../components"
import "../../../" as Shell

ColumnLayout {
    spacing: 0
    
    // Header
    Rectangle {
        Layout.fillWidth: true
        height: Shell.Theme.scaled(60)
        color: "transparent"
        Text {
            anchors.left: parent.left
            anchors.leftMargin: Shell.Theme.scaled(20)
            anchors.verticalCenter: parent.verticalCenter
            text: "Bar Configuration"
            font.pixelSize: Shell.Theme.scaled(20)
            font.weight: Font.Bold
            color: Shell.Theme.text
        }
    }
    
    SettingRow {
        label: "Height"
        description: "Vertical thickness in pixels of the status bar and floating pill containers"
        NumberInput {
            from: 20; to: 100; step: 2
            value: BarSettings.height
            onValueModified: {
                BarSettings.height = value;
                PillSettings.height = value;
            }
        }
    }
    
    SettingRow {
        label: "Radius"
        description: "Corner curvature radius for the bar surface and capsule pill islands"
        NumberInput {
            from: 0; to: 50; step: 2
            value: BarSettings.radius
            onValueModified: {
                BarSettings.radius = value;
                PillSettings.radius = value;
            }
        }
    }

    SettingRow {
        label: "Opacity"
        description: "Overall translucency and glassmorphism alpha channel of the status bar"
        MaterialSlider {
            from: 0.1; to: 1.0; stepSize: 0.05
            value: BarSettings.opacity
            onMoved: BarSettings.opacity = value
            onValueChanged: if (pressed) BarSettings.opacity = value
        }
    }

    Item { height: Shell.Theme.scaled(20) }

    SettingRow {
        label: "Entry Animation"
        description: "Play smooth slide-in easing animation when the status bar first loads"
        MaterialSwitch {
            checked: BarSettings.entryAnimation
            onClicked: BarSettings.entryAnimation = checked
        }
    }
    
    SettingRow {
        label: "Duration (ms)"
        description: "Milliseconds for status bar enter, exit, and hide transitions"
        NumberInput {
            from: 100; to: 3000; step: 100
            value: BarSettings.animationDuration
            onValueModified: BarSettings.animationDuration = value
        }
    }

    Item { Layout.fillHeight: true }
}
