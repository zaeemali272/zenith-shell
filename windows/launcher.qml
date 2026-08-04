import QtQuick
import QtQuick.Controls
import Quickshell

import "components"

Window {
    id: launcherRoot
    width: 700
    height: 500
    visible: true
    flags: Qt.FramelessWindowHint | Qt.Window
    color: "transparent"

    property var filteredApps: []

    function rebuildFiltered() {
        let query = searchInput.text.toLowerCase().trim();
        let result = [];
        let apps = DesktopEntries.applications.values;

        for (let entry of apps) {
            if (!entry || !entry.name || entry.noDisplay) continue;
            if (typeof IconsFetcher !== "undefined" && !IconsFetcher.isMainApp(entry.id, entry.name)) continue;

            if (query !== "") {
                let name = (entry.name || "").toLowerCase();
                let exec = (entry.id  || "").toLowerCase();
                if (!name.includes(query) && !exec.includes(query)) continue;
            }
            result.push(entry);
        }

        // Sort alphabetically by name
        result.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        filteredApps = result;
    }

    Component.onCompleted: rebuildFiltered()

    // Background Container
    Rectangle {
        id: backgroundPanel
        anchors.fill: parent
        radius: 24
        color: Qt.rgba(0.08, 0.08, 0.12, 0.90)
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        // Purple blob (top-left)
        Rectangle {
            width: 300
            height: 300
            x: -50
            y: -50
            radius: width / 2
            color: Qt.rgba(0.54, 0.17, 0.89, 0.20)

            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { to: 1.1; duration: 5000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.9; duration: 5000; easing.type: Easing.InOutSine }
            }
        }

        // Blue blob (bottom-right)
        Rectangle {
            width: 200
            height: 200
            x: backgroundPanel.width - 100
            y: backgroundPanel.height - 100
            radius: width / 2
            color: Qt.rgba(0.31, 0.47, 1.0, 0.15)

            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { to: 1.15; duration: 6000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.85; duration: 6000; easing.type: Easing.InOutSine }
            }
        }

        // Main content column
        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Search bar
            Rectangle {
                width: parent.width
                height: 48
                radius: 14
                color: Qt.rgba(1, 1, 1, 0.05)
                border.color: searchInput.activeFocus
                    ? Qt.rgba(0.54, 0.17, 0.89, 0.70)
                    : Qt.rgba(1, 1, 1, 0.10)
                border.width: 1

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "⌕"
                        color: Qt.rgba(1, 1, 1, 0.40)
                        font.pixelSize: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: searchInput
                        width: parent.width - 40
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 16
                        color: "white"
                        focus: true

                        onTextChanged: launcherRoot.rebuildFiltered()

                        Keys.onEscapePressed: launcherRoot.close()

                        Text {
                            text: "Type to search applications..."
                            color: Qt.rgba(1, 1, 1, 0.30)
                            font.pixelSize: 16
                            visible: searchInput.text.length === 0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Application list
            ListView {
                id: appListView
                width: parent.width
                height: parent.height - 70
                clip: true
                model: launcherRoot.filteredApps
                spacing: 4

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    id: delegateRoot
                    width: appListView.width
                    height: 56
                    radius: 12
                    color: hoverArea.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.08)
                        : Qt.rgba(0, 0, 0, 0)

                    required property var modelData
                    required property int index

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            delegateRoot.modelData.execute();
                            launcherRoot.close();
                        }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        spacing: 16

                        // App icon
                        IconImage {
                            width: 40
                            height: 40
                            anchors.verticalCenter: parent.verticalCenter
                            appName:      delegateRoot.modelData.name      || ""
                            desktopEntry: delegateRoot.modelData.id        || ""
                            iconName:     delegateRoot.modelData.icon      || ""
                        }

                        // Labels
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: delegateRoot.modelData.name || "Unknown"
                                color: "white"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }
                            Text {
                                text: delegateRoot.modelData.genericName
                                    || delegateRoot.modelData.comment
                                    || delegateRoot.modelData.categories
                                    || ""
                                color: Qt.rgba(1, 1, 1, 0.40)
                                font.pixelSize: 11
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                width: appListView.width - 80
                                visible: text !== ""
                            }
                        }
                    }
                }
            }
        }
    }
}