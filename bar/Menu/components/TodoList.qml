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

    readonly property string todoPath: Quickshell.env("HOME") + "/.config/quickshell/todo.txt"

    function saveTasks() {
        let data = "";
        for (let i = 0; i < todoModel.count; i++) {
            let item = todoModel.get(i);
            data += (item.completed ? "[x] " : "[ ] ") + item.task + "\n";
        }
        saveProcess.command = ["sh", "-c", "printf '%s' " + Quickshell.quote(data) + " > " + todoRoot.todoPath];
        saveProcess.running = true;
    }

    ListModel { id: todoModel }
    Process { id: saveProcess }
    Process {
        id: loadProcess
        command: ["cat", todoRoot.todoPath]
        running: true
        onStdoutChanged: {
            let content = stdout.toString();
            todoModel.clear();
            if (!content) return;
            let lines = content.split("\n");
            for (let line of lines) {
                if (line.trim() === "") continue;
                let completed = line.startsWith("[x]");
                let task = line.substring(4).trim();
                todoModel.append({ "task": task, "completed": completed });
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
                        inputFieldContainer.visible = true;
                        inputField.visible = true;
                        inputField.forceActiveFocus();
                    } 
                }
            }

        }

        // Add Input
        Rectangle {
            id: inputFieldContainer
            visible: inputField.visible
            Layout.fillWidth: true; height: 40; radius: 8; color: Theme.glassBackground; border.color: Theme.blue
            TextInput {
                id: inputField
                anchors.fill: parent; anchors.margins: 10
                color: Theme.text; verticalAlignment: TextInput.AlignVCenter
                onAccepted: {
                    if (text !== "") {
                        todoModel.append({ "task": text, "completed": false });
                        text = ""; visible = false; saveTasks();
                    }
                }
                Keys.onEscapePressed: visible = false
            }
        }

        // List
        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true
            model: todoModel; clip: true; spacing: 8
            delegate: Rectangle {
                width: ListView.view.width; height: 45
                radius: 8; color: Theme.glassBackground
                RowLayout {
                    anchors.fill: parent; anchors.margins: 8
                    Rectangle {
                        width: 20; height: 20; radius: 4; color: model.completed ? Theme.blue : Theme.surface1
                        MouseArea { anchors.fill: parent; onClicked: { model.completed = !model.completed; saveTasks(); } }
                    }
                    TextInput {
                        text: model.task; Layout.fillWidth: true; color: model.completed ? Theme.surface2 : Theme.text
                        onAccepted: { model.task = text; saveTasks(); }
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
