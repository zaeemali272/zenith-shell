import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "components"
import ".." as Root

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
    
    visible: true
    color: "transparent"
    
    property bool active: true
    
    onActiveChanged: {
        if (active) {
            win.visible = true;
            root.opacity = 0;
            root.scale = 0.98;
            showAnim.start();
            if (searchBar) searchBar.forceFocus();
        } else {
            hideAnim.start();
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
        ScriptAction { script: Qt.quit(); }
    }

    // Full screen background blur effect (simulated with dark transparent rect)
    Rectangle {
        id: root
        anchors.fill: parent
        radius: 15
        color: Root.Theme.crust ? Qt.rgba(Root.Theme.crust.r, Root.Theme.crust.g, Root.Theme.crust.b, 0.85) : "#d911111b"
        
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
            anchors.topMargin: (Root.Theme && Root.Theme.scaled) ? Root.Theme.scaled(60) : 60
            anchors.bottomMargin: (Root.Theme && Root.Theme.scaled) ? Root.Theme.scaled(40) : 40
            anchors.leftMargin: (Root.Theme && Root.Theme.scaled) ? Root.Theme.scaled(100) : 100
            anchors.rightMargin: (Root.Theme && Root.Theme.scaled) ? Root.Theme.scaled(100) : 100
            spacing: (Root.Theme && Root.Theme.scaled) ? Root.Theme.scaled(40) : 40

            // Search Bar
            SearchBar {
                id: searchBar
                Layout.alignment: Qt.AlignHCenter
                onQueryChanged: (query) => appMenu.searchText = query
            }

            // Workspaces (GNOME style top bar)
            WorkspaceView {
                id: workspaceView
                Layout.fillWidth: true
                Layout.preferredHeight: (Root.Theme && Root.Theme.scaled) ? Root.Theme.scaled(250) : 250
            }

            // App Grid
            AppMenu {
                id: appMenu
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
    
    function toggle() {
        active = !active;
    }

    Component.onCompleted: {
        searchBar.forceFocus();
    }
}
