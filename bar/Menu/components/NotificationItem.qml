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
    implicitHeight: layout.implicitHeight + 24 // Added small extra padding for expansion
    Layout.fillWidth: true
    color: "#121212"
    radius: 12
    border.color: "#1a1a1a"
    border.width: 1
    clip: true // Prevents children from leaking outside the rounded corners

    // Add smooth animation for expansion
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }

    }

    MouseArea {
        id: mainMouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
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
        Layout.alignment: Qt.AlignTop

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
                        let iconName = notification.rawIcon || "";
                        if (iconName === "") {
                            // If we don't have a raw name, just fallback to generic
                            source = "image://icon/dialog-information";
                            return;
                        }

                        // Try OneUI Action path (as requested by user)
                        let oneUIAction = "file:///usr/share/icons/OneUI/24/actions/" + iconName + ".svg";
                        if (source.toString() !== oneUIAction) {
                            source = oneUIAction;
                            return;
                        }

                        // Try OneUI Apps path
                        let oneUIApp = "file:///usr/share/icons/OneUI/24/apps/" + iconName + ".svg";
                        if (source.toString() !== oneUIApp) {
                            source = oneUIApp;
                            return;
                        }

                        // Try Adwaita fallback
                        let adwaitaPath = "image://icon/adwaita/" + iconName;
                        if (source.toString() !== adwaitaPath) {
                            source = adwaitaPath;
                        } else {
                            source = "image://icon/dialog-information";
                        }
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
                elide: mainMouseArea.containsMouse ? Text.ElideNone : Text.ElideRight
                wrapMode: mainMouseArea.containsMouse ? Text.WordWrap : Text.NoWrap
                Layout.fillWidth: true
            }

            Label {
                text: notification ? (notification.body || "") : ""
                color: "#cad3f5"
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                // Expansion logic
                elide: mainMouseArea.containsMouse ? Text.ElideNone : Text.ElideRight
                maximumLineCount: mainMouseArea.containsMouse ? 50 : 2
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
