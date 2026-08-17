import ".."
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: pill

    // ===== Public API =====
    property string icon: ""
    property string text: ""
    property color textColor: "white"
    property color hoverColor: Theme.pillHoverColor
    property color normalColor: Theme.pillColor
    // ===== Content injection =====
    default property alias content: contentItem.data
    // ✅ SAFE: children is bindable
    property bool hasCustomContent: contentItem.children.length > 1
    property alias containsMouse: mouseArea.containsMouse

    signal clicked(var mouse)
    signal wheel(var wheel)
    signal entered()

    radius: Theme.pillRadius
    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    // Hover is expressed as a binding, not as an assignment from onEntered.
    // Assigning to `color` in a handler permanently destroys the binding
    // underneath it, so after the first time the pointer touched a pill that
    // pill was frozen at whatever colour the handler last wrote -- it could
    // no longer follow a theme change, and any widget that varies
    // `normalColor` by state stopped updating entirely.
    color: mouseArea.containsMouse ? hoverColor : normalColor
    clip: true
    implicitWidth: Math.max(fallback.implicitWidth, contentItem.childrenRect.width) + Theme.pillPadding * 2

    scale: mouseArea.pressed ? 0.95 : (mouseArea.containsMouse ? 1.04 : 1.0)
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

    Item {
        id: contentItem

        anchors.centerIn: parent
        // Mouse-transparency not strictly needed if MouseArea is on top with high Z

        RowLayout {
            id: fallback

            visible: !pill.hasCustomContent
            spacing: pill.text === "" ? 0 : Theme.pillGap

            Text {
                text: pill.icon
                color: pill.textColor
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: pill.text
                visible: pill.text !== ""
                color: pill.textColor
                font.pixelSize: Theme.fontSize
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
            }

        }

    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        z: 10 // Highest Z-index to ensure it captures events over everything inside
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: pill.entered()
        onClicked: (mouse) => pill.clicked(mouse)
        onWheel: (wheel) => pill.wheel(wheel)
    }

}
