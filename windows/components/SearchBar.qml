import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." as Root

Rectangle {
    id: root
    
    signal queryChanged(string query)
    property alias text: input.text
    
    // Provide a safe default for scaled values if Theme isn't ready
    readonly property real s: (Root.Theme && Root.Theme.scaled) ? Root.Theme.scaled(1) : 1
    
    width: 500 * s
    height: 50 * s
    radius: 25 * s
    color: (Root.Theme && Root.Theme.mantle) ? Root.Theme.mantle : "#181825"
    border.color: input.activeFocus ? (Root.Theme && Root.Theme.mauve ? Root.Theme.mauve : "#cba6f7") : (Root.Theme && Root.Theme.surface0 ? Root.Theme.surface0 : "#313244")
    border.width: 1
    
    Behavior on border.color { ColorAnimation { duration: 200 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20 * s
        anchors.rightMargin: 20 * s
        spacing: 15 * s

        Text {
            text: "󰍉"
            font.family: (Root.Theme && Root.Theme.iconFont) ? Root.Theme.iconFont : "monospace"
            font.pixelSize: 20 * s
            color: input.activeFocus ? (Root.Theme && Root.Theme.mauve ? Root.Theme.mauve : "#cba6f7") : (Root.Theme && Root.Theme.subtext0 ? Root.Theme.subtext0 : "#a6adc8")
            
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            color: (Root.Theme && Root.Theme.text) ? Root.Theme.text : "#cdd6f4"
            font.pixelSize: 18 * s
            selectionColor: (Root.Theme && Root.Theme.mauve) ? Root.Theme.mauve : "#cba6f7"
            selectedTextColor: (Root.Theme && Root.Theme.crust) ? Root.Theme.crust : "#11111b"
            cursorVisible: true
            
            Text {
                text: "Search applications..."
                color: (Root.Theme && Root.Theme.surface2) ? Root.Theme.surface2 : "#585b70"
                font.pixelSize: parent.font.pixelSize
                visible: !parent.text && !parent.activeFocus
            }
            
            onTextChanged: root.queryChanged(text)
            
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    if (text !== "") {
                        text = "";
                        event.accepted = true;
                    } else {
                        win.active = false;
                    }
                } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Right || event.key === Qt.Key_Left) {
                    appMenu.focus = true;
                    appMenu.Keys.pressed(event);
                    event.accepted = true;
                }
            }
        }
        
        Text {
            text: "󰅖"
            font.family: (Root.Theme && Root.Theme.iconFont) ? Root.Theme.iconFont : "monospace"
            font.pixelSize: 18 * s
            color: (Root.Theme && Root.Theme.surface2) ? Root.Theme.surface2 : "#585b70"
            visible: input.text !== ""
            
            MouseArea {
                anchors.fill: parent
                onClicked: input.text = ""
            }
        }
    }
    
    function forceFocus() {
        input.forceActiveFocus();
    }
}
