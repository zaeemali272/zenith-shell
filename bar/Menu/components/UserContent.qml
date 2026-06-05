import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
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

    Component.onCompleted: {
        // Simple loading from local path
    }

    FolderListModel {
        id: folderModel
        folder: "file:///usr/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
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

                ColumnLayout {
                    spacing: 5
                    Text { text: "Welcome, Zaeem"; color: Shell.Theme.text; font.pixelSize: Shell.Theme.scaled(20); font.bold: true }
                    RowLayout {
                        spacing: 5
                        Text { id: locText; text: "Living in: Lahore, Pakistan"; color: Shell.Theme.subtext1; font.pixelSize: Shell.Theme.scaled(14) }
                        Text { text: "(wrong? click here)"; color: Shell.Theme.blue; font.pixelSize: Shell.Theme.scaled(10); font.underline: true }
                    }
                }
            }
        }

        // Wellbeing Stats
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0,0,0,0.2)
            radius: Shell.Theme.scaled(24)
            border.color: Shell.Theme.glassBorder

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Shell.Theme.scaled(20)
                spacing: Shell.Theme.scaled(15)

                Text { text: "DIGITAL WELLBEING"; color: Shell.Theme.subtext1; font.pixelSize: Shell.Theme.scaled(11); font.weight: Font.Black }
                
                // Stats
                ListView {
                    id: statsList
                    Layout.fillWidth: true; Layout.fillHeight: true
                    model: [] 
                    delegate: RowLayout {
                        width: statsList.width
                        spacing: 10
                        Text { text: modelData.name; color: Shell.Theme.text; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: Math.floor(modelData.time / 60) + " mins"; color: Shell.Theme.blue; font.bold: true }
                    }
                }
            }
        }
    }

    function resetScroll() { statsList.positionViewAtBeginning(); }

    onVisibleChanged: {
        if (visible) refreshData();
    }

    function refreshData() {
        let data = [];
        for (let i = 0; i < folderModel.count; i++) {
            let fn = folderModel.get(i, "fileName");
            let appId = fn.replace(".desktop", "");
            let displayName = appId.charAt(0).toUpperCase() + appId.slice(1);
            let usage = Services.AppUsageService.usageData[appId] || { totalSeconds: 0 };
            data.push({ name: displayName, time: usage.totalSeconds });
        }
        data.sort((a, b) => b.time - a.time);
        statsList.model = data;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: refreshData()
    }
}
