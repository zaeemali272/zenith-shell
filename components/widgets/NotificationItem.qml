import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import "../"
import "../../"
import Quickshell.Services.Notifications
import "../"
import "../../"
import "../../services"
import "../../"

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
            iconImg.source = Quickshell.iconPath("dialog-information");
        }
    }

    function updateCandidates() {
        if (!notification) return;
        
        let candidates = [];
        
        // Collect names to try
        let raw = (notification.rawIcon || "").toLowerCase();
        let desktop = (notification.desktopEntry || "").toLowerCase();
        let app = (notification.appName || "").toLowerCase();
        let summary = (notification.summary || "").toLowerCase().replace(/\s+/g, '-');
        let appDashed = app.replace(/\s+/g, '-');
        let appNoSpace = app.replace(/\s+/g, '');
        
        let names = [raw, desktop, appDashed, appNoSpace, app, summary].filter((v, i, a) => v !== "" && a.indexOf(v) === i);

        // System directories to scan
        let bases = [
            "/usr/share/icons/OneUI/symbolic/status/",
            "/usr/share/icons/hicolor/scalable/apps/",
            "/usr/share/icons/hicolor/256x256/apps/",
            "/usr/share/icons/hicolor/128x128/apps/",
            "/usr/share/icons/hicolor/64x64/apps/",
            "/usr/share/icons/hicolor/48x48/apps/",
            "/usr/share/icons/OneUI/scalable/apps/",
            "/usr/share/icons/OneUI/48x48/apps/",
            "/usr/share/icons/Adwaita/scalable/apps/",
            "/usr/share/icons/Adwaita/48x48/apps/",
            "/usr/share/icons/breeze/apps/48/",
            "/usr/share/icons/breeze-dark/apps/48/",
            "/usr/share/icons/hicolor/scalable/status/",
            "/usr/share/icons/hicolor/48x48/status/",
            "/usr/share/icons/OneUI/symbolic/actions/",
            "/usr/share/icons/OneUI/24/actions/"
        ];

        // 1. First try exactly what the service resolved
        if (notification.appIcon) candidates.push(notification.appIcon);
        
        // 2. Try variations of names via Quickshell provider
        for (let name of names) {
            // Only use Quickshell.iconPath for non-path names
            if (!name.includes("/")) {
                candidates.push(Quickshell.iconPath(name));
                if (!name.endsWith("-bin")) {
                    candidates.push(Quickshell.iconPath(name + "-bin"));
                }
            }
        }

        // 3. Try manual file paths
        for (let name of names) {
            if (name.includes("/")) continue; // Skip if it looks like a path
            for (let base of bases) {
                candidates.push("file://" + base + name + ".svg");
                candidates.push("file://" + base + name + ".png");
                
                // Specific battery naming variations for OneUI
                if (name.startsWith("battery-")) {
                    // Try to match both battery-level-080 and battery-080
                    if (name.startsWith("battery-level-")) {
                        let shortName = name.replace("battery-level-", "battery-");
                        let match = name.match(/battery-level-(\d+)/);
                        if (match) {
                            let val = match[1].padStart(3, '0');
                            let suffix = name.split(match[1])[1];
                            candidates.push("file://" + base + "battery-" + val + suffix + ".svg");
                        }
                        candidates.push("file://" + base + shortName + ".svg");
                    } else {
                        // If it's battery-080, try battery-level-80
                        let match = name.match(/battery-(\d+)/);
                        if (match) {
                            let val = parseInt(match[1]);
                            let suffix = name.split(match[1])[1];
                            candidates.push("file://" + base + "battery-level-" + val + suffix + ".svg");
                        }
                    }
                }
                
                if (!name.endsWith("-bin")) {
                    candidates.push("file://" + base + name + "-bin.png");
                    candidates.push("file://" + base + name + "-bin.svg");
                }
            }
        }
        
        // Final generic fallbacks
        candidates.push(Quickshell.iconPath("dialog-information"));
        candidates.push(Quickshell.iconPath("application-x-executable"));
        
        // Deduplicate and filter out empty
        iconCandidates = candidates.filter((v, i, a) => v && v !== "" && a.indexOf(v) === i);
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
        
        Layout.alignment: Qt.AlignVCenter 

        // Icon Container
        Rectangle {
            id: iconContainer
            Layout.preferredWidth: Theme.scaled(50)
            Layout.preferredHeight: Theme.scaled(50)
            Layout.alignment: Qt.AlignVCenter 
            
            color: "#181825"
            radius: Theme.scaled(12)
            border.color: "#313244"
            border.width: 1

            Image {
                id: iconImg
                anchors.centerIn: parent
                
                // Fixed size for the image to avoid QSize(2, 2) warnings
                width: Theme.scaled(35)
                height: Theme.scaled(35)
                
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                
                onStatusChanged: {
                    if (status === Image.Ready) {
                         // Quickshell's icon provider returns a 100x100 checkerboard if not found
                         if (iconImg.implicitWidth === 100 && iconImg.implicitHeight === 100 && source.toString().startsWith("image://icon/")) {
                             tryNextIcon();
                         } else if (iconImg.implicitWidth <= 2) {
                             tryNextIcon();
                         }
                    } else if (status === Image.Error) {
                         tryNextIcon();
                    }
                }
            }
        }

        // Text Section
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
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
