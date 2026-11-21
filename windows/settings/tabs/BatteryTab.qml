import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Settings"
import "../components"
import "../../../" as Shell

ColumnLayout {
    spacing: 0
    
    Text { text: "Power Levels"; font.pixelSize: 18; font.bold: true; color: "white"; Layout.margins: 20; Layout.topMargin: 20 }
    
    SettingRow {
        label: "High Threshold"
        description: "Charge percentage above which battery is considered healthy and normal"
        NumberInput {
            from: 50; to: 100; step: 5
            value: BatterySettings.high
            onValueModified: BatterySettings.high = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }
    
    SettingRow {
        label: "Low Threshold"
        description: "Percentage level at which warning color and low battery notifications fire"
        NumberInput {
            from: 10; to: 40; step: 5
            value: BatterySettings.low
            onValueModified: BatterySettings.low = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    SettingRow {
        label: "Critical Threshold"
        description: "Emergency battery percentage triggering persistent power alerts"
        NumberInput {
            from: 1; to: 15; step: 1
            value: BatterySettings.critical
            onValueModified: BatterySettings.critical = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    SettingRow {
        label: "Bar Margins"
        description: "Spacing padding offset for the battery indicator on the right bar cluster"
        NumberInput {
            from: 0; to: 50; step: 1
            value: BatterySettings.barMargins
            onValueModified: {
                BatterySettings.barMargins = value;
                BarSettings.marginLeft = value;
                BarSettings.marginRight = value;
            }
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    Item { Layout.fillHeight: true }
}
