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
            text: "Appearance"
            font.pixelSize: Shell.Theme.scaled(20)
            font.weight: Font.Bold
            color: Shell.Theme.text
        }
    }
    
    SettingRow {
        label: "Menu Opacity"
        MaterialSlider {
            from: 0; to: 1; stepSize: 0.05
            value: AppearanceSettings.menuOpacity
            onMoved: AppearanceSettings.menuOpacity = value
        }
    }

    SettingRow {
        label: "Settings Opacity"
        MaterialSlider {
            from: 0; to: 1; stepSize: 0.05
            value: AppearanceSettings.settingsOpacity
            onMoved: AppearanceSettings.settingsOpacity = value
        }
    }
    
    SettingRow {
        label: "Glass Blur"
        NumberInput {
            from: 0; to: 1000; step: 10
            value: AppearanceSettings.glassBlur
            onValueModified: AppearanceSettings.glassBlur = value
        }
    }

    Item { height: Shell.Theme.scaled(20) }

    SettingRow {
        label: "Font Size"
        NumberInput {
            from: 8; to: 32; step: 1
            value: AppearanceSettings.fontSize
            onValueModified: AppearanceSettings.fontSize = value
        }
    }
    
    SettingRow {
        label: "Icon Size"
        NumberInput {
            from: 8; to: 64; step: 2
            value: AppearanceSettings.iconSize
            onValueModified: AppearanceSettings.iconSize = value
        }
    }

    SettingRow {
        label: "Font Family"
        TextInputBox {
            text: AppearanceSettings.iconFont
            onAccepted: AppearanceSettings.iconFont = text
        }
    }

    Item { Layout.fillHeight: true }
}
