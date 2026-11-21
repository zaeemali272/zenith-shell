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
            text: "General"
            font.pixelSize: Shell.Theme.scaled(20)
            font.weight: Font.Bold
            color: Shell.Theme.text
        }
    }
    
    SettingRow {
        label: "Enable Media/Weather"
        description: "Display currently playing media tracks and live weather updates in the bar center"
        MaterialSwitch {
            checked: WidgetSettings.enableMedia
            onClicked: WidgetSettings.enableMedia = checked
            onToggled: WidgetSettings.enableMedia = checked
        }
    }
    
    SettingRow {
        label: "Enable Battery"
        description: "Show battery percentage, remaining time, and charge status in the status bar"
        MaterialSwitch {
            checked: WidgetSettings.enableBattery
            onClicked: WidgetSettings.enableBattery = checked
            onToggled: WidgetSettings.enableBattery = checked
        }
    }
    
    SettingRow {
        label: "Enable Resources"
        description: "Monitor live CPU load, RAM allocation, and network transfer speeds"
        MaterialSwitch {
            checked: WidgetSettings.enableResources
            onClicked: WidgetSettings.enableResources = checked
            onToggled: WidgetSettings.enableResources = checked
        }
    }

    Item { Layout.fillHeight: true }
}
