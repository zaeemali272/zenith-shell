import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../" as Root

Rectangle {
    id: root
    
    signal queryChanged(string query)
    property alias text: input.text
    
    width: Root.Theme.scaled ? Root.Theme.scaled(500) : 500
    height: Root.Theme.scaled ? Root.Theme.scaled(50) : 50
    radius: height / 2
    color: Root.Theme.mantle || "#181825"
    border.color: input.activeFocus ? (Root.Theme.mauve || "#cba6f7") : (Root.Theme.surface0 || "#313244")
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: 200 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Root.Theme.scaled ? Root.Theme.scaled(20) : 20
        anchors.rightMargin: Root.Theme.scaled ? Root.Theme.scaled(20) : 20
        spacing: Root.Theme.scaled ? Root.Theme.scaled(15) : 15

        Text {
            text: "󰍉"
            font.family: Root.Theme.iconFont || "monospace"
            font.pixelSize: Root.Theme.scaled ? Root.Theme.scaled(20) : 20
            color: input.activeFocus ? (Root.Theme.mauve || "#cba6f7") : (Root.Theme.subtext0 || "#a6adc8")

            Behavior on color { ColorAnimation { duration: 200 } }
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            color: Root.Theme.text || "#cdd6f4"
            font.pixelSize: Root.Theme.scaled ? Root.Theme.scaled(18) : 18
            selectionColor: Root.Theme.mauve || "#cba6f7"
            selectedTextColor: Root.Theme.crust || "#11111b"
            cursorVisible: true

            Text {
                text: "Search applications..."
                color: Root.Theme.surface2 || "#585b70"
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
                        // find active property in parents
                        let p = root.parent;
                        while (p) {
                            if (p.hasOwnProperty("active")) {
                                p.active = false;
                                break;
                            }
                            p = p.parent;
                        }
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
            font.family: Root.Theme.iconFont || "monospace"
            font.pixelSize: Root.Theme.scaled ? Root.Theme.scaled(18) : 18
            color: Root.Theme.surface2 || "#585b70"
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
