import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../"
import "../../../services"
import "../../../Settings"
import "../../../windows/settings/tabs" as Tabs

ColumnLayout {
    id: root
    spacing: Theme.scaled(14)

    property int activeTab: 0

    readonly property var subTabs: [
        { name: "General", icon: "󰘚" },
        { name: "Bar", icon: "󰇄" },
        { name: "Appearance", icon: "󰏘" },
        { name: "Workspace", icon: "󰨇" },
        { name: "Battery", icon: "󰁹" },
        { name: "Media", icon: "󰎆" },
        { name: "Hyprland", icon: "󱓞" },
        { name: "Displays", icon: "󰍹" }
    ]

    // Horizontal Sub-Tabs Row
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.scaled(8)

        Repeater {
            model: root.subTabs
            delegate: Rectangle {
                id: tabBtn
                implicitWidth: tabRow.implicitWidth + Theme.scaled(20)
                height: Theme.scaled(32)
                radius: Theme.bubbleRadiusPill
                color: root.activeTab === index ? Theme.accentColor : (tabMouse.containsMouse ? Theme.cardBackgroundHover : "transparent")
                border.width: 0
                antialiasing: true
                scale: tabMouse.pressed ? 0.94 : 1.0

                Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.animInstant } }

                Row {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(6)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.icon
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(13)
                        color: root.activeTab === index ? Colors.on_primary : (tabMouse.containsMouse ? Theme.text : Theme.subtext0)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        font.pixelSize: Theme.scaled(11)
                        font.weight: Font.Bold
                        color: root.activeTab === index ? Colors.on_primary : (tabMouse.containsMouse ? Theme.text : Theme.subtext0)
                    }
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeTab = index
                }
            }
        }

        Item { Layout.fillWidth: true }
    }

    // Scrollable Settings View
    Flickable {
        id: settingsFlick
        FastWheel {}
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: width
        contentHeight: (settingsStack.children && settingsStack.children[settingsStack.currentIndex] ? settingsStack.children[settingsStack.currentIndex].implicitHeight : settingsStack.implicitHeight) + Theme.scaled(40)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            parent: settingsFlick
            anchors.top: settingsFlick.top
            anchors.bottom: settingsFlick.bottom
            anchors.right: settingsFlick.right
            anchors.rightMargin: 2
            width: 4
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                radius: 999
                color: Theme.accentColor
                opacity: 0.7
            }
        }

        StackLayout {
            id: settingsStack
            width: settingsFlick.width - Theme.scaled(12)
            currentIndex: root.activeTab
            onCurrentIndexChanged: settingsFlick.contentY = 0

            Tabs.GeneralTab { Layout.fillWidth: true }
            Tabs.BarTab { Layout.fillWidth: true }
            Tabs.AppearanceTab { Layout.fillWidth: true }
            Tabs.WorkspaceTab { Layout.fillWidth: true }
            Tabs.BatteryTab { Layout.fillWidth: true }
            Tabs.MediaTab { Layout.fillWidth: true }
            Tabs.HyprlandTab { Layout.fillWidth: true }
            Tabs.DisplayTab { Layout.fillWidth: true }
        }
    }
}
