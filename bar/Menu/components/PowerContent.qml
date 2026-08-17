import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."

ColumnLayout {
    id: root
    spacing: Theme.scaled(25)
    Layout.fillWidth: true
    focus: true
    
    function handleKeys(event) {
        let cols = 2;
        let maxIdx = powerButtons.count - 1;
        if (event.key === Qt.Key_Right) {
            root.selectedIndex = Math.min(root.selectedIndex + 1, maxIdx);
        }
        else if (event.key === Qt.Key_Left) {
            root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
        }
        else if (event.key === Qt.Key_Down) {
            root.selectedIndex = Math.min(root.selectedIndex + cols, maxIdx);
        }
        else if (event.key === Qt.Key_Up) {
            root.selectedIndex = Math.max(root.selectedIndex - cols, 0);
        }
        else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            let modelData = powerButtons.model[root.selectedIndex];
            if (modelData) {
                let cmd = modelData.cmd;
                powerProc.command = ["sh", "-c", cmd];
                powerProc.running = true;
            }
        }
    }
    
    // Explicit sizing for ScrollView integration
    implicitHeight: mainLayout.implicitHeight

    // Index 0 is LOCK. This used to default to 5 -- SHUTDOWN -- and was reset
    // to it every time the panel opened. Because the panel calls
    // forceActiveFocus() on open and Enter activates the selection, opening
    // the session menu and pressing Enter powered the machine off.
    readonly property int defaultIndex: 0
    property int selectedIndex: defaultIndex

    // Reset selection every time the menu is opened
    onVisibleChanged: {
        if (visible) {
            selectedIndex = defaultIndex;
            root.forceActiveFocus();
        }
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        spacing: Theme.scaled(25)
        
        // ... (existing content)


        Text {
            text: "SESSION"
            color: Theme.blue
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 2
            Layout.leftMargin: Theme.scaled(5)
        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            rowSpacing: Theme.scaled(12)
            columnSpacing: Theme.scaled(12)

            Repeater {
                id: powerButtons
                // Same reason as PowerProfileContent: a Theme.* value inside the model
                // array makes the array itself a palette binding, so a recolour
                // destroys and rebuilds every delegate. Resolved per delegate below.
                model: [
                    { icon: "󰌾", label: "LOCK",     cmd: "hyprlock --immediate-render --no-fade-in" },
                    { icon: "󰒲", label: "BIOS",     cmd: "systemctl reboot --firmware-setup" },
                    { icon: "󰗼", label: "LOGOUT",   cmd: "hyprctl dispatch exit" },
                    { icon: "󰤄", label: "SUSPEND",  cmd: "systemctl suspend" },
                    { icon: "󰑐", label: "REBOOT",   cmd: "reboot" },
                    { icon: "󰐥", label: "SHUTDOWN", cmd: "shutdown now" }
                ]

                delegate: Rectangle {
                    id: powerBtn

                    readonly property color accent: modelData.label === "LOGOUT"   ? Theme.powerGreen
                                                  : modelData.label === "REBOOT"   ? Theme.blue
                                                  : modelData.label === "SHUTDOWN" ? Theme.powerRed
                                                  : modelData.label === "BIOS"     ? Theme.mauve
                                                  : Theme.lavender

                    Layout.fillWidth: true
                    height: Theme.scaled(100)
                    anchors.margins: 2 
                    
                    property bool isSelected: index === root.selectedIndex
                    
                    color: isSelected ? Qt.rgba(1,1,1,0.1) : (m.containsMouse ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0,0,0,0.2))
                    radius: Theme.scaled(20)
                    border.color: isSelected ? powerBtn.accent : (m.containsMouse ? powerBtn.accent : Theme.glassBorder)
                    border.width: 1
                    
                    scale: m.pressed ? 0.92 : (isSelected || m.containsMouse ? 1.00 : 0.95)
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    MouseArea {
                        id: m
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: root.selectedIndex = index
                        onClicked: { powerProc.command = ["sh", "-c", modelData.cmd]; powerProc.running = true; }
                    }

                    RowLayout {
                        anchors.centerIn: parent; spacing: 15
                        Rectangle {
                            width: 44; height: 44; radius: 12; color: Qt.rgba(powerBtn.accent.r, powerBtn.accent.g, powerBtn.accent.b, 0.1)
                            Text { anchors.centerIn: parent; text: modelData.icon; font.family: Theme.iconFont; font.pixelSize: 22; color: powerBtn.accent }
                        }
                        Text { text: modelData.label; font.pixelSize: 11; font.weight: Font.Black; color: Theme.text; opacity: 0.8 }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }

    Process { id: powerProc }
}
