import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import "../../../" as Shell
import "../../../services" as Services
import "../components"

ColumnLayout {
    spacing: 15
    Layout.margins: 20

    property string ppPath: Services.UserService.ppPath

    FileDialog {
        id: profilePicDialog
        title: "Please choose a profile picture"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.svg *.webp)"]
        onAccepted: {
            let src = selectedFile.toString().replace("file://", "");
            if (Qt.platform.os === "linux") {
                src = decodeURIComponent(src);
            }
            Quickshell.Io.copyFile(src, ppPath);
            Services.UserService.updateProfilePicture();
        }
    }

    Connections {
        target: Services.UserService
        function onProfilePictureChanged() {
            ppImage.source = "";
            ppImage.source = "file://" + ppPath + "?" + Date.now();
        }
    }

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

            // Profile Picture Container
            Rectangle {
                width: Shell.Theme.scaled(50)
                height: Shell.Theme.scaled(50)
                radius: width / 2
                color: Shell.Theme.surface1
                clip: true

                Image {
                    id: ppImage
                    anchors.fill: parent
                    source: "file://" + ppPath
                    fillMode: Image.PreserveAspectCrop
                    onStatusChanged: {
                        if (status === Image.Error) {
                            ppImage.visible = false;
                            defaultIcon.visible = true;
                        } else if (status === Image.Ready) {
                            ppImage.visible = true;
                            defaultIcon.visible = false;
                        }
                    }
                }

                Text {
                    id: defaultIcon
                    anchors.centerIn: parent
                    text: ""
                    font.family: Shell.Theme.iconFont
                    font.pixelSize: Shell.Theme.scaled(30)
                    color: Shell.Theme.blue
                }

                Rectangle {
                    id: cameraOverlay
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.5)
                    opacity: 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰄀"
                        font.family: Shell.Theme.iconFont
                        font.pixelSize: Shell.Theme.scaled(20)
                        color: "white"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: cameraOverlay.opacity = 1
                    onExited: cameraOverlay.opacity = 0
                    onClicked: profilePicDialog.open()
                }
            }

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
