import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../../services"

Rectangle {
    id: root

    property var notification: null

    visible: !!notification
    implicitHeight: layout.implicitHeight + 20
    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    color: "#121212"
    radius: 12
    border.color: "#1a1a1a"
    border.width: 1

    // Main interaction: Click to redirect to the app
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (notification && notification.originalNotif) {
                console.log("Redirecting to app: " + notification.appName);
                notification.originalNotif.invokeAction("default");
                notification.originalNotif.dismiss();
                // Call the singleton directly by its filename-based name
                NotificationService.removeNotification(notification.id);
            }
        }
    }

    RowLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 12

        // App Icon
        Rectangle {
            width: 50; height: 50; radius: 10
            color: 'transparent'
            visible: notification && notification.appIcon !== ""

            Image {
                anchors.fill: parent
                source: (notification && notification.appIcon) ? notification.appIcon : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                onStatusChanged: if (status === Image.Error) source = "image://icon/dialog-information"
            }
        }

        // Text Content
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                text: notification ? (notification.appName || "SYSTEM") : ""
                color: "#6e738d"; font.pixelSize: 9; font.bold: true; font.capitalization: Font.AllUppercase
                Layout.fillWidth: true
            }

            Label {
                text: notification ? (notification.summary || "Notification") : ""
                color: "white"; font.bold: true; font.pixelSize: 13
                elide: Text.ElideRight; Layout.fillWidth: true
            }

            Label {
                text: notification ? (notification.body || "") : ""
                color: "#cad3f5"; font.pixelSize: 11; wrapMode: Text.WordWrap
                elide: Text.ElideRight; maximumLineCount: 2; Layout.fillWidth: true
            }
        }

        // Dismiss Button
        Text {
            z: 10 // Higher depth so it catches the click first
            text: "󰅖"
            color: dismissMouse.containsMouse ? "#f38ba8" : "#ee99a0"
            font.pixelSize: 18
            visible: !!notification

            MouseArea {
                id: dismissMouse
                anchors.fill: parent
                anchors.margins: -10
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                // Inside Dismiss Button MouseArea
                onClicked: {
                    if (notification) {
                        console.log("Removing notification: " + notification.id);
                        
                        // 1. Tell the system it's dismissed
                        if (notification.originalNotif) {
                            notification.originalNotif.dismiss();
                        }
                        
                        // 2. Remove it from your historyModel
                        // The import above makes this name visible now
                        NotificationService.removeNotification(notification.id);
                    }
                }
            }
        }
    }
}