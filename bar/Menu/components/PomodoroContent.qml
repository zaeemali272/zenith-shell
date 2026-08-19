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
            spacing: Theme.scaled(10)
            Repeater {
                model: ["Todo", "Roadmap", "Timer"]
                delegate: Rectangle {
                    width: Theme.scaled(80); height: Theme.scaled(30); radius: Theme.scaled(8)
                    color: root.activeTool === modelData ? Theme.blue : Theme.surface1
                    Text { 
                        anchors.centerIn: parent; text: modelData; font.pixelSize: Theme.scaled(10); font.weight: Font.Black
                        color: root.activeTool === modelData ? Theme.base : Theme.text 
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.activeTool = modelData }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            currentIndex: ["Todo", "Roadmap", "Timer"].indexOf(root.activeTool)

            TodoContent { Layout.fillWidth: true; Layout.fillHeight: true }
            RoadmapContent { Layout.fillWidth: true; Layout.fillHeight: true }
            TimerContent { Layout.fillWidth: true; Layout.fillHeight: true }
        }
    }

    function resetScroll() {
        root.activeTool = "Todo";
    }
}
