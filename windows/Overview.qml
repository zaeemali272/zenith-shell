import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../" as Root
import "overview"

PanelWindow {
    id: win
    
    // Fill the screen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    // Overlay layer to cover everything
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.margins { top: 10; bottom: 10; left: 10; right: 10 }
    
    visible: false
    color: "transparent"
    
    property bool active: false
    
    onActiveChanged: {
        if (active) {
            win.visible = true;
            root.opacity = 0;
            root.scale = 0.98;
            showAnim.start();
            // Use a small delay for component ready state
            Qt.callLater(() => {
                if (searchBar) searchBar.forceFocus();
            });
        } else {
            hideAnim.start();
            if (searchBar) searchBar.text = "";
        }
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; from: 0.98; to: 1; duration: 300; easing.type: Easing.OutCubic }
    }
    
    SequentialAnimation {
        id: hideAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "scale"; to: 0.98; duration: 250; easing.type: Easing.InCubic }
        }
        PropertyAction { target: win; property: "visible"; value: false }
    }

    // Full screen background blur effect (simulated with dark transparent rect)
    Rectangle {
        id: root
        anchors.fill: parent
        radius: 20
        color: Root.Theme.crust ? Qt.rgba(Root.Theme.crust.r, Root.Theme.crust.g, Root.Theme.crust.b, 0.40) : '#4d010101'
        
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) active = false;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: active = false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: Root.Theme.scaled ? Root.Theme.scaled(20) : 20
            anchors.bottomMargin: Root.Theme.scaled ? Root.Theme.scaled(20) : 20
            anchors.leftMargin: Root.Theme.isSmallScreen ? Root.Theme.scaled(20) : Root.Theme.scaled(120)
            anchors.rightMargin: Root.Theme.isSmallScreen ? Root.Theme.scaled(20) : Root.Theme.scaled(120)
            spacing: Root.Theme.scaled ? Root.Theme.scaled(20) : 20

            // Search Bar
            Search {
                id: searchBar
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: Root.Theme.scaled ? Root.Theme.scaled(45) : 45
                Layout.preferredWidth: Root.Theme.isSmallScreen ? parent.width - 40 : Root.Theme.scaled(500)
                onQueryChanged: (query) => appGrid.searchText = query
            }

            // Workspaces (GNOME style top bar)
            Workspaces {
                id: workspaceView
                Layout.fillWidth: true
                Layout.preferredHeight: Root.Theme.isSmallScreen ? Root.Theme.scaled(180) : Root.Theme.scaled(250)
            }

            // App Grid
            Apps {
                id: appGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                onCloseRequested: active = false
            }
        }
    }
    
    function toggle() {
        active = !active;
    }

}
