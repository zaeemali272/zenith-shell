import "../../../services"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell.Services.Notifications

Rectangle {
    id: root

    property var notification: null
    readonly property bool hovered: mainMouseArea.containsMouse || dismissMouse.containsMouse

    signal autoDismissed(real id)

    // --- ZENITH THEMEING ---
    color: "#11111b"
    radius: Theme.scaled(14)
    border.color: "#313244"
    border.width: 1
    clip: true

    implicitHeight: layout.implicitHeight + Theme.scaled(24)
    Layout.fillWidth: true

    // --- ANIMATIONS ---
    opacity: 0
    scale: 0.95
    transform: Translate { id: trans; x: 20 }

    Component.onCompleted: appearAnim.start()

    ParallelAnimation {
        id: appearAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; to: 1.0; duration: 400; easing.type: Easing.OutBack }
        NumberAnimation { target: trans; property: "x"; to: 0; duration: 500; easing.type: Easing.OutExpo }
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // --- AUTO DISMISS LOGIC ---
    Timer {
        id: autoDismissTimer
        interval: 8000
        running: !!notification
        repeat: true
        onTriggered: {
            if (!root.hovered) {
                root.autoDismissed(root.notification.id);
                stop();
            }
        }
    }

    // --- ICON RESOLUTION ---
    property var iconCandidates: []
    property int currentCandidateIndex: -1

    function tryNextIcon() {
        currentCandidateIndex++;
        if (currentCandidateIndex < iconCandidates.length) {
            let nextSource = iconCandidates[currentCandidateIndex];
            if (nextSource && nextSource !== "") iconImg.source = nextSource;
            else tryNextIcon();
        } else {
            iconImg.source = "image://icon/dialog-information";
        }
    }

    function updateCandidates() {
        if (!notification) return;
        let raw = notification.rawIcon || "";
        let app = (notification.appName || "").toLowerCase().replace(/\s+/g, '-');
        let summary = (notification.summary || "").toLowerCase().replace(/\s+/g, '-');
        let names = [raw, app, summary].filter((v, i, a) => v !== "" && a.indexOf(v) === i);

        let bases = [
            "/usr/share/icons/OneUI/24/apps/", "/usr/share/icons/OneUI/scalable/apps/",
            "/usr/share/icons/OneUI/symbolic/apps/", "/usr/share/icons/Adwaita/scalable/apps/",
            "/usr/share/icons/hicolor/scalable/apps/"
        ];

        let candidates = [];
        if (notification.appIcon) candidates.push(notification.appIcon);

        for (let name of names) {
            for (let base of bases) {
                candidates.push("file://" + base + name + ".svg");
                candidates.push("file://" + base + name + ".png");
            }
            candidates.push("image://icon/" + name);
        }
        iconCandidates = candidates;
        currentCandidateIndex = -1;
        tryNextIcon();
    }

    onNotificationChanged: updateCandidates()

    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        anchors.rightMargin: 44
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        z: 1
        onClicked: {
            if (notification?.originalNotif) {
                notification.originalNotif.invokeAction("default");
                notification.originalNotif.dismiss();
                NotificationService.removeNotification(notification.id);
            }
        }
    }

// --- Main layout ---
    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.scaled(12)
        spacing: Theme.scaled(8)
        z: 2
        
        // This ensures the entire row of content is centered 
        // vertically if the notification body is short.
        Layout.alignment: Qt.AlignVCenter 

        // Icon Container (Bigger & Centered)
        Rectangle {
            id: iconContainer
            Layout.preferredWidth: Theme.scaled(50)
            Layout.preferredHeight: Theme.scaled(50)
            
            // This centers the icon box vertically within the row
            Layout.alignment: Qt.AlignVCenter 
            
            color: "#181825"
            radius: Theme.scaled(12)
            border.color: "#313244"
            border.width: 1

            Image {
                id: iconImg
                anchors.centerIn: parent
                
                // Use standard width/height to avoid the "read-only" error
                width: parent.width * 0.7 
                height: parent.height * 0.7
                
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                onStatusChanged: if (status === Image.Error) tryNextIcon()
            }
        }

        // Text Section
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter // Centers the text block relative to the icon
            spacing: Theme.scaled(2)

            Label {
                text: notification ? (notification.appName || "SYSTEM").toUpperCase() : ""
                color: "#89b4fa"
                font.pixelSize: Theme.scaled(10)
                font.weight: Font.Black
                font.letterSpacing: 1.5
                Layout.fillWidth: true
            }

            Label {
                text: notification ? (notification.summary || "Notification") : ""
                color: "white"
                font.bold: true
                font.pixelSize: Theme.scaled(13)
                elide: mainMouseArea.containsMouse ? Text.ElideNone : Text.ElideRight
                wrapMode: mainMouseArea.containsMouse ? Text.WordWrap : Text.NoWrap
                Layout.fillWidth: true
            }

            Label {
                text: notification ? (notification.body || "") : ""
                color: "#a6adc8"
                font.pixelSize: Theme.scaled(11)
                wrapMode: Text.WordWrap
                elide: mainMouseArea.containsMouse ? Text.ElideNone : Text.ElideRight
                maximumLineCount: mainMouseArea.containsMouse ? 20 : 2
                Layout.fillWidth: true
            }
        }
    }

    // Dismiss Button
    Item {
        id: dismissButton
        width: Theme.scaled(32); height: Theme.scaled(32)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Theme.scaled(10)
        z: 100

        Rectangle {
            anchors.fill: parent
            radius: Theme.scaled(8)
            color: dismissMouse.containsMouse ? "#313244" : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
            
            Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: dismissMouse.containsMouse ? "#f38ba8" : "#585b70"
                font.pixelSize: Theme.scaled(16)
            }
        }

        MouseArea {
            id: dismissMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (notification) {
                    notification.originalNotif?.dismiss();
                    NotificationService.removeNotification(notification.id);
                }
            }
        }
    }
}