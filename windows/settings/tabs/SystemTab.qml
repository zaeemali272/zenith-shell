import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Settings"
import "../components"
import "../../../" as Shell

ColumnLayout {
    id: sysRoot
    spacing: 0

    property int subTab: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Shell.Theme.scaled(20)
        Layout.rightMargin: Shell.Theme.scaled(20)
        Layout.topMargin: Shell.Theme.scaled(16)
        Layout.bottomMargin: Shell.Theme.scaled(12)
        spacing: Shell.Theme.scaled(12)

        Text {
            text: "System & Power"
            font.pixelSize: Shell.Theme.scaled(20)
            font.weight: Font.Bold
            color: Shell.Theme.text
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            implicitWidth: sysSubRow.implicitWidth + Shell.Theme.scaled(8)
            height: Shell.Theme.scaled(30)
            radius: 999
            color: Shell.Theme.cardBackground
            border.color: Shell.Theme.glassBorder
            border.width: 1

            Row {
                id: sysSubRow
                anchors.centerIn: parent
                spacing: Shell.Theme.scaled(4)

                Repeater {
                    model: ["Hyprland", "Battery"]
                    delegate: Rectangle {
                        readonly property bool active: sysRoot.subTab === index
                        width: sysLbl.implicitWidth + Shell.Theme.scaled(16)
                        height: Shell.Theme.scaled(22)
                        radius: 999
                        color: active ? Shell.Theme.accentColor : (sysM.containsMouse ? Shell.Theme.cardBackgroundHover : "transparent")
                        Text {
                            id: sysLbl
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: Shell.Theme.scaled(10)
                            font.weight: Font.Bold
                            color: active ? Shell.Colors.on_primary : Shell.Theme.subtext0
                        }
                        MouseArea {
                            id: sysM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sysRoot.subTab = index
                        }
                    }
                }
            }
        }
    }

    HyprlandTab {
        visible: sysRoot.subTab === 0
        Layout.fillWidth: true
    }

    BatteryTab {
        visible: sysRoot.subTab === 1
        Layout.fillWidth: true
    }

    Item { Layout.fillHeight: true }
}
