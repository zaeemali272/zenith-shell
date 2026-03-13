import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: todoRoot

    // --- Persistence Logic ---
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

    implicitHeight: 250
    color: "transparent"

    Process {
        id: saveProcess
    }

    Process {
        id: loadProcess

        command: ["cat", todoRoot.todoPath]
        running: true
        onStdoutChanged: {
            let content = stdout.toString();
            todoModel.clear();
            if (!content)
                return ;

            let lines = content.split("\n");
            for (let line of lines) {
                if (line.trim() === "")
                    continue;

                let completed = line.startsWith("[x]");
                let task = line.substring(4).trim();
                todoModel.append({
                    "task": task,
                    "completed": completed
                });
            }
        }
    }

    // --- FIX 4: The Focus Timer (From WifiMenu) ---
    Timer {
        id: focusTimer

        interval: 50
        onTriggered: {
            if (inputField.visible)
                inputField.forceActiveFocus();

        }
    }

    ListModel {
        id: todoModel
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "To-Do"
                color: "#cdd6f4"
                font.bold: true
                font.pixelSize: 16
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "󰐕"
                color: "#a6e3a1"
                font.pixelSize: 20

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        inputField.visible = true;
                        focusTimer.start(); // Trigger the grab
                    }
                }

            }

        }

        TextField {
            id: inputField

            visible: false
            Layout.fillWidth: true
            placeholderText: "New task..."
            color: "#cdd6f4"
            focus: true
            onAccepted: {
                if (text !== "") {
                    todoModel.append({
                        "task": text,
                        "completed": false
                    });
                    text = "";
                    visible = false;
                    saveTasks();
                }
            }

            background: Rectangle {
                color: "#111111"
                radius: 4
                border.color: "#313244"
                border.width: 1
            }

        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: todoModel
            spacing: 8

            delegate: RowLayout {
                width: parent.width
                spacing: 10

                CheckBox {
                    checked: model.completed
                    onToggled: {
                        model.completed = checked;
                        saveTasks();
                    }
                }

                TextInput {
                    text: model.task
                    Layout.fillWidth: true
                    color: model.completed ? "#585b70" : "#cdd6f4"
                    selectByMouse: true
                    onAccepted: {
                        model.task = text;
                        focus = false;
                        saveTasks();
                    }
                }

                Text {
                    text: "󰅖"
                    color: "#f38ba8"
                    font.pixelSize: 16

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            todoModel.remove(index);
                            saveTasks();
                        }
                    }

                }

            }

        }

    }

}
