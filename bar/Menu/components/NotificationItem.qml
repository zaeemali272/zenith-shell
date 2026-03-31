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

    visible: !!notification
    // Calculate height based on content
    implicitHeight: layout.implicitHeight + 24
    Layout.fillWidth: true
    color: "#121212"
    radius: 12
    border.color: "#1a1a1a"
    border.width: 1
    clip: true

    // --- ANIMATIONS ---
    opacity: 0
    scale: 0.8
    transform: Translate { id: trans; x: 50 }

    Component.onCompleted: {
        appearAnim.start()
    }

    ParallelAnimation {
        id: appearAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; to: 1.0; duration: 500; easing.type: Easing.OutBack }
        NumberAnimation { target: trans; property: "x"; to: 0; duration: 600; easing.type: Easing.OutExpo }
    }

    // Add smooth animation for expansion
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    // --- ICON RESOLUTION LOGIC ---
    property var iconCandidates: []
    property int currentCandidateIndex: -1

    function tryNextIcon() {
        currentCandidateIndex++;
        if (currentCandidateIndex < iconCandidates.length) {
            let nextSource = iconCandidates[currentCandidateIndex];
            if (nextSource && nextSource !== "") {
                iconImg.source = nextSource;
            } else {
                tryNextIcon();
            }
        } else {
            iconImg.source = "image://icon/dialog-information";
        }
    }

    function updateCandidates() {
        if (!notification) return;
        
        let raw = notification.rawIcon || "";
        let app = (notification.appName || "").toLowerCase().replace(/\s+/g, '-');
        let summary = (notification.summary || "").toLowerCase().replace(/\s+/g, '-');
        
        let names = [];
        if (raw !== "") names.push(raw);
        if (app !== "") names.push(app);
        if (summary !== "") names.push(summary);
        
        // Remove duplicates
        names = names.filter((v, i, a) => a.indexOf(v) === i);

        let bases = [
            "/usr/share/icons/OneUI/24/apps/",
            "/usr/share/icons/OneUI/24/actions/",
            "/usr/share/icons/OneUI/24/panel/",
            "/usr/share/icons/OneUI/24/status/",
            "/usr/share/icons/OneUI/24/devices/",
            "/usr/share/icons/OneUI/24/places/",
            "/usr/share/icons/OneUI/scalable/apps/",
            "/usr/share/icons/OneUI/scalable/actions/",
            "/usr/share/icons/OneUI/scalable/status/",
            "/usr/share/icons/OneUI/scalable/devices/",
            "/usr/share/icons/OneUI/scalable/places/",
            "/usr/share/icons/OneUI/symbolic/apps/",
            "/usr/share/icons/OneUI/symbolic/actions/",
            "/usr/share/icons/OneUI/symbolic/status/",
            "/usr/share/icons/OneUI/symbolic/devices/",
            "/usr/share/icons/OneUI/symbolic/places/",
            "/usr/share/icons/Adwaita/24x24/apps/",
            "/usr/share/icons/Adwaita/scalable/apps/",
            "/usr/share/icons/Adwaita/symbolic/ui/",
            "/usr/share/icons/hicolor/48x48/apps/",
            "/usr/share/icons/hicolor/scalable/apps/"
        ];

        let candidates = [];
        // 1. Original hinted icon or path
        if (notification.appIcon && notification.appIcon !== "") {
            candidates.push(notification.appIcon);
        }

        // 2. Generate candidates from names and bases
        for (let name of names) {
            for (let base of bases) {
                candidates.push("file://" + base + name + ".svg");
                candidates.push("file://" + base + name + ".png");
                if (base.includes("symbolic")) {
                    candidates.push("file://" + base + name + "-symbolic.svg");
                }
            }
            candidates.push("image://icon/" + name);
        }

        iconCandidates = candidates;
        currentCandidateIndex = -1;
        tryNextIcon();
    }

    onNotificationChanged: updateCandidates()

    // 1. Background MouseArea for the whole notification (except dismiss button)
    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        anchors.rightMargin: 44 // Ensure it doesn't overlap dismiss button
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        z: 1
        onClicked: {
            if (notification && notification.originalNotif) {
                notification.originalNotif.invokeAction("default");
                notification.originalNotif.dismiss();
                autoDismissTimer.stop();
                NotificationService.removeNotification(notification.id);
            }
        }
    }

    // 2. Main content layout
    RowLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: dismissButton.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 12
        spacing: 12
        z: 2

        // --- APP ICON SECTION ---
        Item {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            Layout.alignment: Qt.AlignVCenter
            
            Rectangle {
                anchors.fill: parent
                color: "#1a1a1a"
                radius: 8
                visible: iconImg.status !== Image.Ready
            }

            Image {
                id: iconImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                
                onStatusChanged: {
                    if (status === Image.Error) {
                        tryNextIcon();
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
                font.pixelSize: 10
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
                elide: mainMouseArea.containsMouse ? Text.ElideNone : Text.ElideRight
                maximumLineCount: mainMouseArea.containsMouse ? 50 : 2
                Layout.fillWidth: true
            }
        }
    }

    // 3. Dismiss button
    Item {
        id: dismissButton
        width: 32
        height: 32
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 8
        z: 100

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: dismissMouse.containsMouse ? "#2a2a2a" : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.centerIn: parent
            text: "󰅖"
            // Color gets "darker" (stronger/more contrast) on hover
            color: dismissMouse.containsMouse ? "#f38ba8" : "#6e738d"
            font.pixelSize: 18
            visible: !!notification
        }

        MouseArea {
            id: dismissMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (notification) {
                    if (notification.originalNotif)
                        notification.originalNotif.dismiss();
                    autoDismissTimer.stop();
                    NotificationService.removeNotification(notification.id);
                }
            }
        }
    }
}
