import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../" as Root

PanelWindow {
    id: popupBase

    property alias content: contentContainer.data
    property bool active: false
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.margins { top: 20; bottom: 20; left: 20; right: 20 }
    
    visible: active
    color: "transparent"

    onActiveChanged: {
        if (active) {
            popupBase.visible = true;
            root.opacity = 0;
            root.scale = 0.95;
            showAnim.start();
        } else {
            hideAnim.start();
        }
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; from: 0.95; to: 1; duration: 250; easing.type: Easing.OutBack }
    }
    
    SequentialAnimation {
        id: hideAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 0; duration: 200; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "scale"; to: 0.95; duration: 200; easing.type: Easing.InCubic }
        }
        PropertyAction { target: popupBase; property: "visible"; value: false }
    }

    Rectangle {
        id: root
        anchors.fill: parent
        radius: 24
        color: Root.Theme.crust ? Qt.rgba(Root.Theme.crust.r, Root.Theme.crust.g, Root.Theme.crust.b, 0.30) : '#4d010101'
        border.color: Root.Theme.glassBorder
        border.width: 1
        
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) active = false;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: active = false
        }

        Item {
            id: contentContainer
            anchors.fill: parent
            anchors.margins: Root.Theme.scaled ? Root.Theme.scaled(30) : 30
        }
    }
}
