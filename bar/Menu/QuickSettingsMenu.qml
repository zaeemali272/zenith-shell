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

PanelWindow {
    id: root

    property var parentWindow: null
    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: (typeof wifiContent !== "undefined" && wifiContent.isInputActive) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quicksettings"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: mainContent
    }

    Component.onDestruction: MenuService.unregister(root)

    onVisibleChanged: {
        Variables.quickSettingsOpen = visible;
        if (visible) {
            MenuService.register(root);
            QuickSettingsService.qsVisible = true;
            Qt.callLater(() => mainContent.forceActiveFocus());
            showAnim.restart();
        } else {
            MenuService.unregister(root);
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
            duration: Theme.animNormal
            easing.type: Theme.animEasing
        }
        NumberAnimation {
            target: mainContent
            property: "scale"
            from: 0.94; to: 1.0
            duration: Theme.animNormal
            easing.type: Theme.animEasing
        }
        NumberAnimation {
            target: mainTranslate
            property: "y"
            from: -6; to: 0
            duration: Theme.animNormal
            easing.type: Theme.animEasing
        }
    }

    // --- DISMISS ON OUTER CLICK ---
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: QuickSettingsService.close()
    }

    // Masterwork Material 3 Floating QuickSettings Card (Directly below bar)
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
                        model: [
                            { id: "network", icon: "󰤨", title: "WIFI" },
                            { id: "bluetooth", icon: "󰂯", title: "BT" },
                            { id: "volume", icon: "󰕾", title: "AUDIO" },
                            { id: "powerprofile", icon: "󰍛", title: "PROF" },
                            { id: "battery", icon: "󰁹", title: "PWR" },
                            { id: "power", icon: "󰐥", title: "SYS" }
                        ]

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

                NumberAnimation { id: fadeAnim; target: contentStack; property: "opacity"; from: 0; to: 1; duration: Theme.animFast }

                StackLayout {
                    id: contentStack
                    width: scrollArea.availableWidth
                    height: {
                        if (currentIndex >= 0 && currentIndex < children.length && children[currentIndex]) {
                            return children[currentIndex].implicitHeight || 420;
                        }
                        return 420;
                    }
                    currentIndex: ["network", "bluetooth", "volume", "powerprofile", "battery", "power"].indexOf(QuickSettingsService.activeTab)

                    onCurrentIndexChanged: fadeAnim.restart()

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
