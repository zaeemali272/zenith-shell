import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../.."
import "../../../"

Item {
    id: root
    property string activeTool: "Timer"

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        // Tools Tabs
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Repeater {
                model: ["Timer", "Todo"]
                delegate: Rectangle {
                    width: 80; height: 30; radius: 8
                    color: root.activeTool === modelData ? Theme.blue : Theme.surface1
                    Text { 
                        anchors.centerIn: parent; text: modelData; font.pixelSize: 10; font.weight: Font.Black
                        color: root.activeTool === modelData ? Theme.base : Theme.text 
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.activeTool = modelData }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            currentIndex: ["Timer", "Todo"].indexOf(root.activeTool)

            TimerContent { Layout.fillWidth: true; Layout.fillHeight: true }
            TodoContent { Layout.fillWidth: true; Layout.fillHeight: true }
        }
    }
}
