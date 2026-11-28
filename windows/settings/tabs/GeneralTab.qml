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
        label: "Fullscreen Notifications"
        description: "Show notification popups while a window is fullscreen"
        MaterialSwitch {
            checked: NotificationSettings.fullscreenNotification
            onClicked: NotificationSettings.fullscreenNotification = checked
            onToggled: NotificationSettings.fullscreenNotification = checked
        }
    }

    SettingRow {
        label: "Fullscreen OSD"
        description: "Show volume and brightness OSD popups while a window is fullscreen"
        MaterialSwitch {
            checked: NotificationSettings.fullscreenOSD
            onClicked: NotificationSettings.fullscreenOSD = checked
            onToggled: NotificationSettings.fullscreenOSD = checked
        }
    }

    // Calendar & Location Section Header
    Rectangle {
        Layout.fillWidth: true
        height: Shell.Theme.scaled(48)
        color: "transparent"
        Text {
            anchors.left: parent.left
            anchors.leftMargin: Shell.Theme.scaled(20)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Shell.Theme.scaled(6)
            text: "Calendar & Location"
            font.pixelSize: Shell.Theme.scaled(16)
            font.weight: Font.Bold
            color: Shell.Theme.text
        }
    }

    SettingRow {
        label: "Auto-Detect Location"
        description: "Automatically detect your country from timezone/locale for calendar holidays"
        MaterialSwitch {
            checked: GeneralSettings.autoDetectCountry
            onClicked: GeneralSettings.autoDetectCountry = checked
            onToggled: GeneralSettings.autoDetectCountry = checked
        }
    }

    SettingRow {
        visible: !GeneralSettings.autoDetectCountry
        label: "Country Code"
        description: "Two-letter ISO country code (e.g. PK, US, GB, DE, JP) used for holiday lookups"
        TextInputBox {
            text: GeneralSettings.customCountryCode
            onAccepted: (val) => {
                let cleaned = val.trim().toUpperCase().slice(0, 2);
                if (cleaned.length > 0) GeneralSettings.customCountryCode = cleaned;
            }
        }
    }

    SettingRow {
        label: "Show Official Holidays"
        description: "Display national and religious holidays in the calendar grid and agenda"
        MaterialSwitch {
            checked: GeneralSettings.showHolidays
            onClicked: GeneralSettings.showHolidays = checked
            onToggled: GeneralSettings.showHolidays = checked
        }
    }

    SettingRow {
        label: "First Day of Week"
        description: "Choose whether the calendar week starts on Sunday, Monday, or Saturday"
        SelectionBox {
            model: ["Sunday", "Monday", "Saturday"]
            currentIndex: GeneralSettings.firstDayOfWeek === 1 ? 1 : (GeneralSettings.firstDayOfWeek === 6 ? 2 : 0)
            onActivated: (idx) => {
                GeneralSettings.firstDayOfWeek = idx === 1 ? 1 : (idx === 2 ? 6 : 0);
            }
        }
    }

    SettingRow {
        label: "Show Week Numbers"
        description: "Display ISO week numbers along the left side of the calendar grid"
        MaterialSwitch {
            checked: GeneralSettings.showWeekNumbers
            onClicked: GeneralSettings.showWeekNumbers = checked
            onToggled: GeneralSettings.showWeekNumbers = checked
        }
    }

    Item { Layout.fillHeight: true }
}
