import ".."
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
    implicitHeight: Theme.pillHeight
    color: normalColor
    clip: true
    implicitWidth: Math.max(fallback.implicitWidth, contentItem.childrenRect.width) + Theme.pillPadding * 2

    Item {
        id: contentItem

        anchors.centerIn: parent

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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: {
            pill.color = hoverColor;
            pill.entered();
        }
        onExited: pill.color = normalColor
        onClicked: (mouse) => pill.clicked(mouse)
        onWheel: (wheel) => pill.wheel(wheel)
    }

}
