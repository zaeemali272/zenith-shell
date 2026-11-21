import QtQuick
import QtQuick.Layouts
import "../../../" as Shell

Rectangle {
    id: settingRowRoot
    property string label: ""
    property string description: ""
    property alias helperText: settingRowRoot.description
    default property alias content: rowContent.data
    
    Layout.fillWidth: true
    implicitHeight: Math.max(Shell.Theme.scaled(56), settingCol.implicitHeight + Shell.Theme.scaled(18))
    height: implicitHeight
    color: "transparent"
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Shell.Theme.scaled(16)
        anchors.rightMargin: Shell.Theme.scaled(16)
        spacing: Shell.Theme.scaled(16)
        
        ColumnLayout {
            id: settingCol
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Shell.Theme.scaled(3)

            Text {
                text: settingRowRoot.label
                color: Shell.Theme.text
                font.pixelSize: Shell.Theme.scaled(14)
                font.weight: Font.Medium
                Layout.fillWidth: true
            }

            Text {
                text: settingRowRoot.description
                color: Shell.Theme.subtext0
                font.pixelSize: Shell.Theme.scaled(11)
                wrapMode: Text.WordWrap
                visible: settingRowRoot.description !== ""
                Layout.fillWidth: true
            }
        }
        
        Item {
            id: rowContent
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
    
    // Bottom border for separation
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width - Shell.Theme.scaled(32)
        anchors.horizontalCenter: parent.horizontalCenter
        height: Shell.Theme.scaled(1)
        color: Shell.Theme.surface1
    }
}
