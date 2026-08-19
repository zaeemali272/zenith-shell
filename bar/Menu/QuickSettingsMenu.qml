import "../.."
import "../../services"
import "../../Settings"
import "./components"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

MenuWindow {
    id: root

    card: mainContent
    namespaceName: "quicksettings"

    readonly property var allTabs: [
        { id: "network", icon: "󰤨", title: "WI-FI" },
        { id: "bluetooth", icon: "󰂯", title: "BT" },
        { id: "volume", icon: "󰕾", title: "AUDIO" },
        { id: "powerprofile", icon: "󰍛", title: "POWER" },
        { id: "battery", icon: "󰁹", title: "BATTERY" },
        { id: "power", icon: "󰐥", title: "SESSION" }
    ]

    readonly property var availableTabs: allTabs.filter(function (t) {
        if (t.id === "bluetooth") return HardwareService.hasBluetooth;
        if (t.id === "battery")   return HardwareService.hasBattery;
        if (t.id === "network")   return HardwareService.hasNetworking;
        return true;
    })
    // Typing a WiFi password flips keyboardFocus, which reconfigures the
    // surface and drops the grab; without this the panel vanished the
    // moment you clicked a network to connect to.
    dismissInhibited: typeof wifiContent !== "undefined" && wifiContent.isInputActive
    onDismissed: QuickSettingsService.close()

    property var parentWindow: null

    WlrLayershell.keyboardFocus: (typeof wifiContent !== "undefined" && wifiContent.isInputActive) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
    onVisibleChanged: {
        Variables.quickSettingsOpen = visible;
        if (visible) {
            QuickSettingsService.qsVisible = true;
            Qt.callLater(() => mainContent.forceActiveFocus());
            showAnim.restart();
        } else {
            QuickSettingsService.qsVisible = false;
            mainContent.opacity = 0;
            mainContent.scale = 0.94;
            mainTranslate.y = -6;
        }
    }


    ParallelAnimation {
        id: showAnim
        NumberAnimation {
            target: mainContent
            property: "opacity"
            from: 0; to: 1
            duration: Theme.animFast
            easing.type: Theme.animEasing
        }
        NumberAnimation {
            target: mainContent
            property: "scale"
            from: 0.94; to: 1.0
            duration: Theme.animFast
            easing.type: Theme.animEasing
        }
        NumberAnimation {
            target: mainTranslate
            property: "y"
            from: -6; to: 0
            duration: Theme.animFast
            easing.type: Theme.animEasing
        }
    }

    // Outer clicks are dismissed by DismissOverlay; the input mask and the
    // reason a dismiss MouseArea cannot live here are documented in
    // MenuWindow.qml.
    Rectangle {
        id: mainContent
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barMarginTop + Theme.scaled(4)
        anchors.rightMargin: Theme.isSmallScreen ? Theme.scaled(8) : Theme.scaled(14)

        // Production-ready responsive dimensions
        width: Math.min(Theme.scaled(560), (screen ? screen.width : Theme.screenWidth) - Theme.scaled(20))
        height: Math.min(Theme.scaled(500), (screen ? screen.height : Theme.screenHeight) - Theme.barHeight - Theme.scaled(20))

        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                QuickSettingsService.close();
            } else {
                let currentContent = contentStack.children[contentStack.currentIndex];
                if (currentContent && typeof currentContent.handleKeys === 'function') {
                    currentContent.handleKeys(event);
                }
            }
        }
        
        color: Theme.glassBackground
        radius: Theme.cardRadius
        border.color: Theme.glassBorder
        border.width: 2
        clip: true

        opacity: 0
        scale: 0.94
        transformOrigin: Item.TopRight
        
        transform: Translate { id: mainTranslate; y: -6 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(16)
            spacing: Theme.scaled(14)

            // --- MATERIAL 3 SEGMENTED TAB BAR ---
            Rectangle {
                Layout.fillWidth: true
                height: Theme.scaled(50)
                color: Qt.rgba(0, 0, 0, 0.35)
                radius: 999
                border.width: 0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.scaled(4)
                    spacing: Theme.scaled(4)
                    
                    Repeater {
                        // Only the tabs this machine can actually use. A
                        // Bluetooth tab on a desktop with no adapter, or a
                        // battery tab in a VM, is a dead button.
                        model: root.availableTabs

                        delegate: Rectangle {
                            id: tabRect
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 999
                            color: QuickSettingsService.activeTab === modelData.id ? Theme.accentColor : (tabMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent")
                            
                            scale: tabMouse.pressed ? 0.94 : (tabMouse.containsMouse ? 1.03 : 1.0)
                            
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Theme.scaled(5)
                                Text {
                                    text: modelData.icon
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(16)
                                    color: QuickSettingsService.activeTab === modelData.id ? Colors.on_primary : "#ffffff"
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                Text {
                                    text: modelData.title
                                    font.pixelSize: Theme.scaled(9)
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.5
                                    visible: QuickSettingsService.activeTab === modelData.id || !Theme.isSmallScreen
                                    color: QuickSettingsService.activeTab === modelData.id ? Colors.on_primary : "#ffffff"
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent; hoverEnabled: true
                                onClicked: QuickSettingsService.activeTab = modelData.id
                            }
                        }
                    }
                }
            }

            // --- CONTENT AREA ---
            ScrollView {
                id: scrollArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                contentHeight: contentStack.height

                ScrollBar.vertical: ScrollBar {
                    parent: scrollArea
                    anchors.top: scrollArea.top
                    anchors.bottom: scrollArea.bottom
                    anchors.right: scrollArea.right
                    policy: ScrollBar.AsNeeded
                    width: 3
                    contentItem: Rectangle { radius: 999; color: Theme.accentColor; opacity: 0.6 }
                }

                ParallelAnimation {
                    id: transitionAnim
                    NumberAnimation { target: contentStack; property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutQuad }
                    NumberAnimation { target: contentTranslate; property: "y"; from: 8; to: 0; duration: 250; easing.type: Easing.OutQuad }
                }

                StackLayout {
                    id: contentStack
                    width: scrollArea.availableWidth
                    transform: Translate { id: contentTranslate }
                    // Own implicitHeight, not a walk over children. See the
                    // segfault note: the previous binding read
                    // children[currentIndex].implicitHeight, which re-enters
                    // Qt's layout engine from inside its own rearrange.
                    height: Math.max(implicitHeight, Theme.scaled(420))
                    // Indexed against allTabs, because the pages below are all
                    // still here in their original order -- only the tab strip
                    // is filtered. Indexing the filtered list would show the
                    // wrong page as soon as one was hidden.
                    //
                    // A tab that has been filtered out can still be the active
                    // one (a saved state, or a keybind), so fall back to the
                    // first tab this machine actually has.
                    currentIndex: {
                        var all = root.allTabs.map(function (t) { return t.id; });
                        var avail = root.availableTabs.map(function (t) { return t.id; });
                        var active = QuickSettingsService.activeTab;
                        if (avail.indexOf(active) < 0 && avail.length > 0)
                            active = avail[0];
                        var i = all.indexOf(active);
                        return i >= 0 ? i : 0;
                    }

                    onCurrentIndexChanged: transitionAnim.restart()

                    WifiContent { id: wifiContent }
                    BluetoothContent { }
                    VolumeContent { }
                    PowerProfileContent { }
                    BatteryContent { }
                    PowerContent { 
                        id: powerContent
                        Connections {
                            target: QuickSettingsService
                            function onActiveTabChanged() {
                                if (QuickSettingsService.activeTab === "power") {
                                    powerContent.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
