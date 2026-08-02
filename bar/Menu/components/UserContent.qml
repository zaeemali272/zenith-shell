import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import "../../../" as Shell
import "../../../services" as Services

Rectangle {
    id: root
    color: "transparent"

    property string ppPath: Services.UserService.ppPath
    property string pathFile: Quickshell.env("HOME") + "/.config/quickshell/profilePicturePath"
    property string savedPath: ""
    property string defaultPp: "../../assets/cat_f0.png"

    Connections {
        target: Services.UserService
        function onProfilePictureChanged() {
            ppImage.source = "";
            ppImage.source = "file://" + root.ppPath + "?" + Date.now();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Shell.Theme.scaled(20)

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Shell.Theme.scaled(10)
            Text { text: ""; font.family: Shell.Theme.iconFont; color: Shell.Theme.blue; font.pixelSize: Shell.Theme.scaled(16) }
            Text { text: "USER PROFILE"; color: Shell.Theme.text; font.pixelSize: Shell.Theme.scaled(14); font.weight: Font.Black }
        }

        // Profile Card
        Rectangle {
            Layout.fillWidth: true
            height: Shell.Theme.scaled(150)
            color: Qt.rgba(0,0,0,0.2)
            radius: Shell.Theme.scaled(24)
            border.color: Shell.Theme.glassBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: Shell.Theme.scaled(20)
                spacing: Shell.Theme.scaled(20)

                Rectangle {
                    width: Shell.Theme.scaled(100); height: Shell.Theme.scaled(100); radius: Shell.Theme.scaled(50)
                    color: Shell.Theme.surface1
                    clip: true
                    
                    Image {
                        id: ppImage
                        anchors.fill: parent
                        source: "file://" + root.ppPath
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
                        text: "󰄛"
                        font.pixelSize: Shell.Theme.scaled(40)
                        color: Shell.Theme.blue
                        visible: true
                    }
                    
                    Rectangle {
                        id: hoverOverlay
                        anchors.fill: parent; color: Qt.rgba(0,0,0,0.5); opacity: 0; z: 10
                        Text { 
                            anchors.centerIn: parent; text: "󰒓"; color: "white"; 
                            font.family: Shell.Theme.iconFont; font.pixelSize: 24 
                        }
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                    MouseArea { 
                        id: mouse; anchors.fill: parent; hoverEnabled: true; z: 11
                        onEntered: hoverOverlay.opacity = 1
                        onExited: hoverOverlay.opacity = 0
                        onClicked: Services.SettingsService.toggle(7)
                    }
                }

                readonly property string username: Services.UserService.username
                readonly property string location: Services.UserService.location

                ColumnLayout {
                    spacing: 5
                    Text { text: "Welcome, " + (Services.UserService.username || "User"); color: Shell.Theme.text; font.pixelSize: Shell.Theme.scaled(20); font.bold: true }
                    RowLayout {
                        spacing: 5
                        Text { id: locText; text: "Living in: " + (Services.UserService.location || "Unknown"); color: Shell.Theme.subtext1; font.pixelSize: Shell.Theme.scaled(14) }
                        Text { 
                            text: "(wrong? click here)"; color: Shell.Theme.blue; font.pixelSize: Shell.Theme.scaled(10); font.underline: true 
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Services.SettingsService.toggle(7)
                            }
                        }
                    }
                }
            }
        }
    }
}
