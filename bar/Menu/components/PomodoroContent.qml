import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../.."
import "../../../"
import "../../../services"

Item {
    id: root
    property string activeTool: CenterState.focusTool

    onActiveToolChanged: CenterState.focusTool = activeTool

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.scaled(20)

        // Tools Tabs
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(8)
            Repeater {
                model: ["Todo", "Roadmap", "Timer", "Mail", "Services"]
                delegate: Rectangle {
                    id: toolTabRect
                    implicitWidth: tabRow.implicitWidth + Theme.scaled(26)
                    height: Theme.scaled(32)
                    radius: Theme.bubbleRadiusPill
                    color: root.activeTool === modelData ? Theme.accentColor : (toolTabMouse.containsMouse ? Theme.cardBackgroundHover : "transparent")
                    border.width: 0
                    antialiasing: true
                    scale: toolTabMouse.pressed ? 0.94 : 1.0

                    Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.animInstant } }

                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: Theme.scaled(7)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData === "Services" ? "󰒍" : (modelData === "Todo" ? "󰄲" : (modelData === "Roadmap" ? "󰙅" : (modelData === "Mail" ? "󰇮" : "󱎫")))
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(14)
                            color: root.activeTool === modelData ? Colors.on_primary : (toolTabMouse.containsMouse ? Theme.text : Theme.subtext0)
                        }

                        Text { 
                            id: toolTabText
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData === "Services" ? "Services" : (modelData === "Todo" ? "Tasks" : (modelData === "Mail" ? "Mail" : modelData))
                            font.pixelSize: Theme.scaled(11)
                            font.weight: Font.Bold
                            color: root.activeTool === modelData ? Colors.on_primary : (toolTabMouse.containsMouse ? Theme.text : Theme.subtext0) 
                        }
                    }

                    MouseArea { 
                        id: toolTabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTool = modelData 
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        StackLayout {
            id: toolStack
            Layout.fillWidth: true; Layout.fillHeight: true
            currentIndex: ["Todo", "Roadmap", "Timer", "Mail", "Services"].indexOf(root.activeTool)

            TodoContent { id: todoContent; Layout.fillWidth: true; Layout.fillHeight: true }
            RoadmapContent { Layout.fillWidth: true; Layout.fillHeight: true }
            TimerContent { Layout.fillWidth: true; Layout.fillHeight: true }
            MailContent { Layout.fillWidth: true; Layout.fillHeight: true }
            ServicesContent { id: servicesContent; Layout.fillWidth: true; Layout.fillHeight: true }
        }

    }

    function handleKeys(event) {
        if (root.activeTool === "Todo" && typeof todoContent.handleKeys === 'function') {
            todoContent.handleKeys(event);
        }
    }

    function resetScroll() {
        root.activeTool = "Todo";
    }
}
