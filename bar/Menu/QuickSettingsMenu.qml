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

    shown: QuickSettingsService.qsVisible
    card: mainContent
    namespaceName: "quicksettings"
    cardOrigin: Item.TopRight

    readonly property var allTabs: [
        { id: "main", icon: "󰕮", title: "HOME" },
        { id: "network", icon: "󰤨", title: "NETWORK" },
        { id: "bluetooth", icon: "󰂯", title: "BT" },
        { id: "volume", icon: "󰕾", title: "SOUND" },
        { id: "powerprofile", icon: "󰓅", title: "POWER" },
        { id: "battery", icon: "󰁹", title: "BATTERY" },
        { id: "power", icon: "󰐥", title: "SESSION" }
    ]

    readonly property var availableTabs: allTabs.filter(function (t) {
        if (t.id === "bluetooth") return HardwareService.hasBluetooth;
        if (t.id === "battery")   return HardwareService.hasBattery;
        if (t.id === "network")   return HardwareService.hasNetworking;
        return true;
    })

    function getSubmenuTitle(id) {
        if (id === "network") return "NETWORK";
        if (id === "bluetooth") return "BLUETOOTH";
        if (id === "volume") return "SOUND";
        if (id === "powerprofile") return "POWER PROFILE";
        if (id === "battery") return "BATTERY & CHARGING";
        if (id === "power") return "SESSION";
        return "";
    }

    onDismissed: QuickSettingsService.close()

    onShownChanged: {
        if (shown) Qt.callLater(() => mainContent.forceActiveFocus());
    }

    // Outer clicks are dismissed by DismissOverlay; the input mask and the
    // reason a dismiss MouseArea cannot live here are documented in
    // MenuWindow.qml.
    Rectangle {
        id: mainContent
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barMarginTop + Theme.scaled(4)
        anchors.rightMargin: Theme.barMarginRight + (Theme.isSmallScreen ? Theme.scaled(4) : Theme.scaled(8))

        // Production-ready dynamic & adaptive dimensions
        readonly property real maxMenuHeight: Math.min(
            Theme.scaled(580),
            (screen ? screen.height : Theme.screenHeight) - Theme.barHeight - Theme.barMarginTop - Theme.scaled(24)
        )
        readonly property real minMenuHeight: Theme.scaled(240)

        readonly property Item activeTabItem: {
            if (!contentStack || !contentStack.children || contentStack.currentIndex < 0 || contentStack.currentIndex >= contentStack.children.length)
                return null;
            let child = contentStack.children[contentStack.currentIndex];
            return (child && child.item) ? child.item : child;
        }

        readonly property real activeItemHeight: {
            if (!activeTabItem) return Theme.scaled(480);
            let h = activeTabItem.implicitHeight;
            return (h && h > 0) ? h : Theme.scaled(480);
        }

        readonly property real subHeaderHeight: (QuickSettingsService.activeTab !== "main")
            ? (subHeader.height + mainColLayout.spacing)
            : 0

        readonly property real targetHeight: {
            let total = activeItemHeight + subHeaderHeight + Theme.scaled(32);
            return Math.max(minMenuHeight, Math.min(maxMenuHeight, Math.round(total)));
        }

        width: Math.min(Theme.scaled(560), (screen ? screen.width : Theme.screenWidth) - Theme.scaled(20))
        height: targetHeight

        Behavior on height {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }

        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                if (QuickSettingsService.activeTab !== "main") {
                    QuickSettingsService.goBack();
                    event.accepted = true;
                    return;
                } else {
                    QuickSettingsService.close();
                    event.accepted = true;
                    return;
                }
            }
            if (event.key === Qt.Key_Back || event.key === Qt.Key_Backspace) {
                if (QuickSettingsService.activeTab !== "main" && !(typeof wifiContent !== "undefined" && wifiContent.isInputActive)) {
                    QuickSettingsService.goBack();
                    event.accepted = true;
                    return;
                }
            }
            if (QuickSettingsService.activeTab === "power") {
                let pc = powerLoader.item;
                if (pc && typeof pc.handleKeys === 'function') {
                    pc.handleKeys(event);
                    if (event.accepted) return;
                }
            }
            if (QuickSettingsService.activeTab === "network") {
                wifiContent.handleKeys(event);
                if (event.accepted) return;
            }
            let currentContent = contentStack.children[contentStack.currentIndex];
            let targetContent = (currentContent && currentContent.item) ? currentContent.item : currentContent;
            if (targetContent && typeof targetContent.handleKeys === 'function') {
                targetContent.handleKeys(event);
                if (event.accepted) return;
            }
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                if (QuickSettingsService.activeTab !== "main") {
                    let tabs = root.availableTabs.filter(t => t.id !== "main");
                    let idx = tabs.findIndex(t => t.id === QuickSettingsService.activeTab);
                    if (idx !== -1) {
                        let nextIdx = (event.key === Qt.Key_Right) ? (idx + 1) % tabs.length : (idx - 1 + tabs.length) % tabs.length;
                        QuickSettingsService.activeTab = tabs[nextIdx].id;
                        event.accepted = true;
                        return;
                    }
                }
            }
        }

        color: Theme.glassBackground
        radius: Theme.cardRadius
        border.color: Theme.glassBorder
        border.width: 1
        antialiasing: true

        ColumnLayout {
            id: mainColLayout
            anchors.fill: parent
            anchors.margins: Theme.scaled(16)
            spacing: Theme.scaled(12)

            // --- SUB-MENU NAVIGATION HEADER (Shown only when in a sub-menu) ---
            Rectangle {
                id: subHeader
                visible: QuickSettingsService.activeTab !== "main"
                Layout.fillWidth: true
                height: Theme.scaled(38)
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.scaled(8)

                    // ‹ Back Button
                    Rectangle {
                        height: Theme.scaled(32)
                        implicitWidth: backRow.implicitWidth + Theme.scaled(16)
                        radius: Theme.scaled(16)
                        color: backMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                        border.color: Theme.glassBorder
                        border.width: 1
                        antialiasing: true
                        scale: backMouse.pressed ? 0.95 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }

                        RowLayout {
                            id: backRow
                            anchors.centerIn: parent
                            spacing: Theme.scaled(6)

                            Text {
                                text: "‹"
                                font.pixelSize: Theme.scaled(18)
                                font.weight: Font.Black
                                color: Theme.accentColor
                            }

                            Text {
                                text: "Back"
                                font.pixelSize: Theme.scaled(11)
                                font.weight: Font.Bold
                                color: Theme.text
                            }
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: QuickSettingsService.goBack()
                        }
                    }

                    // Submenu Title
                    Text {
                        text: root.getSubmenuTitle(QuickSettingsService.activeTab)
                        font.pixelSize: Theme.scaled(12)
                        font.weight: Font.Black
                        font.letterSpacing: 1.5
                        color: Theme.text
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: Theme.scaled(4)
                    }

                    Item { Layout.fillWidth: true }

                    // Mini Submenu Switcher Icons
                    RowLayout {
                        spacing: Theme.scaled(4)

                        Repeater {
                            model: root.availableTabs.filter(t => t.id !== "main")

                            delegate: Rectangle {
                                width: Theme.scaled(30)
                                height: Theme.scaled(30)
                                radius: Theme.scaled(15)
                                color: QuickSettingsService.activeTab === modelData.id
                                       ? Theme.accentColor
                                       : (miniTabMouse.containsMouse ? Theme.cardBackgroundHover : "transparent")
                                border.width: 0

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(14)
                                    color: QuickSettingsService.activeTab === modelData.id
                                           ? Colors.on_primary
                                           : (miniTabMouse.containsMouse ? Theme.text : Theme.subtext0)
                                }

                                MouseArea {
                                    id: miniTabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: QuickSettingsService.activeTab = modelData.id
                                }
                            }
                        }
                    }
                }
            }

            // --- CONTENT AREA ---
            ScrollView {
                id: scrollArea
                FastWheel {}
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
                    NumberAnimation { target: contentStack; property: "opacity"; from: 0.2; to: 1; duration: Theme.animNormal; easing.type: Easing.OutCubic }
                    NumberAnimation {
                        id: slideAnim
                        target: contentTranslate
                        property: "x"
                        from: 24
                        to: 0
                        duration: Theme.animNormal
                        easing.type: Easing.OutCubic
                    }
                }

                StackLayout {
                    id: contentStack
                    width: scrollArea.availableWidth
                    transform: Translate { id: contentTranslate }
                    height: mainContent.activeItemHeight
                    currentIndex: {
                        var all = root.allTabs.map(function (t) { return t.id; });
                        var active = QuickSettingsService.activeTab || "main";
                        var i = all.indexOf(active);
                        return i >= 0 ? i : 0;
                    }

                    onCurrentIndexChanged: {
                        if (currentIndex === 0) {
                            slideAnim.from = -24;
                        } else {
                            slideAnim.from = 24;
                        }
                        transitionAnim.restart();
                        if (scrollArea.ScrollBar && scrollArea.ScrollBar.vertical) {
                            scrollArea.ScrollBar.vertical.position = 0;
                        }
                    }

                    MainQuickSettings { id: mainQuickSettings }
                    WifiContent { id: wifiContent }

                    Loader {
                        id: btLoader
                        Layout.fillWidth: true
                        property bool hasBeenActive: false
                        active: QuickSettingsService.activeTab === "bluetooth" || hasBeenActive
                        onActiveChanged: if (active) hasBeenActive = true
                        sourceComponent: Component { BluetoothContent { } }
                    }

                    Loader {
                        id: volLoader
                        Layout.fillWidth: true
                        property bool hasBeenActive: false
                        active: QuickSettingsService.activeTab === "volume" || hasBeenActive
                        onActiveChanged: if (active) hasBeenActive = true
                        sourceComponent: Component { VolumeContent { } }
                    }

                    Loader {
                        id: powerProfileLoader
                        Layout.fillWidth: true
                        property bool hasBeenActive: false
                        active: QuickSettingsService.activeTab === "powerprofile" || hasBeenActive
                        onActiveChanged: if (active) hasBeenActive = true
                        sourceComponent: Component { PowerProfileContent { } }
                    }

                    Loader {
                        id: batteryLoader
                        Layout.fillWidth: true
                        property bool hasBeenActive: false
                        active: QuickSettingsService.activeTab === "battery" || hasBeenActive
                        onActiveChanged: if (active) hasBeenActive = true
                        sourceComponent: Component { BatteryContent { } }
                    }

                    Loader {
                        id: powerLoader
                        Layout.fillWidth: true
                        property bool hasBeenActive: false
                        active: QuickSettingsService.activeTab === "power" || hasBeenActive
                        onActiveChanged: if (active) hasBeenActive = true
                        sourceComponent: Component {
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
    }
}
