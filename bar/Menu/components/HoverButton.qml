import "../../../Settings"
import QtQuick

// A simple helper to add hover effect to Rectangles used as buttons
Rectangle {
    property bool hovered: false
    property color baseColor: "transparent"
    property color hoverColor: Theme.surface0
    
    color: hovered ? hoverColor : baseColor
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: parent.hovered = true
        onExited: parent.hovered = false
    }
}
