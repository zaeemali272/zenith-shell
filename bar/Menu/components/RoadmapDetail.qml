// The panel that opens when you click a node, the way roadmap.sh opens one.
//
// Lifted out of RoadmapContent, which had grown past 40KB and was the largest
// file in the repo. This part is self-contained -- it renders whatever it is
// handed and reports back through signals -- so it had no business living
// inside the graph view.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../"
import "../../../services"
import "../../../Settings"

Rectangle {
    id: detail

    property string topicTitle: ""
    property string body: ""
    property var resources: []
    property bool loading: false
    property bool isDone: false

    signal closed()
    signal toggleDone()
    signal openLink(string url)

    color: Colors.surface_container_high
    radius: Theme.bubbleRadiusMedium
    border.color: Colors.outline_variant
    border.width: 1

    // Absorb mouse events to prevent clicking through to graph nodes underneath
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    Keys.onEscapePressed: detail.closed()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.scaled(16)
        spacing: Theme.scaled(12)

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(8)

            Rectangle {
                width: backLabel.implicitWidth + Theme.scaled(20)
                height: Theme.scaled(26)
                radius: Theme.scaled(8)
                color: backM.containsMouse ? Theme.cardBackgroundHover : Qt.rgba(255, 255, 255, 0.08)
                border.color: Theme.cardBorder
                border.width: 1
                Text {
                    id: backLabel
                    anchors.centerIn: parent
                    text: "← Back"
                    color: Theme.text
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: backM; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: detail.closed()
                }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: doneLabel.implicitWidth + Theme.scaled(24)
                height: Theme.scaled(26)
                radius: Theme.scaled(8)
                color: detail.isDone ? Theme.accentColor
                     : (doneM.containsMouse ? Theme.cardBackgroundHover : Qt.rgba(255, 255, 255, 0.08))
                border.color: detail.isDone ? Theme.accentColor : Theme.cardBorder
                border.width: 1
                Behavior on color { ColorAnimation { duration: Theme.animInstant } }
                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)
                    Text {
                        visible: detail.isDone
                        text: "󰄬"
                        font.family: Theme.iconFont
                        color: Colors.on_primary
                        font.pixelSize: Theme.scaled(11)
                        font.bold: true
                    }
                    Text {
                        id: doneLabel
                        text: detail.isDone ? "Done" : "Mark done"
                        color: detail.isDone ? Colors.on_primary : Theme.text
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Bold
                    }
                }
                MouseArea {
                    id: doneM; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: detail.toggleDone()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: detail.topicTitle
            color: Theme.text
            font.pixelSize: Theme.scaled(16)
            font.weight: Font.Black
            wrapMode: Text.WordWrap
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: detailCol.implicitHeight
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            FastWheel {}

            ColumnLayout {
                id: detailCol
                width: parent.width
                spacing: Theme.scaled(10)

                // Body Skeleton while loading
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(8)
                    visible: detail.loading

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.35; to: 0.75; duration: 800; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.75; to: 0.35; duration: 800; easing.type: Easing.InOutSine }
                    }

                    Rectangle { Layout.fillWidth: true; height: Theme.scaled(12); radius: 3; color: Qt.rgba(255, 255, 255, 0.12) }
                    Rectangle { Layout.fillWidth: true; height: Theme.scaled(12); radius: 3; color: Qt.rgba(255, 255, 255, 0.10) }
                    Rectangle { width: parent.width * 0.75; height: Theme.scaled(12); radius: 3; color: Qt.rgba(255, 255, 255, 0.08) }
                    Rectangle { width: parent.width * 0.5; height: Theme.scaled(12); radius: 3; color: Qt.rgba(255, 255, 255, 0.06) }
                }

                Text {
                    Layout.fillWidth: true
                    visible: !detail.loading
                    text: detail.body
                    color: Theme.subtext1
                    font.pixelSize: Theme.scaled(12)
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                }

                Text {
                    Layout.fillWidth: true
                    visible: detail.resources.length > 0
                    text: "RESOURCES"
                    color: Theme.accentColor
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.Black
                    font.letterSpacing: 1
                }

                Repeater {
                    model: detail.resources
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: resRow.implicitHeight + Theme.scaled(14)
                        radius: Theme.scaled(8)
                        color: resM.containsMouse ? Theme.cardBackgroundHover : Qt.rgba(255, 255, 255, 0.05)
                        border.color: Theme.cardBorder
                        border.width: 1

                        RowLayout {
                            id: resRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Theme.scaled(10)
                            anchors.rightMargin: Theme.scaled(10)
                            spacing: Theme.scaled(8)

                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                width: kindLabel.implicitWidth + Theme.scaled(12)
                                height: Theme.scaled(18)
                                radius: Theme.scaled(4)
                                color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g,
                                               Theme.accentColor.b, 0.18)
                                Text {
                                    id: kindLabel
                                    anchors.centerIn: parent
                                    text: modelData.kind
                                    color: Theme.accentColor
                                    font.pixelSize: Theme.scaled(8.5)
                                    font.weight: Font.Black
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Theme.text
                                font.pixelSize: Theme.scaled(11)
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            id: resM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: detail.openLink(modelData.url)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: !detail.loading && detail.resources.length === 0
                             && detail.body !== ""
                    text: "No links published for this topic."
                    color: Theme.subtext0
                    font.pixelSize: Theme.scaled(10)
                }
            }
        }
        }
}
