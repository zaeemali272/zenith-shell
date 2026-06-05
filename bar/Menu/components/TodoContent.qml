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
    property int activeTabIndex: 0
    property var todoData: [] // Central source of truth
    property int editingIndex: -1 // Track which task is being edited

    function cancelEdit() {
        editingIndex = -1;
        inputField.visible = false;
        inputField.text = "";
    }

    // Auto-close input fields when menu is hidden without losing data
    onVisibleChanged: {
        if (!visible) {
            cancelEdit();
            tabNameInputContainer.visible = false;
        }
    }

    function updateModels() {
        tabsModel.clear();
        for (let i = 0; i < todoData.length; i++) {
            tabsModel.append({ name: todoData[i].name });
        }

        tasksModel.clear();
        if (activeTabIndex >= 0 && activeTabIndex < todoData.length) {
            let tasks = todoData[activeTabIndex].tasks;
            for (let i = 0; i < tasks.length; i++) {
                tasksModel.append(tasks[i]);
            }
        }
    }

    function syncCurrentTasks() {
        if (!isLoaded || activeTabIndex < 0 || activeTabIndex >= todoData.length) return;
        
        let currentTasks = [];
        for (let i = 0; i < tasksModel.count; i++) {
            currentTasks.push({ 
                task: tasksModel.get(i).task, 
                completed: tasksModel.get(i).completed 
            });
        }
        todoData[activeTabIndex].tasks = currentTasks;
    }

    function saveTasks() {
        if (!isLoaded) return;
        syncCurrentTasks();

        let jsonStr = JSON.stringify(todoData);
        saveProcess.command = [
            "sh", "-c", 
            "mkdir -p $(dirname '" + todoRoot.todoPath + "') && echo \"$1\" > '" + todoRoot.todoPath + ".tmp' && mv '" + todoRoot.todoPath + ".tmp' '" + todoRoot.todoPath + "'",
            "--", 
            jsonStr
        ];
        saveProcess.running = true;
    }

    function switchTab(index) {
        if (index === activeTabIndex) return;
        syncCurrentTasks();
        activeTabIndex = index;
        cancelEdit();
        
        tasksModel.clear();
        if (activeTabIndex >= 0 && activeTabIndex < todoData.length) {
            let tasks = todoData[activeTabIndex].tasks;
            for (let i = 0; i < tasks.length; i++) {
                tasksModel.append(tasks[i]);
            }
        }
    }

    function addTab(name) {
        syncCurrentTasks();
        todoData.push({ name: name, tasks: [] });
        activeTabIndex = todoData.length - 1;
        updateModels();
        saveTasks();
    }

    ListModel { id: tabsModel }
    ListModel { id: tasksModel }

    Process { id: saveProcess; running: false }
    Process {
        id: loadProcess
        command: ["sh", "-c", "mkdir -p $(dirname '" + todoRoot.todoPath + "') && (cat '" + todoRoot.todoPath + "' 2>/dev/null || echo '[]')"]
        running: true
        stdout: SplitParser {
            onRead: (text) => {
                let output = text.trim();
                if (output === "" || output === "[]") {
                    todoData = [{ name: "General", tasks: [] }];
                    todoRoot.isLoaded = true;
                    updateModels();
                    return;
                }
                try {
                    let content = JSON.parse(output);
                    if (Array.isArray(content)) {
                        if (content.length > 0 && content[0].tasks === undefined) {
                            todoData = [{ name: "General", tasks: content }];
                        } else {
                            todoData = content;
                        }
                    }
                } catch (e) {
                    todoData = [{ name: "General", tasks: [] }];
                }
                if (todoData.length === 0) todoData = [{ name: "General", tasks: [] }];
                activeTabIndex = 0;
                todoRoot.isLoaded = true;
                updateModels();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 10

        // Section Tabs
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                contentWidth: tabsRow.width
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                
                Row {
                    id: tabsRow
                    spacing: 8
                    Repeater {
                        model: tabsModel
                        delegate: Rectangle {
                            width: Math.max(50, tabText.implicitWidth + 20); height: 28; radius: 14
                            color: activeTabIndex === index ? Theme.mauve : "transparent"
                            border.color: activeTabIndex === index ? "transparent" : Theme.surface2
                            border.width: 1
                            
                            Text {
                                id: tabText
                                anchors.centerIn: parent
                                text: model.name
                                color: activeTabIndex === index ? Theme.base : Theme.surface2
                                font.pixelSize: 11; font.weight: activeTabIndex === index ? Font.Bold : Font.Normal
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: switchTab(index)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: 28; height: 28; radius: 14; color: "transparent"; border.color: Theme.mauve; border.width: 1
                Text { anchors.centerIn: parent; text: "󰐕"; font.family: Theme.iconFont; color: Theme.mauve; font.pixelSize: 12 }
                MouseArea { 
                    anchors.fill: parent
                    onClicked: { 
                        tabNameInput.text = ""; 
                        tabNameInputContainer.visible = !tabNameInputContainer.visible;
                        if (tabNameInputContainer.visible) tabNameInput.forceActiveFocus();
                    } 
                }
            }

            Rectangle {
                width: 28; height: 28; radius: 14; color: "transparent"; border.color: Theme.powerRed; border.width: 1
                visible: todoData.length > 1
                Text { anchors.centerIn: parent; text: "󰆴"; font.family: Theme.iconFont; color: Theme.powerRed; font.pixelSize: 12 }
                MouseArea { 
                    anchors.fill: parent
                    onClicked: {
                        if (todoData.length > 1) {
                            todoData.splice(activeTabIndex, 1);
                            if (activeTabIndex >= todoData.length) activeTabIndex = todoData.length - 1;
                            updateModels();
                            saveTasks();
                        }
                    }
                }
            }
        }

        // Tab Name Input
        Rectangle {
            id: tabNameInputContainer
            visible: false
            Layout.fillWidth: true; Layout.preferredHeight: 32
            radius: 8; color: Theme.glassBackground; border.color: Theme.mauve
            TextInput {
                id: tabNameInput
                anchors.fill: parent; anchors.margins: 6
                color: Theme.text; font.pixelSize: 13
                verticalAlignment: TextInput.AlignVCenter
                Text {
                    text: "Tab Name..."; color: Theme.surface2; font.pixelSize: 13
                    visible: !parent.text && !parent.activeFocus; verticalAlignment: Text.AlignVCenter
                }
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        if (text.trim() !== "") {
                            addTab(text.trim());
                            text = ""; tabNameInputContainer.visible = false;
                            event.accepted = true;
                        }
                    } else if (event.key === Qt.Key_Escape) {
                        tabNameInputContainer.visible = false;
                        event.accepted = true;
                    }
                }
            }
        }

        // Add Task Header
        RowLayout {
            Layout.fillWidth: true
            Text { 
                text: (activeTabIndex >= 0 && activeTabIndex < todoData.length) ? todoData[activeTabIndex].name : "Tasks"
                color: Theme.text; font.weight: Font.Bold; font.pixelSize: 14 
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 24; height: 24; radius: 6; color: Theme.surface1
                Text { anchors.centerIn: parent; text: "󰐕"; font.family: Theme.iconFont; color: Theme.blue }
                MouseArea { 
                    anchors.fill: parent
                    onClicked: { 
                        todoRoot.cancelEdit();
                        inputField.text = ""; 
                        inputField.visible = true; 
                        inputField.forceActiveFocus(); 
                    } 
                }
            }
        }

        // Add/Edit Task Input
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
                    if (event.modifiers & Qt.ShiftModifier) return;
                    if (text.trim() !== "") {
                        if (todoRoot.editingIndex !== -1) {
                            tasksModel.setProperty(todoRoot.editingIndex, "task", text.trim());
                            todoRoot.editingIndex = -1;
                        } else {
                            tasksModel.append({ "task": text.trim(), "completed": false });
                        }
                        inputField.text = ""; inputField.visible = false; 
                        saveTasks();
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Escape) {
                    todoRoot.cancelEdit();
                    event.accepted = true;
                }
            }
        }

        // Tasks List
        ListView {
            id: taskListView
            Layout.fillWidth: true; Layout.fillHeight: true
            model: tasksModel; clip: true; spacing: 8
            
            displaced: Transition {
                NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutQuad }
            }

            delegate: Item {
                id: delegateRoot
                width: taskListView.width; height: visible ? contentCol.height + 16 : 0
                z: dragArea.held ? 100 : 1
                visible: todoRoot.editingIndex !== index

                Rectangle {
                    id: visualContent
                    anchors.fill: parent; radius: 8; color: Theme.glassBackground
                    y: 0
                    
                    ColumnLayout {
                        id: contentCol
                        width: parent.width - 16; anchors.margins: 8; x: 8; y: 8
                        RowLayout {
                            spacing: 8
                            
                            // Drag Handle
                            Text {
                                text: ": :"; font.family: Theme.iconFont; color: Theme.surface2; font.pixelSize: 16
                                MouseArea {
                                    id: dragArea
                                    anchors.fill: parent
                                    property bool held: false
                                    preventStealing: true
                                    
                                    onPressed: held = true
                                    onReleased: {
                                        held = false;
                                        visualContent.y = 0;
                                        saveTasks();
                                    }
                                    
                                    onPositionChanged: (mouse) => {
                                        if (held) {
                                            // Get point relative to the content area (scrollable area)
                                            let pointInContent = taskListView.contentItem.mapFromItem(dragArea, mouse.x, mouse.y);
                                            let itemHeight = delegateRoot.height + taskListView.spacing;
                                            let targetIndex = Math.floor(pointInContent.y / itemHeight);
                                            
                                            // Ensure within bounds
                                            targetIndex = Math.max(0, Math.min(targetIndex, tasksModel.count - 1));
                                            
                                            if (targetIndex !== index) {
                                                tasksModel.move(index, targetIndex, 1);
                                            }
                                            
                                            // Follow mouse feedback (relative to stable delegate root)
                                            let pointInDelegate = delegateRoot.mapFromItem(dragArea, mouse.x, mouse.y);
                                            visualContent.y = pointInDelegate.y - height / 2;
                                        }
                                    }
                                }
                            }

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
                                MouseArea { 
                                    anchors.fill: parent; 
                                    onClicked: { 
                                        todoRoot.editingIndex = index;
                                        inputField.text = model.task;
                                        inputField.visible = true; 
                                        inputField.forceActiveFocus();
                                        inputField.cursorPosition = inputField.text.length;
                                    } 
                                }
                            }
                            
                            Text { 
                                text: "󰆴"; font.family: Theme.iconFont; color: Theme.powerRed
                                MouseArea { anchors.fill: parent; onClicked: { tasksModel.remove(index); saveTasks(); } }
                            }
                        }
                    }
                }
            }
        }
    }
}
