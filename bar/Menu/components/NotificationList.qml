import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../../Settings"
import "../../../services"
import "../../../"

ColumnLayout {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Theme.scaled(8)

    property bool searchOpen: false
    property string searchText: ""
    property string selectedApp: "All"
    property int _rev: 0

    function toggleSearch() {
        searchOpen = !searchOpen;
        if (searchOpen) {
            Qt.callLater(() => filterInput.forceActiveFocus());
        } else {
            searchText = "";
            filterInput.text = "";
            selectedApp = "All";
        }
    }

    function resetScroll() {
        notifFlick.contentY = 0;
    }

    readonly property var appList: {
        let _r = _rev;
        let count = NotificationService.notifications.count;
        let seen = {};
        let apps = ["All"];
        for (let i = 0; i < count; i++) {
            let n = NotificationService.notifications.get(i);
            let app = (n && n.appName) ? String(n.appName).trim() : "";
            if (app && !seen[app]) {
                seen[app] = true;
                apps.push(app);
            }
        }
        return apps;
    }

    readonly property var filteredIndices: {
        let _r = _rev;
        let count = NotificationService.notifications.count;
        let q = searchText.trim().toLowerCase();
        let appFilter = selectedApp;
        let out = [];
        for (let i = 0; i < count; i++) {
            let n = NotificationService.notifications.get(i);
            if (!n) continue;
            let app = String(n.appName || "");
            if (appFilter !== "All" && app !== appFilter) continue;
            if (q !== "") {
                let hay = (app + " " + String(n.summary || "") + " " + String(n.body || "")).toLowerCase();
                if (!hay.includes(q)) continue;
            }
            out.push(i);
        }
        return out;
    }

    Connections {
        target: NotificationService.notifications
        function onCountChanged() {
            root._rev++;
            if (NotificationService.notifications.count === 0) {
                root.searchOpen = false;
                root.searchText = "";
                root.selectedApp = "All";
            }
        }
    }

    // DND Active Banner
    Rectangle {
        visible: PowerToolsService.dnd && NotificationSettings.enableNotifications
        Layout.fillWidth: true
        height: Theme.scaled(28)
        radius: Theme.scaled(8)
        color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.12)
        border.color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.3)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.scaled(10)
            anchors.rightMargin: Theme.scaled(10)
            spacing: Theme.scaled(6)

            Text {
                text: "󰂛"
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(12)
                color: Theme.accentColor
            }
            Text {
                Layout.fillWidth: true
                text: "Do Not Disturb active — popups silenced"
                color: Theme.text
                font.pixelSize: Theme.scaled(10)
                elide: Text.ElideRight
            }
            Text {
                text: "Resume"
                color: Theme.accentColor
                font.pixelSize: Theme.scaled(10)
                font.weight: Font.Bold
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PowerToolsService.toggleDnd()
                }
            }
        }
    }

    // Search & App Filter Bar
    ColumnLayout {
        visible: NotificationSettings.enableNotifications && NotificationService.notifications.count > 0 && (root.searchOpen || root.appList.length > 2)
        Layout.fillWidth: true
        spacing: Theme.scaled(6)

        Rectangle {
            visible: root.searchOpen
            Layout.fillWidth: true
            height: Theme.scaled(30)
            radius: Theme.scaled(8)
            color: Theme.surface1
            border.color: filterInput.activeFocus ? Theme.accentColor : Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(8)
                anchors.rightMargin: Theme.scaled(8)
                spacing: Theme.scaled(6)

                Text {
                    text: "󰍉"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(13)
                    color: Theme.subtext0
                }

                TextInput {
                    id: filterInput
                    Layout.fillWidth: true
                    color: Theme.text
                    font.pixelSize: Theme.scaled(11)
                    clip: true
                    onTextChanged: root.searchText = text
                    Keys.onEscapePressed: root.toggleSearch()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Filter notifications..."
                        color: Theme.subtext2
                        font.pixelSize: Theme.scaled(11)
                        visible: !parent.text && !parent.activeFocus
                    }
                }

                Text {
                    visible: root.searchText !== ""
                    text: "󰅖"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(12)
                    color: Theme.subtext0
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            filterInput.text = "";
                            root.searchText = "";
                        }
                    }
                }
            }
        }

        // App Filter Chips (only when notifications come from multiple apps)
        Flickable {
            visible: root.appList.length > 2
            Layout.fillWidth: true
            height: Theme.scaled(24)
            contentWidth: chipsRow.implicitWidth
            clip: true

            Row {
                id: chipsRow
                spacing: Theme.scaled(5)

                Repeater {
                    model: root.appList
                    delegate: Rectangle {
                        readonly property bool active: root.selectedApp === modelData
                        width: chipLabel.implicitWidth + Theme.scaled(14)
                        height: Theme.scaled(22)
                        radius: 999
                        color: active ? Theme.accentColor : (chipHover.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
                        border.color: active ? Theme.accentColor : Theme.glassBorder
                        border.width: 1

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: Theme.scaled(9.5)
                            font.weight: active ? Font.Bold : Font.Medium
                            color: active ? Colors.on_primary : Theme.subtext0
                        }

                        MouseArea {
                            id: chipHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedApp = modelData
                        }
                    }
                }
            }
        }
    }

    // Notifications Disabled State
    Item {
        visible: !NotificationSettings.enableNotifications
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.scaled(6)
            opacity: 0.7

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "󰂛"
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(42)
                color: Theme.subtext0
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Notifications paused"
                color: Theme.text
                font.pixelSize: Theme.scaled(13)
                font.weight: Font.Bold
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Re-enable notifications in Settings"
                color: Theme.subtext0
                font.pixelSize: Theme.scaled(10)
            }
        }
    }

    // Scrollable Notification Feed / Empty State
    Flickable {
        id: notifFlick
        FastWheel {}
        visible: NotificationSettings.enableNotifications
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: Math.max(height, mainLayout.implicitHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 3
            contentItem: Rectangle { radius: 999; color: Theme.accentColor; opacity: 0.6 }
        }

        ColumnLayout {
            id: mainLayout
            width: notifFlick.width
            height: root.filteredIndices.length === 0 ? notifFlick.height : implicitHeight
            spacing: Theme.scaled(8)

            Repeater {
                model: root.filteredIndices
                delegate: NotificationItem {
                    notification: NotificationService.notifications.get(modelData)
                    itemIndex: index
                    Layout.fillWidth: true
                    enableAutoDismiss: false
                    animateOut: false
                }
            }

            // Centered Empty / No-Match State
            Item {
                visible: root.filteredIndices.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Theme.scaled(6)
                    opacity: 0.65

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: NotificationService.notifications.count === 0 ? "󰂚" : "󰍉"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(44)
                        color: Theme.subtext0
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: NotificationService.notifications.count === 0 ? "All caught up" : "No matching notifications"
                        color: Theme.text
                        font.pixelSize: Theme.scaled(13)
                        font.weight: Font.Bold
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: NotificationService.notifications.count === 0
                            ? "New notifications will appear here"
                            : "Try clearing your search or app filter"
                        color: Theme.subtext0
                        font.pixelSize: Theme.scaled(10)
                    }
                }
            }
        }
    }
}
