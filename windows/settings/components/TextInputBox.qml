import QtQuick
import QtQuick.Controls
import "../../../" as Shell

Rectangle {
    id: control
    width: Shell.Theme.scaled(180)
    height: Shell.Theme.scaled(32)
    radius: Shell.Theme.scaled(8)
    color: Shell.Theme.surface1
    clip: true
    
    property alias text: input.text
    signal accepted(string text)

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Shell.Theme.scaled(10)
        anchors.rightMargin: Shell.Theme.scaled(10)
        verticalAlignment: TextInput.AlignVCenter
        color: Shell.Theme.text
        font.pixelSize: Shell.Theme.scaled(13)
        selectByMouse: true
        clip: true
        onAccepted: control.accepted(text)
        onTextEdited: control.accepted(text)
    }
}
