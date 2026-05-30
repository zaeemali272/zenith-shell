import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import "../../../" as Shell
import "../components"

ColumnLayout {
    spacing: 15
    Layout.margins: 20

    property string ppPath: Quickshell.env("HOME") + "/.config/quickshell/profilePicture"

    Text { text: "User Settings"; font.pixelSize: 18; font.bold: true; color: "white"; Layout.topMargin: 10 }

    Rectangle {
        Layout.fillWidth: true
        height: Shell.Theme.scaled(80)
        color: Qt.rgba(0,0,0,0.2)
        radius: Shell.Theme.scaled(24)
        border.color: Shell.Theme.glassBorder

        RowLayout {
            anchors.fill: parent
            anchors.margins: Shell.Theme.scaled(20)
            spacing: Shell.Theme.scaled(20)

            Text { text: ""; font.family: Shell.Theme.iconFont; font.pixelSize: Shell.Theme.scaled(30); color: Shell.Theme.blue }

            ColumnLayout {
                spacing: 5
                Text { text: "Zaeem"; color: Shell.Theme.text; font.pixelSize: Shell.Theme.scaled(20); font.bold: true }
                Text { text: "Lahore, Pakistan"; color: Shell.Theme.subtext1; font.pixelSize: Shell.Theme.scaled(14) }
            }
        }
    }

    SettingRow {
        label: "Username"
        TextInputBox { text: "Zaeem"; Layout.preferredWidth: Shell.Theme.scaled(200) }
    }

    SettingRow {
        label: "Location"
        TextInputBox { text: "Lahore, Pakistan"; Layout.preferredWidth: Shell.Theme.scaled(200) }
    }

    Item { Layout.fillHeight: true }
}
