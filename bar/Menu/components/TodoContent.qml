import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."
import "../../../"

Rectangle {
    id: todoRoot
    color: "transparent"

    readonly property string todoPath: Quickshell.env("HOME") + "/Documents/Task/todo.json"
    property bool isLoaded: false

    function saveTasks() {
        if (!isLoaded) return;
        
        let data = [];
        for (let i = 0; i < todoModel.count; i++) {
            data.push({ task: todoModel.get(i).task, completed: todoModel.get(i).completed });
        }
        
        let jsonStr = JSON.stringify(data);
        
        // FIX: Injecting the raw JSON safely by passing it as a separate shell argument ($1)
        // This avoids messing with deprecating Qt.btoa completely.
        saveProcess.command = [
            "sh", "-c", 
            "mkdir -p $(dirname '" + todoRoot.todoPath + "') && echo \"$1\" > '" + todoRoot.todoPath + ".tmp' && mv '" + todoRoot.todoPath + ".tmp' '" + todoRoot.todoPath + "'",
            "--", 
            jsonStr
        ];
        
        console.log("Running save process for JSON length:", jsonStr.length);
        saveProcess.running = true;
    }

    ListModel { id: todoModel }

    // FIX: Using an explicit Process item for saving to avoid the .exec() type runtime failure
    Process {
        id: saveProcess
        running: false
    }

    // Safely loading tasks via the built-in SplitParser
    Process {
        id: loadProcess
        command: ["sh", "-c", "mkdir -p $(dirname '" + todoRoot.todoPath + "') && (cat '" + todoRoot.todoPath + "' 2>/dev/null || echo '[]')"]
        running: true
        
        stdout: SplitParser {
            onRead: (text) => {
                let output = text.trim();
                if (output === "" || output === "[]") {
                    todoRoot.isLoaded = true;
                    return;
                }
                try {
                    let content = JSON.parse(output);
                    todoModel.clear();
                    for (let item of content) {
                        todoModel.append(item);
                    }
                } catch (e) {
                    console.log("Failed to parse todo JSON:", e, "Raw output:", output);
                }
                todoRoot.isLoaded = true;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 10

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Tasks"; color: Theme.text; font.weight: Font.Bold; font.pixelSize: 14 }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 28; height: 28; radius: 6; color: Theme.surface1
                Text { anchors.centerIn: parent; text: "󰐕"; font.family: Theme.iconFont; color: Theme.blue }
                MouseArea { 
                    anchors.fill: parent
                    onClicked: { 
                        inputField.text = "";
                        inputField.visible = true;
                        inputField.forceActiveFocus();
                    } 
                }
            }
        }

        // Add Input
        TextArea {
            id: inputField
            visible: false
            Layout.fillWidth: true; Layout.preferredHeight: contentHeight + 20
            background: Rectangle { radius: 8; color: Theme.glassBackground; border.color: Theme.blue }
            color: Theme.text; padding: 10
            wrapMode: TextArea.Wrap
            verticalAlignment: TextInput.AlignTop
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    if (event.modifiers & Qt.ShiftModifier) {
                        return;
                    } else if (text.trim() !== "") {
                        console.log("Adding task to model:", text.trim());
                        todoModel.append({ "task": text.trim(), "completed": false });
                        inputField.text = ""; 
                        inputField.visible = false; 
                        saveTasks();
                        event.accepted = true;
                    } else {
                        event.accepted = true;
                    }
                }
            }
            onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
        }

        // List
        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true
            model: todoModel; clip: true; spacing: 8
            delegate: Rectangle {
                width: ListView.view.width; height: contentCol.height + 16
                radius: 8; color: Theme.glassBackground
                ColumnLayout {
                    id: contentCol
                    width: parent.width - 16; anchors.margins: 8; x: 8; y: 8
                    RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 20; height: 20; radius: 4; color: model.completed ? Theme.blue : Theme.surface1
                            Text { anchors.centerIn: parent; text: model.completed ? "✓" : ""; color: Theme.base; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; onClicked: { model.completed = !model.completed; saveTasks(); } }
                        }
                        Text { 
                            text: model.task; Layout.fillWidth: true
                            color: model.completed ? Theme.surface2 : Theme.text
                            font.strikeout: model.completed
                            wrapMode: Text.WordWrap
                        }
                        Text { 
                            text: "󰏫"; font.family: Theme.iconFont; color: Theme.blue
                            MouseArea { anchors.fill: parent; onClicked: { inputField.text = model.task; inputField.visible = true; todoModel.remove(index); } }
                        }
                        Text { 
                            text: "󰆴"; font.family: Theme.iconFont; color: Theme.powerRed
                            MouseArea { anchors.fill: parent; onClicked: { todoModel.remove(index); saveTasks(); } }
                        }
                    }
                }
            }
        }
    }
}