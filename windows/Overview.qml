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
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.margins { top: 10; bottom: 10; left: 10; right: 10 }
    
    visible: false
    color: "transparent"
    
    property bool active: false
    
    // Core performance tweak: Populate the layout on boot, not on window display!
    Component.onCompleted: {
        if (!appGrid.isInitialized) {
            appGrid.updateList();
        }
    }
    
    onActiveChanged: {
        if (active) {
            win.visible = true;
            // Immediate focus targeting without deep JS nesting callbacks
            searchBar.forceFocus();
        } else {
            win.visible = false;
            searchBar.text = "";
        }
    }

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

            Search {
                id: searchBar
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: Root.Theme.scaled ? Root.Theme.scaled(45) : 45
                Layout.preferredWidth: Root.Theme.isSmallScreen ? parent.width - 40 : Root.Theme.scaled(500)
                
                // Route navigation requests directly to the grid instance properties
                onNavigateRequested: (direction) => appGrid.navigate(direction)
                onSelectRequested: appGrid.launchCurrent()
                
                onQueryChanged: (query) => appGrid.searchText = query
                onRequestCalculation: (expr) => searchBar.setCalcResult(calculateMath(expr))
            }

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

    function calculateMath(expression) {
        if (/^[0-9+\-*/(). ]+$/.test(expression) && /[+\-*/]/.test(expression)) {
            try {
                let result = eval(expression);
                if (typeof result === 'number' && !isNaN(result)) {
                    return "= " + result;
                }
            } catch (e) {}
        }
        return "";
    }
}