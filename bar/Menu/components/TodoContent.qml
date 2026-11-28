import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."
import "../../../"
import "../../../services"

Rectangle {
    id: todoRoot
    color: "transparent"

    readonly property string todoPath: Quickshell.env("HOME") + "/Documents/Task/todo.json"
    property bool isLoaded: false
    property int activeTabIndex: 0
    property var todoData: [] // Central source of truth
    property int editingIndex: -1 // Track which task is being edited
    property int selectedIndex: 0
    property string filterMode: "all" // "all" | "active" | "done"
    property string searchQuery: ""
    property bool searchOpen: false

    readonly property int completedCount: {
        let c = 0;
        for (let i = 0; i < tasksModel.count; i++) {
            if (tasksModel.get(i).completed) c++;
        }
        return c;
    }

    function rowMatchesFilter(row) {
        if (!row) return false;
        if (filterMode === "active" && row.completed) return false;
        if (filterMode === "done" && !row.completed) return false;
        let q = searchQuery.trim().toLowerCase();
        if (q !== "" && !String(row.task || "").toLowerCase().includes(q)) return false;
        return true;
    }

    function clearCompleted() {
        let removed = false;
        for (let i = tasksModel.count - 1; i >= 0; i--) {
            let row = tasksModel.get(i);
            if (row && row.completed) {
                tombstoneTask(row);
                tasksModel.remove(i);
                removed = true;
            }
        }
        if (removed) saveTasks();
    }

    function handleKeys(event) {
        if (editingIndex !== -1 || inputField.activeFocus || tabNameInputContainer.visible || keyInputRow.visible || taskSearchInput.activeFocus) return;
        let count = tasksModel.count;
        if (event.key === Qt.Key_Slash) {
            searchOpen = true;
            Qt.callLater(() => taskSearchInput.forceActiveFocus());
            event.accepted = true;
            return;
        }
        if (count === 0) return;

        if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            selectedIndex = Math.min(count - 1, selectedIndex + 1);
            taskListView.positionViewAtIndex(selectedIndex, ListView.Contain);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            selectedIndex = Math.max(0, selectedIndex - 1);
            taskListView.positionViewAtIndex(selectedIndex, ListView.Contain);
            event.accepted = true;
        } else if (event.key === Qt.Key_Space) {
            if (selectedIndex >= 0 && selectedIndex < count) {
                let currentItem = tasksModel.get(selectedIndex);
                let newCompleted = !currentItem.completed;
                tasksModel.setProperty(selectedIndex, "completed", newCompleted);
                tasksModel.setProperty(selectedIndex, "dirty", true);
                saveTasks();
                event.accepted = true;
            }
        }
    }

    property bool reloadPending: false

    function cancelEdit() {
        editingIndex = -1;
        inputField.text = "";
        inputField.focus = false;
        if (reloadPending) reloadTasks();
    }

    // Re-reading mid-edit would clear the model out from under the text field,
    // so a reload that lands while the user is typing waits for them to finish.
    function reloadTasks() {
        if (editingIndex !== -1 || inputField.activeFocus) { reloadPending = true; return; }
        reloadPending = false;
        loadProcess.running = false;
        loadProcess.running = true;
    }

    // The task file is read the first time the tab is shown, not at shell
    // start: nothing can look at the list before then.
    property bool started: false

    function startIfNeeded() {
        if (started || !visible) return;
        started = true;
        loadProcess.running = true;
    }

    Component.onCompleted: startIfNeeded()

    // Auto-close input fields when menu is hidden without losing data
    onVisibleChanged: {
        if (!visible) {
            cancelEdit();
            tabNameInputContainer.visible = false;
        } else {
            startIfNeeded();
            if (TodoistService.hasToken) {
                // Pull anything added from the phone or web app since last time.
                TodoistService.syncNow();
            }
        }
    }

    Connections {
        target: TodoistService
        // The sync script rewrites todo.json in place, so re-read it rather
        // than keeping the stale in-memory copy.
        function onTasksChanged() {
            todoRoot.reloadTasks();
        }
    }

    // Every row carries the same four roles, always. A ListModel fixes its
    // roles from the first item appended, so a task added here (no Todoist link
    // yet) landing first would leave todoist_id unreadable on every row after
    // it -- silently breaking the link between the two sides.
    function fillTasksModel() {
        tasksModel.clear();
        if (activeTabIndex < 0 || activeTabIndex >= todoData.length) return;
        let tasks = todoData[activeTabIndex].tasks || [];
        for (let i = 0; i < tasks.length; i++) {
            if (tasks[i].deleted) continue; // tombstone: awaiting push, not shown
            tasksModel.append({
                task: String(tasks[i].task || ""),
                completed: !!tasks[i].completed,
                todoist_id: String(tasks[i].todoist_id || ""),
                dirty: !!tasks[i].dirty
            });
        }
    }

    function updateModels() {
        tabsModel.clear();
        for (let i = 0; i < todoData.length; i++) {
            tabsModel.append({ name: todoData[i].name });
        }
        fillTasksModel();
    }

    function syncCurrentTasks() {
        if (!isLoaded || activeTabIndex < 0 || activeTabIndex >= todoData.length) return;

        let currentTasks = [];
        for (let i = 0; i < tasksModel.count; i++) {
            let row = tasksModel.get(i);
            let entry = { task: row.task, completed: row.completed, deleted: false };
            // Carrying todoist_id through is what keeps a task the *same* task.
            // Rebuilding rows as bare {task, completed} dropped it, so the next
            // sync read every task as newly created and pushed a duplicate of
            // the entire tab.
            if (row.todoist_id) entry.todoist_id = String(row.todoist_id);
            if (row.dirty) entry.dirty = true;
            currentTasks.push(entry);
        }

        // Tombstones are deliberately absent from the model -- they must not
        // appear in the list -- but they still have to reach the sync so the
        // deletion gets replayed to Todoist.
        let previous = todoData[activeTabIndex].tasks || [];
        for (let j = 0; j < previous.length; j++) {
            if (previous[j].deleted) currentTasks.push(previous[j]);
        }

        todoData[activeTabIndex].tasks = currentTasks;
    }

    // Record a deletion rather than just forgetting the task: with no tombstone
    // the next pull finds it still alive on Todoist and brings it right back.
    function tombstoneTask(row) {
        if (!row || String(row.todoist_id || "") === "") return;
        todoData[activeTabIndex].tasks.push({
            task: String(row.task || ""),
            completed: !!row.completed,
            todoist_id: String(row.todoist_id),
            deleted: true
        });
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
        pushTimer.restart();
    }

    function switchTab(index) {
        if (index === activeTabIndex) return;
        syncCurrentTasks();
        activeTabIndex = index;
        cancelEdit();
        
        fillTasksModel();
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
        // Loaded when the tab is first shown rather than at shell start.
        running: false
        // StdioCollector, not SplitParser: SplitParser delivers one *line* per
        // callback, so as soon as the file was written pretty-printed (which
        // the sync script does, to keep it readable) the first callback got
        // "[", JSON.parse threw, and the list fell back to an empty "General"
        // tab -- the whole task list gone from the UI while intact on disk.
        stdout: StdioCollector {
            onStreamFinished: {
                let output = String(text).trim();
                let parsed = null;

                if (output !== "" && output !== "[]") {
                    try {
                        let content = JSON.parse(output);
                        if (Array.isArray(content) && content.length > 0) {
                            parsed = (content[0].tasks === undefined)
                                   ? [{ name: "General", tasks: content }] // legacy flat file
                                   : content;
                        }
                    } catch (e) {
                        // Keep what is already on screen rather than replacing
                        // it with an empty list: a truncated or corrupt file
                        // must never render as "you have no tasks".
                        if (todoRoot.isLoaded) return;
                    }
                }

                // Hold the user's place across a sync-triggered reload.
                let previousTab = (todoRoot.isLoaded && activeTabIndex >= 0
                                   && activeTabIndex < todoData.length)
                                ? todoData[activeTabIndex].name : "";

                todoData = parsed || [{ name: "General", tasks: [] }];

                activeTabIndex = 0;
                if (previousTab !== "") {
                    for (let i = 0; i < todoData.length; i++) {
                        if (todoData[i].name === previousTab) { activeTabIndex = i; break; }
                    }
                }

                todoRoot.isLoaded = true;
                updateModels();
            }
        }
    }

    // A local change is pushed shortly after it settles instead of waiting for
    // the next retry tick, so a task typed here reaches the phone quickly.
    Timer {
        id: pushTimer
        interval: 1500
        repeat: false
        onTriggered: if (TodoistService.hasToken) TodoistService.syncNow()
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 10

        // Section Tabs
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            ScrollView {
                FastWheel {}
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
                            width: Math.max(50, tabText.implicitWidth + 20); height: 28; radius: Theme.bubbleRadiusPill
                            color: activeTabIndex === index ? Theme.accentColor : "transparent"
                            border.color: activeTabIndex === index ? Theme.accentColor : Theme.glassBorder
                            border.width: 1
                            
                            Text {
                                id: tabText
                                anchors.centerIn: parent
                                text: model.name
                                color: activeTabIndex === index ? Colors.on_primary : Theme.subtext0
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
                width: 28; height: 28; radius: 14; color: "transparent"; border.color: Theme.accentColor; border.width: 1
                Text { anchors.centerIn: parent; text: "󰐕"; font.family: Theme.iconFont; color: Theme.accentColor; font.pixelSize: 12 }
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

        // Add Task Header & Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(6)

            Text {
                text: (activeTabIndex >= 0 && activeTabIndex < todoData.length) ? todoData[activeTabIndex].name : "Tasks"
                color: Theme.text
                font.weight: Font.Bold
                font.pixelSize: Theme.scaled(14)
            }

            // Progress Pill
            Rectangle {
                visible: tasksModel.count > 0
                implicitWidth: progTxt.implicitWidth + Theme.scaled(12)
                height: Theme.scaled(20)
                radius: 999
                color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.14)
                Text {
                    id: progTxt
                    anchors.centerIn: parent
                    text: todoRoot.completedCount + "/" + tasksModel.count + " done"
                    color: Theme.accentColor
                    font.pixelSize: Theme.scaled(9.5)
                    font.weight: Font.Bold
                }
            }

            Item { Layout.fillWidth: true }

            // Todoist Sync Status Pill (when connected)
            Rectangle {
                visible: TodoistService.hasToken
                implicitWidth: syncRow.implicitWidth + Theme.scaled(12)
                height: Theme.scaled(22)
                radius: 999
                color: syncPillM.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                border.color: TodoistService.offline ? Theme.powerYellow : Theme.glassBorder
                border.width: 1

                RowLayout {
                    id: syncRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)
                    Text {
                        text: "󰑐"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(11)
                        color: TodoistService.syncing ? Theme.accentColor : Theme.subtext0
                    }
                    Text {
                        text: TodoistService.syncing ? "Syncing"
                            : (TodoistService.offline ? "Offline"
                            : (TodoistService.pendingChanges > 0 ? (TodoistService.pendingChanges + " pending") : "Synced"))
                        color: TodoistService.offline ? Theme.powerYellow : Theme.subtext0
                        font.pixelSize: Theme.scaled(9)
                        font.weight: Font.DemiBold
                    }
                }
                MouseArea {
                    id: syncPillM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TodoistService.syncNow()
                }
            }

            // Search Toggle
            Rectangle {
                visible: tasksModel.count > 0
                width: Theme.scaled(24); height: Theme.scaled(24)
                radius: 999
                color: todoRoot.searchOpen ? Theme.accentColor : (tSearchM.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
                border.color: Theme.glassBorder
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "󰍉"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(12)
                    color: todoRoot.searchOpen ? Colors.on_primary : Theme.subtext0
                }
                MouseArea {
                    id: tSearchM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        todoRoot.searchOpen = !todoRoot.searchOpen;
                        if (todoRoot.searchOpen) Qt.callLater(() => taskSearchInput.forceActiveFocus());
                        else { todoRoot.searchQuery = ""; taskSearchInput.text = ""; }
                    }
                }
            }
        }

        // Filter Chips + Clear Completed
        RowLayout {
            visible: tasksModel.count > 0
            Layout.fillWidth: true
            spacing: Theme.scaled(5)

            Repeater {
                model: [
                    { id: "all", label: "All" },
                    { id: "active", label: "Active" },
                    { id: "done", label: "Done" }
                ]
                delegate: Rectangle {
                    readonly property bool active: todoRoot.filterMode === modelData.id
                    implicitWidth: fChipTxt.implicitWidth + Theme.scaled(14)
                    height: Theme.scaled(22)
                    radius: 999
                    color: active ? Theme.accentColor : (fChipM.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
                    border.color: active ? Theme.accentColor : Theme.glassBorder
                    border.width: 1
                    Text {
                        id: fChipTxt
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: Theme.scaled(9.5)
                        font.weight: Font.Bold
                        color: active ? Colors.on_primary : Theme.subtext0
                    }
                    MouseArea {
                        id: fChipM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: todoRoot.filterMode = modelData.id
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                visible: todoRoot.completedCount > 0
                implicitWidth: clrDoneTxt.implicitWidth + Theme.scaled(12)
                height: Theme.scaled(22)
                radius: 999
                color: clrDoneM.containsMouse ? Qt.rgba(Theme.powerRed.r, Theme.powerRed.g, Theme.powerRed.b, 0.18) : "transparent"
                border.color: clrDoneM.containsMouse ? Theme.powerRed : Theme.glassBorder
                border.width: 1
                Text {
                    id: clrDoneTxt
                    anchors.centerIn: parent
                    text: "Clear done"
                    font.pixelSize: Theme.scaled(9.5)
                    font.weight: Font.DemiBold
                    color: clrDoneM.containsMouse ? Theme.powerRed : Theme.subtext0
                }
                MouseArea {
                    id: clrDoneM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: todoRoot.clearCompleted()
                }
            }
        }

        // Optional Search Bar
        Rectangle {
            visible: todoRoot.searchOpen && tasksModel.count > 0
            Layout.fillWidth: true
            height: Theme.scaled(30)
            radius: Theme.scaled(8)
            color: Theme.surface1
            border.color: taskSearchInput.activeFocus ? Theme.accentColor : Theme.glassBorder
            border.width: 1
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(8)
                anchors.rightMargin: Theme.scaled(8)
                spacing: Theme.scaled(6)
                Text { text: "󰍉"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(12); color: Theme.subtext0 }
                TextInput {
                    id: taskSearchInput
                    Layout.fillWidth: true
                    color: Theme.text
                    font.pixelSize: Theme.scaled(11)
                    clip: true
                    onTextChanged: todoRoot.searchQuery = text
                    Keys.onEscapePressed: {
                        todoRoot.searchOpen = false;
                        todoRoot.searchQuery = "";
                        text = "";
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search tasks..."
                        color: Theme.subtext2
                        font.pixelSize: Theme.scaled(11)
                        visible: !parent.text && !parent.activeFocus
                    }
                }
            }
        }

        // Always-Ready Inline Add / Edit Task Input
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(Theme.scaled(36), inputField.contentHeight + Theme.scaled(14))
            radius: Theme.scaled(10)
            color: Theme.cardBackground
            border.color: (inputField.activeFocus || todoRoot.editingIndex !== -1) ? Theme.accentColor : Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(10)
                anchors.rightMargin: Theme.scaled(8)
                spacing: Theme.scaled(6)

                Text {
                    text: todoRoot.editingIndex !== -1 ? "󰏫" : "󰐕"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(14)
                    color: Theme.accentColor
                }

                TextArea {
                    id: inputField
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    background: null
                    color: Theme.text
                    padding: Theme.scaled(4)
                    font.pixelSize: Theme.scaled(11.5)
                    wrapMode: TextArea.Wrap
                    placeholderText: todoRoot.editingIndex !== -1 ? "Edit task..." : "Add a task and press Enter..."
                    placeholderTextColor: Theme.subtext2
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            if (event.modifiers & Qt.ShiftModifier) return;
                            if (text.trim() !== "") {
                                if (todoRoot.editingIndex !== -1) {
                                    tasksModel.setProperty(todoRoot.editingIndex, "task", text.trim());
                                    tasksModel.setProperty(todoRoot.editingIndex, "dirty", true);
                                    todoRoot.editingIndex = -1;
                                } else {
                                    tasksModel.append({ "task": text.trim(), "completed": false,
                                                        "todoist_id": "", "dirty": false });
                                }
                                inputField.text = "";
                                inputField.focus = false;
                                saveTasks();
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            todoRoot.cancelEdit();
                            event.accepted = true;
                        }
                    }
                }

                Rectangle {
                    visible: inputField.text.trim() !== "" || todoRoot.editingIndex !== -1
                    implicitWidth: addActLbl.implicitWidth + Theme.scaled(12)
                    height: Theme.scaled(24)
                    radius: Theme.scaled(6)
                    color: Theme.accentColor
                    Text {
                        id: addActLbl
                        anchors.centerIn: parent
                        text: todoRoot.editingIndex !== -1 ? "Save" : "Add"
                        color: Colors.on_primary
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let t = inputField.text.trim();
                            if (t !== "") {
                                if (todoRoot.editingIndex !== -1) {
                                    tasksModel.setProperty(todoRoot.editingIndex, "task", t);
                                    tasksModel.setProperty(todoRoot.editingIndex, "dirty", true);
                                    todoRoot.editingIndex = -1;
                                } else {
                                    tasksModel.append({ "task": t, "completed": false, "todoist_id": "", "dirty": false });
                                }
                                inputField.text = "";
                                inputField.focus = false;
                                saveTasks();
                            } else {
                                todoRoot.cancelEdit();
                            }
                        }
                    }
                }
            }
        }

        // --- TODOIST CONNECT PROMPT ---
        //
        // Sits above the task list rather than inside tasksModel: it is not a
        // task, and putting it in the model would make it draggable, savable,
        // and part of the reorder indices. It disappears the moment a token is
        // stored.
        Rectangle {
            id: todoistPrompt
            Layout.fillWidth: true
            Layout.preferredHeight: keyInputRow.visible ? Theme.scaled(112) : Theme.scaled(44)
            Layout.bottomMargin: Theme.scaled(8)
            visible: !TodoistService.hasToken

            radius: Theme.bubbleRadiusMedium
            color: Theme.menuBackground2
            border.color: Theme.glassBorder
            border.width: 1

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(8)
                spacing: Theme.scaled(6)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(8)

                    Text {
                        text: "󰌆"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(15)
                        color: Theme.accentColor
                        Layout.leftMargin: Theme.scaled(4)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: TodoistService.lastError !== ""
                              ? TodoistService.lastError
                              : "Add API key for Todoist to connect"
                        color: TodoistService.lastError !== "" ? Theme.powerRed : Theme.text
                        font.pixelSize: Theme.scaled(11)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    // The key button: opens the inline field.
                    Rectangle {
                        implicitWidth: Theme.scaled(28)
                        implicitHeight: Theme.scaled(28)
                        radius: Theme.scaled(8)
                        color: keyBtnMouse.containsMouse
                               ? Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.25)
                               : Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.15)

                        Behavior on color { ColorAnimation { duration: Theme.animInstant } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰌆"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(13)
                            color: Theme.accentColor
                        }

                        MouseArea {
                            id: keyBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                keyInputRow.visible = !keyInputRow.visible;
                                if (keyInputRow.visible) {
                                    tokenInput.text = "";
                                    tokenInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Inline entry. Hidden until the key button is pressed.
                RowLayout {
                    id: keyInputRow
                    Layout.fillWidth: true
                    visible: false
                    spacing: Theme.scaled(6)

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.scaled(28)
                        radius: Theme.scaled(8)
                        color: Qt.rgba(0, 0, 0, 0.35)
                        border.color: Theme.glassBorder
                        border.width: 1

                        TextInput {
                            id: tokenInput
                            anchors.fill: parent
                            anchors.leftMargin: Theme.scaled(8)
                            anchors.rightMargin: Theme.scaled(8)
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: Theme.scaled(11)
                            color: Theme.text
                            selectByMouse: true
                            clip: true
                            // A credential on a desktop others can see.
                            echoMode: TextInput.Password

                            onAccepted: todoistPrompt.submitToken()
                            Keys.onEscapePressed: keyInputRow.visible = false

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: tokenInput.text.length === 0
                                text: "Paste your Todoist API token"
                                color: Theme.subtext0
                                font.pixelSize: Theme.scaled(11)
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: Theme.scaled(28)
                        implicitHeight: Theme.scaled(28)
                        radius: Theme.scaled(8)
                        color: tokenInput.text.length > 0 ? Theme.accentColor : Theme.surface1
                        Behavior on color { ColorAnimation { duration: Theme.animInstant } }

                        Text {
                            anchors.centerIn: parent
                            text: TodoistService.verifying ? "󰅖" : "󰄬"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(13)
                            color: tokenInput.text.length > 0 ? Colors.on_primary : Theme.subtext0

                            RotationAnimator on rotation {
                                running: TodoistService.verifying
                                from: 0; to: 360; duration: 900; loops: Animation.Infinite
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: tokenInput.text.length > 0
                            cursorShape: Qt.PointingHandCursor
                            onClicked: todoistPrompt.submitToken()
                        }
                    }
                }

                // Where to actually get the token. Clicking opens the page
                // directly rather than making the user hunt through settings.
                // A plain Item the ColumnLayout manages, so the MouseArea can
                // anchor-fill it. Anchoring directly inside a layout is
                // undefined behaviour -- the layout owns the geometry.
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaled(16)
                    Layout.leftMargin: Theme.scaled(4)
                    visible: keyInputRow.visible

                    RowLayout {
                        anchors.fill: parent
                        spacing: Theme.scaled(5)

                        Text {
                            text: "󰏌"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(10)
                            color: linkMouse.containsMouse ? Theme.accentColor : Theme.subtext0
                            Behavior on color { ColorAnimation { duration: Theme.animInstant } }
                        }

                        Text {
                            text: "Get a token: Todoist -> Settings -> Integrations -> Developer"
                            font.pixelSize: Theme.scaled(10)
                            font.underline: linkMouse.containsMouse
                            color: linkMouse.containsMouse ? Theme.accentColor : Theme.subtext0
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: Theme.animInstant } }
                        }
                    }

                    MouseArea {
                        id: linkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: todoistPrompt.openTokenPage()
                    }
                }
            }

            readonly property string tokenPageUrl:
                "https://app.todoist.com/app/settings/integrations/developer"

            Process {
                id: openTokenPageProc
                command: ["xdg-open", todoistPrompt.tokenPageUrl]
            }

            function openTokenPage() {
                openTokenPageProc.running = false;
                openTokenPageProc.running = true;
            }

            function submitToken() {
                if (tokenInput.text.trim() === "") return;
                TodoistService.saveToken(tokenInput.text);
                tokenInput.text = "";
                keyInputRow.visible = false;
            }
        }

        // Tasks List
        ListView {
            id: taskListView
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: tasksModel.count > 0
            model: tasksModel; clip: true; spacing: 8

            FastWheel {}

            ScrollBar.vertical: ScrollBar {
                parent: taskListView
                anchors.top: taskListView.top
                anchors.bottom: taskListView.bottom
                anchors.right: taskListView.right
                anchors.rightMargin: 1
                policy: ScrollBar.AsNeeded
                width: 3
                contentItem: Rectangle { radius: 999; color: Theme.accentColor; opacity: 0.6 }
            }
            
            displaced: Transition {
                NumberAnimation { properties: "y"; duration: Theme.animFast; easing.type: Easing.OutCubic }
            }

            delegate: Item {
                id: delegateRoot
                readonly property bool matchesFilter: todoRoot.rowMatchesFilter(model)
                width: taskListView.width; height: visible ? contentCol.height + Theme.scaled(14) : 0
                z: dragArea.held ? 100 : 1
                visible: todoRoot.editingIndex !== index && matchesFilter

                Rectangle {
                    id: visualContent
                    anchors.fill: parent; radius: Theme.bubbleRadiusSmall
                    color: (todoRoot.selectedIndex === index) ? Theme.cardBackgroundHover : Theme.cardBackground
                    border.color: (todoRoot.selectedIndex === index) ? Theme.accentColor : Theme.glassBorder
                    border.width: 1
                    y: 0
                    
                    ColumnLayout {
                        id: contentCol
                        width: parent.width - 16; anchors.margins: 8; x: 8; y: 8
                        RowLayout {
                            spacing: 8
                            
                            // Drag Handle
                            Text {
                                text: "󰍜"; font.family: Theme.iconFont; color: Theme.surface2; font.pixelSize: 16
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
                                width: 22; height: 22; radius: 6; color: model.completed ? Theme.accentColor : Qt.rgba(255, 255, 255, 0.12); border.width: 0
                                Text { anchors.centerIn: parent; text: model.completed ? "󰄬" : ""; font.family: Theme.iconFont; color: Colors.on_primary; font.pixelSize: 13; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        tasksModel.setProperty(index, "completed", !model.completed);
                                        tasksModel.setProperty(index, "dirty", true);
                                        saveTasks();
                                    }
                                }
                            }

                            Text { 
                                text: model.task; Layout.fillWidth: true
                                color: model.completed ? Theme.surface2 : Theme.text
                                font.strikeout: model.completed
                                wrapMode: Text.WordWrap
                            }

                            Text { 
                                text: "󰏫"; font.family: Theme.iconFont; color: Theme.accentColor; font.pixelSize: Theme.scaled(16)
                                MouseArea { 
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { 
                                        todoRoot.editingIndex = index;
                                        inputField.text = model.task;
                                        inputField.forceActiveFocus();
                                        inputField.cursorPosition = inputField.text.length;
                                    } 
                                }
                            }
                            
                            Text { 
                                text: "󰆴"; font.family: Theme.iconFont; color: Theme.powerRed; font.pixelSize: Theme.scaled(18)
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        todoRoot.tombstoneTask(tasksModel.get(index));
                                        tasksModel.remove(index);
                                        saveTasks();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Empty state & helper text
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: tasksModel.count === 0
            color: "transparent"
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.scaled(8)
                Text {
                    text: "󰄬"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(32)
                    color: Theme.powerGreen
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "ALL TASKS COMPLETED"
                    color: Theme.text
                    font.pixelSize: Theme.scaled(12)
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Type a task above and press Enter to add"
                    color: Theme.subtext0
                    font.pixelSize: Theme.scaled(10)
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
