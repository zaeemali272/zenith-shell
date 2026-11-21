import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Settings"
import "../components"
import "../../../" as Shell

ColumnLayout {
    spacing: 0
    
    Text { text: "Media Behavior"; font.pixelSize: 18; font.bold: true; color: "white"; Layout.margins: 20; Layout.topMargin: 20 }
    
    SettingRow {
        label: "Truncate Track Title"
        description: "Ellipsize long music or podcast titles to maintain compact bar proportions"
        MaterialSwitch {
            checked: MediaSettings.truncateTrackTitle
            onClicked: MediaSettings.truncateTrackTitle = checked
            onToggled: MediaSettings.truncateTrackTitle = checked
        }
    }
    
    SettingRow {
        label: "Max Title Length"
        description: "Maximum character length threshold before track title is truncated"
        NumberInput {
            from: 10; to: 200; step: 5
            value: MediaSettings.maxTrackTitleLength
            onValueModified: MediaSettings.maxTrackTitleLength = value
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    SettingRow {
        label: "Auto Focus Player"
        description: "Automatically switch active media controls to whatever player began playback"
        MaterialSwitch {
            checked: MediaSettings.autoManageMediaFocus
            onClicked: MediaSettings.autoManageMediaFocus = checked
            onToggled: MediaSettings.autoManageMediaFocus = checked
        }
    }

    SettingRow {
        label: "Bar Margins"
        description: "Reserved margin spacing surrounding the center media and weather pill"
        NumberInput {
            from: 0; to: 50; step: 1
            value: MediaSettings.barMargins
            onValueModified: {
                MediaSettings.barMargins = value;
                BarSettings.marginLeft = value;
                BarSettings.marginRight = value;
            }
            Layout.preferredWidth: Shell.Theme.scaled(150)
        }
    }

    Item { Layout.fillHeight: true }
}
