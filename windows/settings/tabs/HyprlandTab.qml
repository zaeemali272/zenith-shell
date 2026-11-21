import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Settings"
import "../components"
import "../../../" as Shell

ColumnLayout {
    spacing: 0
    
    Text { text: "Hyprland Overrides (Real-time)"; font.pixelSize: 18; font.bold: true; color: "white"; Layout.margins: 20; Layout.topMargin: 20 }
    
    SettingRow {
        label: "Gaps In"
        description: "Pixel separation gap between adjacent tiled Hyprland windows"
        NumberInput {
            from: 0; to: 50; step: 1
            value: HyprlandSettings.gapsIn
            onValueModified: HyprlandSettings.gapsIn = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }
    
    SettingRow {
        label: "Gaps Out"
        description: "Outer perimeter gap between tiled windows and the screen edges"
        NumberInput {
            from: 0; to: 100; step: 2
            value: HyprlandSettings.gapsOut
            onValueModified: HyprlandSettings.gapsOut = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    SettingRow {
        label: "Rounding"
        description: "Window corner rounding radius applied across all Hyprland client surfaces"
        NumberInput {
            from: 0; to: 30; step: 1
            value: HyprlandSettings.rounding
            onValueModified: HyprlandSettings.rounding = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    SettingRow {
        label: "Border Size"
        description: "Pixel border thickness rendered around active and inactive windows"
        NumberInput {
            from: 0; to: 10; step: 1
            value: HyprlandSettings.borderSize
            onValueModified: HyprlandSettings.borderSize = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    SettingRow {
        label: "Shadow Range"
        description: "Drop shadow blur radius cast behind floating application windows"
        NumberInput {
            from: 0; to: 100; step: 2
            value: HyprlandSettings.shadowRange
            onValueModified: HyprlandSettings.shadowRange = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    SettingRow {
        label: "Bar Margins"
        description: "Reserved edge padding for the status bar layer in Hyprland"
        NumberInput {
            from: 0; to: 50; step: 1
            value: HyprlandSettings.barMargins
            onValueModified: HyprlandSettings.barMargins = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    Item { Layout.fillHeight: true }
}
