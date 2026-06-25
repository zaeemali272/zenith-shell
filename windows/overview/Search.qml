import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../" as Root

Rectangle {
    id: root
    
    signal queryChanged(string query)
    signal requestCalculation(string expression)
    
    // Explicit signal conduits for layout driving
    signal navigateRequested(string direction)
    signal selectRequested()

    property alias text: input.text
    property string calcResult: ""
    
    function setCalcResult(result) {
        calcResult = result;
    }
    
    width: Root.Theme.scaled ? Root.Theme.scaled(500) : 500
    height: Root.Theme.scaled ? Root.Theme.scaled(40) : 40
    radius: height / 2
    color: Root.Theme.mantle || "#a1232323"
    border.color: input.activeFocus ? (Root.Theme.mauve || '#a1585858') : (Root.Theme.surface0 || "#a6010101")
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Root.Theme.scaled ? Root.Theme.scaled(15) : 15
        anchors.rightMargin: Root.Theme.scaled ? Root.Theme.scaled(15) : 15
        spacing: Root.Theme.scaled ? Root.Theme.scaled(10) : 10

        Text {
            text: "󰍉"
            font.family: Root.Theme.iconFont || "monospace"
            font.pixelSize: Root.Theme.scaled ? Root.Theme.scaled(16) : 16
            color: input.activeFocus ? (Root.Theme.mauve || "#cba6f7") : (Root.Theme.subtext0 || "#a6adc8")
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
                text: "Search..."
                color: Root.Theme.surface2 || "#585b70"
                font.pixelSize: parent.font.pixelSize
                visible: !parent.text && !parent.activeFocus
            }

            onTextChanged: {
                root.queryChanged(text);
                root.requestCalculation(text);
            }
            
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    if (text !== "") {
                        text = "";
                        event.accepted = true;
                    } else {
                        let p = root.parent;
                        while (p) {
                            if (p.hasOwnProperty("active")) {
                                p.active = false;
                                break;
                            }
                            p = p.parent;
                        }
                    }
                } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    root.selectRequested();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right) {
                    root.navigateRequested("right");
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                    root.navigateRequested("left");
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    root.navigateRequested("down");
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    root.navigateRequested("up");
                    event.accepted = true;
                }
            }
        }
        
        Text {
            text: root.calcResult
            color: Root.Theme.subtext0 || "#a6adc8"
            font.pixelSize: Root.Theme.scaled ? Root.Theme.scaled(14) : 14
            visible: root.calcResult !== ""
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