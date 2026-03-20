import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell.Services.Notifications

Rectangle {
    id: root

    property var notification: null

    visible: !!notification
    // Calculate height based on content
    implicitHeight: layout.implicitHeight + 20
    Layout.fillWidth: true
    color: "#121212"
    radius: 12
    border.color: "#1a1a1a"
    border.width: 1
    clip: true // Prevents children from leaking outside the rounded corners

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (notification && notification.originalNotif) {
                notification.originalNotif.invokeAction("default");
                notification.originalNotif.dismiss();
                NotificationService.removeNotification(notification.id);
            }
        }
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // --- APP ICON SECTION ---
        Item {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            Layout.alignment: Qt.AlignTop // Keeps icon at the top if text is long
            visible: notification && notification.appIcon !== ""

            Image {
                id: iconImg

                anchors.fill: parent
                source: notification.appIcon
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                onStatusChanged: {
                    if (status === Image.Error) {
                        // Check if we already tried the fallback to avoid infinite loops
                        let rawPath = notification.appIcon.replace("image://icon/", "");
                        let adwaitaPath = "image://icon/adwaita/" + rawPath;
                        if (source !== adwaitaPath)
                            source = adwaitaPath;
                        else
                            source = "image://icon/dialog-information";
                    }
                }
            }

        }

        // --- TEXT CONTENT SECTION ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Label {
                text: notification ? (notification.appName || "SYSTEM") : ""
                color: "#6e738d"
                font.pixelSize: 9
                font.bold: true
                font.capitalization: Font.AllUppercase
                Layout.fillWidth: true
            }

            Label {
                text: notification ? (notification.summary || "Notification") : ""
                color: "white"
                font.bold: true
                font.pixelSize: 13
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: notification ? (notification.body || "") : ""
                color: "#cad3f5"
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
                Layout.fillWidth: true
            }

        }

        // --- DISMISS BUTTON ---
        Text {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 2
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
                onClicked: {
                    if (notification) {
                        if (notification.originalNotif)
                            notification.originalNotif.dismiss();

                        NotificationService.removeNotification(notification.id);
                    }
                }
            }

        }

    }

}
