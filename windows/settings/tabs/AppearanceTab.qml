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
        label: "Theme Studio"
        description: "Launch the theme designer to craft custom palettes, glassmorphism, and accent tones"
        Rectangle {
            width: Shell.Theme.scaled(130)
            height: Shell.Theme.scaled(32)
            radius: height / 2
            color: Shell.Theme.accentColor
            scale: studioMouse.pressed ? 0.94 : 1.0
            Behavior on scale { NumberAnimation { duration: Shell.Theme.animInstant; easing.type: Easing.OutCubic } }

            RowLayout {
                anchors.centerIn: parent
                spacing: Shell.Theme.scaled(6)

                Text {
                    text: "󰏘"
                    font.family: Shell.Theme.iconFont
                    font.pixelSize: Shell.Theme.scaled(13)
                    color: Shell.Colors.on_primary
                }
                Text {
                    text: "Open Studio"
                    font.pixelSize: Shell.Theme.scaled(11)
                    font.weight: Font.Bold
                    color: Shell.Colors.on_primary
                }
            }

            MouseArea {
                id: studioMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    win.visible = false;
                    CenterState.open("Theme");
                }
            }
        }
    }

    SettingRow {
        label: "Themed Status Bar Icons"
        description: "Tint all status bar glyphs automatically with the current theme accent color"
        MaterialSwitch {
            checked: AppearanceSettings.themedBarIcons
            onClicked: AppearanceSettings.themedBarIcons = checked
            onToggled: AppearanceSettings.themedBarIcons = checked
        }
    }

    SettingRow {
        visible: !AppearanceSettings.themedBarIcons
        label: "Permanent Icons Color"
        description: "Fixed hex color used for status bar glyphs when theme tinting is disabled"
        RowLayout {
            spacing: Shell.Theme.scaled(8)

            Rectangle {
                width: Shell.Theme.scaled(26)
                height: Shell.Theme.scaled(26)
                radius: height / 2
                color: AppearanceSettings.barIconsColor
                border.color: Shell.Theme.glassBorder
                border.width: 1
            }

            Repeater {
                model: ["#ffffff", "#74c7ec", "#a6e3a1", "#fab387", "#f38ba8", "#f9e2af"]
                delegate: Rectangle {
                    width: Shell.Theme.scaled(20)
                    height: Shell.Theme.scaled(20)
                    radius: height / 2
                    color: modelData
                    border.color: AppearanceSettings.barIconsColor.toLowerCase() === modelData.toLowerCase() ? Shell.Theme.accentColor : Shell.Theme.glassBorder
                    border.width: AppearanceSettings.barIconsColor.toLowerCase() === modelData.toLowerCase() ? 2 : 1
                    scale: dotMouse.pressed ? 0.9 : 1.0

                    MouseArea {
                        id: dotMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AppearanceSettings.barIconsColor = modelData
                    }
                }
            }

            TextInputBox {
                width: Shell.Theme.scaled(90)
                text: AppearanceSettings.barIconsColor
                onAccepted: (val) => {
                    if (val && val.trim() !== "") {
                        AppearanceSettings.barIconsColor = val.trim();
                    }
                }
            }
        }
    }

    SettingRow {
        label: "Themed Cat Glyph"
        description: "Match the animated walking cat mascot with the active accent color"
        MaterialSwitch {
            checked: AppearanceSettings.themeCatColor
            onClicked: AppearanceSettings.themeCatColor = checked
            onToggled: AppearanceSettings.themeCatColor = checked
        }
    }

    SettingRow {
        visible: !AppearanceSettings.themeCatColor
        label: "Permanent Cat Color"
        description: "Fixed hex color applied to the cat mascot when theme tinting is disabled"
        RowLayout {
            spacing: Shell.Theme.scaled(8)

            Rectangle {
                width: Shell.Theme.scaled(26)
                height: Shell.Theme.scaled(26)
                radius: height / 2
                color: AppearanceSettings.catPermanentColor
                border.color: Shell.Theme.glassBorder
                border.width: 1
            }

            Repeater {
                model: ["#ffffff", "#74c7ec", "#a6e3a1", "#fab387", "#f38ba8", "#f9e2af"]
                delegate: Rectangle {
                    width: Shell.Theme.scaled(20)
                    height: Shell.Theme.scaled(20)
                    radius: height / 2
                    color: modelData
                    border.color: AppearanceSettings.catPermanentColor.toLowerCase() === modelData.toLowerCase() ? Shell.Theme.accentColor : Shell.Theme.glassBorder
                    border.width: AppearanceSettings.catPermanentColor.toLowerCase() === modelData.toLowerCase() ? 2 : 1
                    scale: catDotMouse.pressed ? 0.9 : 1.0

                    MouseArea {
                        id: catDotMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AppearanceSettings.catPermanentColor = modelData
                    }
                }
            }

            TextInputBox {
                width: Shell.Theme.scaled(90)
                text: AppearanceSettings.catPermanentColor
                onAccepted: (val) => {
                    if (val && val.trim() !== "") {
                        AppearanceSettings.catPermanentColor = val.trim();
                    }
                }
            }
        }
    }

    SettingRow {
        label: "Menu Opacity"
        description: "Background opacity and blur translucency of popups and control menus"
        MaterialSlider {
            from: 0.1; to: 1.0; stepSize: 0.05
            value: AppearanceSettings.menuOpacity
            onMoved: AppearanceSettings.menuOpacity = value
            onValueChanged: if (pressed) AppearanceSettings.menuOpacity = value
        }
    }

    SettingRow {
        label: "Tooltip Opacity"
        description: "Alpha transparency of informative tooltips when hovering controls"
        MaterialSlider {
            from: 0.1; to: 1.0; stepSize: 0.05
            value: AppearanceSettings.tooltipOpacity
            onMoved: AppearanceSettings.tooltipOpacity = value
            onValueChanged: if (pressed) AppearanceSettings.tooltipOpacity = value
        }
    }

    SettingRow {
        label: "Settings Opacity"
        description: "Translucency factor of the Zenith settings dialogue window"
        MaterialSlider {
            from: 0.1; to: 1.0; stepSize: 0.05
            value: AppearanceSettings.settingsOpacity
            onMoved: AppearanceSettings.settingsOpacity = value
            onValueChanged: if (pressed) AppearanceSettings.settingsOpacity = value
        }
    }
    
    SettingRow {
        label: "Glass Blur"
        description: "Kawase blur radius strength applied to translucent shell surfaces"
        NumberInput {
            from: 0; to: 1000; step: 10
            value: AppearanceSettings.glassBlur
            onValueModified: AppearanceSettings.glassBlur = value
        }
    }

    Item { height: Shell.Theme.scaled(20) }

    SettingRow {
        label: "Font Size"
        description: "Base text point size scaled throughout shell widgets and menus"
        NumberInput {
            from: 8; to: 32; step: 1
            value: AppearanceSettings.fontSize
            onValueModified: AppearanceSettings.fontSize = value
        }
    }
    
    SettingRow {
        label: "Icon Size"
        description: "Standard glyph and symbol icon dimension in pixels"
        NumberInput {
            from: 8; to: 64; step: 2
            value: AppearanceSettings.iconSize
            onValueModified: AppearanceSettings.iconSize = value
        }
    }

    SettingRow {
        label: "Font Family"
        description: "Primary system typeface name used for UI labels"
        TextInputBox {
            text: AppearanceSettings.fontFamily
            onAccepted: AppearanceSettings.fontFamily = text
        }
    }

    SettingRow {
        label: "Icon Font"
        description: "Nerd Font family utilized for system icons and indicators"
        TextInputBox {
            text: AppearanceSettings.iconFont
            onAccepted: AppearanceSettings.iconFont = text
        }
    }

    Item { Layout.fillHeight: true }
}
