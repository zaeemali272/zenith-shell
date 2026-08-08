import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."
import "../../../"

Rectangle {
    id: root
    color: "transparent"

    property string currentModel: "gemini"
    property bool isStreaming: false
    property string scriptPath: Quickshell.env("HOME") + "/zenith-shell/scripts/ai_agent.py"
    property string promptText: ""
    property int suggestionIndex: 0

    property bool statusGemini: false
    property bool statusClaude: false
    property bool statusGroq: false
    property bool statusOllama: false
    property string keysFilePath: ""

    ListModel { id: chatModel }

    Component.onCompleted: {
        root.loadHistory();
        root.refreshKeys();
        Qt.callLater(() => root.focusInput());
    }

    Process {
        id: keyCheckProc
        command: ["python3", "-u", root.scriptPath, "--check-keys"]
        running: false
        stdout: SplitParser {
            onRead: (dataStr) => {
                try {
                    let res = JSON.parse(dataStr.trim());
                    if (res.type === "keys_status") {
                        root.statusGemini = res.gemini;
                        root.statusClaude = res.claude;
                        root.statusGroq = res.groq;
                        root.statusOllama = res.ollama;
                        if (res.keys_file) root.keysFilePath = res.keys_file;
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: historyProc
        running: false
        stdout: SplitParser {
            onRead: (dataStr) => {
                try {
                    let res = JSON.parse(dataStr.trim());
                    if (res.type === "history_loaded" && Array.isArray(res.history)) {
                        if (chatModel.count === 0 && res.history.length > 0) {
                            for (let i = 0; i < res.history.length; i++) {
                                chatModel.append(res.history[i]);
                            }
                            Qt.callLater(() => chatListView.positionViewAtEnd());
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: aiProcess
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                let text = line.trim();
                if (!text) return;
                try {
                    let event = JSON.parse(text);
                    if (event.type === "token") {
                        if (chatModel.count > 0) {
                            let lastIdx = chatModel.count - 1;
                            let curMsg = chatModel.get(lastIdx);
                            if (curMsg.role === "assistant") {
                                let updatedContent = curMsg.content + event.content;
                                chatModel.setProperty(lastIdx, "content", updatedContent);
                            }
                        }
                        chatListView.positionViewAtEnd();
                    } else if (event.type === "done") {
                        root.isStreaming = false;
                        aiProcess.running = false;
                        chatListView.positionViewAtEnd();
                        root.saveHistory();
                        root.refreshKeys();
                    } else if (event.type === "error") {
                        if (chatModel.count > 0) {
                            let lastIdx = chatModel.count - 1;
                            let curMsg = chatModel.get(lastIdx);
                            if (curMsg.role === "assistant") {
                                let errText = curMsg.content.length > 0 
                                    ? curMsg.content + "\n\n⚠️ " + event.message 
                                    : "⚠️ " + event.message;
                                chatModel.setProperty(lastIdx, "content", errText);
                            }
                        }
                        root.isStreaming = false;
                        aiProcess.running = false;
                        chatListView.positionViewAtEnd();
                        root.saveHistory();
                        root.refreshKeys();
                    }
                } catch (e) {}
            }
        }

        onExited: (code) => {
            root.isStreaming = false;
        }
    }

    Process { id: copyProc }

    function focusInput() {
        inputArea.forceActiveFocus();
        inputArea.cursorPosition = inputArea.text.length;
    }

    function getSuggestions(text) {
        if (!text) return [];
        let trimText = text.trimStart();
        if (!trimText) return [];

        let allModels = ["gemini", "gemini-pro", "claude", "groq", "ollama"];
        let keyProviders = ["gemini", "claude", "groq"];
        let lower = trimText.toLowerCase();

        if (lower.startsWith("/models") || lower.startsWith("/model") || lower.startsWith("model")) {
            let parts = lower.split(" ");
            let prefix = parts.length > 1 ? parts[1] : "";
            let matches = allModels.filter(m => m.startsWith(prefix));
            return matches.map(m => "/models " + m);
        }

        if (lower.startsWith("/key") || lower.startsWith("key")) {
            let parts = lower.split(" ");
            let prefix = parts.length > 1 ? parts[1] : "";
            let matches = keyProviders.filter(p => p.startsWith(prefix));
            return matches.map(p => "/key " + p + " <API_KEY>");
        }

        if (lower.startsWith("/exec") || lower.startsWith("exec") || lower.startsWith("run")) {
            return ["/exec hyprctl clients", "/exec free -h", "/exec uptime"];
        }

        if (lower.startsWith("/sys") || lower.startsWith("sys") || lower.startsWith("metrics")) {
            return ["/sys"];
        }

        if (lower.startsWith("/export") || lower.startsWith("export")) {
            return ["/export"];
        }

        if (lower.startsWith("/help") || lower.startsWith("help")) {
            return ["/help"];
        }

        if (lower.startsWith("/clear") || lower.startsWith("clear")) {
            return ["/clear"];
        }

        if (lower.startsWith("/")) {
            let baseCmds = ["/exec", "/sys", "/export", "/key", "/models", "/help", "/clear"];
            return baseCmds.filter(c => c.startsWith(lower));
        }

        if (lower.startsWith("@") || lower.startsWith("file")) {
            return ["@file /path/to/file"];
        }

        return [];
    }

    function acceptSuggestion(sug) {
        if (!sug) return;
        let cleanSug = sug.replace(" <API_KEY>", "").replace(" /path/to/file", "");
        inputArea.text = cleanSug + (cleanSug.endsWith(" ") ? "" : " ");
        root.promptText = inputArea.text;
        inputArea.cursorPosition = inputArea.text.length;

        if (cleanSug.startsWith("/models ")) {
            let targetModel = cleanSug.split(" ")[1].trim().toLowerCase();
            if (["gemini", "gemini-pro", "claude", "groq", "ollama"].indexOf(targetModel) !== -1) {
                root.currentModel = targetModel;
            }
        }
    }

    function copyToClipboard(textToCopy) {
        copyProc.command = ["sh", "-c", "printf '%s' " + JSON.stringify(textToCopy) + " | wl-copy 2>/dev/null || printf '%s' " + JSON.stringify(textToCopy) + " | xclip -selection clipboard 2>/dev/null"];
        copyProc.running = true;
    }

    function refreshKeys() {
        keyCheckProc.running = false;
        keyCheckProc.running = true;
    }

    function loadHistory() {
        historyProc.command = ["python3", "-u", root.scriptPath, "--load-history"];
        historyProc.running = true;
    }

    function saveHistory() {
        let history = [];
        for (let i = 0; i < chatModel.count; i++) {
            let item = chatModel.get(i);
            history.push({
                role: item.role,
                content: item.content,
                modelTag: item.modelTag,
                timestamp: item.timestamp
            });
        }
        let req = { action: "save_history", messages: history };
        aiProcess.command = ["python3", "-u", root.scriptPath, JSON.stringify(req)];
        aiProcess.running = true;
    }

    function clearChat() {
        stopStreaming();
        chatModel.clear();
        saveHistory();
    }

    function stopStreaming() {
        if (aiProcess.running) {
            aiProcess.running = false;
        }
        root.isStreaming = false;
    }

    function saveKey(provider, keyValue) {
        let req = {
            action: "save_key",
            provider: provider,
            key: keyValue
        };
        chatModel.append({
            role: "assistant",
            content: "Saving API Key...",
            modelTag: "System",
            timestamp: Qt.formatTime(new Date(), "hh:mm A")
        });
        aiProcess.command = ["python3", "-u", root.scriptPath, JSON.stringify(req)];
        aiProcess.running = true;
    }

    function executeCommand(bashCmd) {
        let req = { action: "exec", command: bashCmd };
        chatModel.append({
            role: "assistant",
            content: "",
            modelTag: "Terminal Exec",
            timestamp: Qt.formatTime(new Date(), "hh:mm A")
        });
        root.isStreaming = true;
        aiProcess.command = ["python3", "-u", root.scriptPath, JSON.stringify(req)];
        aiProcess.running = true;
    }

    function fetchSysInfo() {
        let req = { action: "sys_info" };
        chatModel.append({
            role: "assistant",
            content: "",
            modelTag: "System Metrics",
            timestamp: Qt.formatTime(new Date(), "hh:mm A")
        });
        root.isStreaming = true;
        aiProcess.command = ["python3", "-u", root.scriptPath, JSON.stringify(req)];
        aiProcess.running = true;
    }

    function exportChat() {
        let history = [];
        for (let i = 0; i < chatModel.count; i++) {
            let item = chatModel.get(i);
            history.push({
                role: item.role,
                content: item.content,
                modelTag: item.modelTag,
                timestamp: item.timestamp
            });
        }
        let req = { action: "export", messages: history };
        chatModel.append({
            role: "assistant",
            content: "",
            modelTag: "Export Engine",
            timestamp: Qt.formatTime(new Date(), "hh:mm A")
        });
        root.isStreaming = true;
        aiProcess.command = ["python3", "-u", root.scriptPath, JSON.stringify(req)];
        aiProcess.running = true;
    }

    function handleSlashCommand(inputRaw) {
        let text = inputRaw.trim();
        let parts = text.split(" ");
        let cmd = parts[0].toLowerCase();
        let args = parts.slice(1);

        if (cmd === "/exec" || cmd === "/sh" || cmd === "/run") {
            let bashCmd = args.join(" ");
            if (!bashCmd) {
                chatModel.append({
                    role: "assistant",
                    content: "Usage: `/exec <bash_command>` (e.g. `/exec hyprctl clients` or `/exec free -h`)",
                    modelTag: "System Help",
                    timestamp: Qt.formatTime(new Date(), "hh:mm A")
                });
            } else {
                executeCommand(bashCmd);
            }
            return true;
        }

        if (cmd === "/sys" || cmd === "/info" || cmd === "/metrics") {
            fetchSysInfo();
            return true;
        }

        if (cmd === "/export") {
            exportChat();
            return true;
        }

        if (cmd === "/key" || cmd === "/keys") {
            if (args.length >= 2) {
                let provider = args[0].toLowerCase();
                let keyVal = args.slice(1).join(" ");
                saveKey(provider, keyVal);
            } else {
                let statusText = "🔑 **API Key Configuration & Status**\n\n" +
                    "• **Gemini**: " + (root.statusGemini ? "✅ Active" : "❌ Missing") + "\n" +
                    "• **Claude**: " + (root.statusClaude ? "✅ Active" : "❌ Missing") + "\n" +
                    "• **Groq**: " + (root.statusGroq ? "✅ Active" : "❌ Missing") + "\n" +
                    "• **Ollama**: " + (root.statusOllama ? "✅ Server Active" : "❌ Server Unreachable") + "\n\n" +
                    "**To save an API key locally**:\n" +
                    "`/key gemini AIzaSy...`\n" +
                    "`/key claude sk-ant-...`\n" +
                    "`/key groq gsk_...`\n\n" +
                    "Keys are saved securely in `" + (root.keysFilePath || "~/.config/zenith/ai_keys.json") + "`";
                
                chatModel.append({
                    role: "assistant",
                    content: statusText,
                    modelTag: "System Help",
                    timestamp: Qt.formatTime(new Date(), "hh:mm A")
                });
                chatListView.positionViewAtEnd();
            }
            return true;
        }

        if (cmd === "/models" || cmd === "/model") {
            if (args.length >= 1) {
                let targetModel = args[0].toLowerCase();
                if (["gemini", "gemini-pro", "claude", "groq", "ollama"].indexOf(targetModel) !== -1) {
                    root.currentModel = targetModel;
                    chatModel.append({
                        role: "assistant",
                        content: "Switched model to **" + getModelDisplayName(targetModel) + "**",
                        modelTag: "System",
                        timestamp: Qt.formatTime(new Date(), "hh:mm A")
                    });
                } else {
                    chatModel.append({
                        role: "assistant",
                        content: "Unknown model `" + targetModel + "`. Available: `gemini`, `gemini-pro`, `claude`, `groq`, `ollama`",
                        modelTag: "System",
                        timestamp: Qt.formatTime(new Date(), "hh:mm A")
                    });
                }
            } else {
                let modelsText = "🤖 **Available AI Models**\n\n" +
                    "1. `/models gemini` - Google Gemini 3.6 / Flash\n" +
                    "2. `/models gemini-pro` - Google Gemini Pro\n" +
                    "3. `/models claude` - Anthropic Claude 3.5 Sonnet\n" +
                    "4. `/models groq` - Groq Free Tier (Llama 3.3 70B)\n" +
                    "5. `/models ollama` - Ollama Local Model\n\n" +
                    "Current active model: **" + getModelDisplayName(root.currentModel) + "**";
                chatModel.append({
                    role: "assistant",
                    content: modelsText,
                    modelTag: "System Help",
                    timestamp: Qt.formatTime(new Date(), "hh:mm A")
                });
            }
            chatListView.positionViewAtEnd();
            return true;
        }

        if (cmd === "/help") {
            let helpText = "💡 **Zenith Antigravity Desktop AI Commands**\n\n" +
                "• `/exec <bash_command>` : Run shell command (e.g. `/exec free -h`)\n" +
                "• `/sys` : Query active window & system metrics\n" +
                "• `/export` : Export chat history to Markdown file\n" +
                "• `/key <provider> <API_KEY>` : Store API key locally\n" +
                "• `/models <name>` : Switch active model (gemini, claude, groq, ollama)\n" +
                "• `@file /path/to/file` : Attach file contents directly into prompt\n" +
                "• `/clear` : Clear history\n" +
                "• `/help` : Show command guide";
            chatModel.append({
                role: "assistant",
                content: helpText,
                modelTag: "System Help",
                timestamp: Qt.formatTime(new Date(), "hh:mm A")
            });
            chatListView.positionViewAtEnd();
            return true;
        }

        if (cmd === "/clear") {
            root.clearChat();
            return true;
        }

        return false;
    }

    function sendMessage() {
        let text = inputArea.text.trim();
        if (text === "" || root.isStreaming) return;

        if (text.startsWith("/")) {
            inputArea.text = "";
            root.promptText = "";
            handleSlashCommand(text);
            return;
        }

        chatModel.append({
            role: "user",
            content: text,
            modelTag: root.currentModel,
            timestamp: Qt.formatTime(new Date(), "hh:mm A")
        });

        inputArea.text = "";
        root.promptText = "";

        let modelDisplayName = getModelDisplayName(root.currentModel);
        chatModel.append({
            role: "assistant",
            content: "",
            modelTag: modelDisplayName,
            timestamp: Qt.formatTime(new Date(), "hh:mm A")
        });

        chatListView.positionViewAtEnd();
        root.isStreaming = true;

        let history = [];
        for (let i = 0; i < chatModel.count - 1; i++) {
            let item = chatModel.get(i);
            history.push({
                role: item.role,
                content: item.content
            });
        }

        let requestData = {
            action: "prompt",
            model: root.currentModel,
            messages: history,
            system_prompt: "You are Antigravity Desktop AI Agent integrated into the Zenith Linux desktop shell control center. Provide clean markdown answers with code snippets."
        };

        aiProcess.command = ["python3", "-u", root.scriptPath, JSON.stringify(requestData)];
        aiProcess.running = true;
    }

    function getModelDisplayName(modelKey) {
        if (modelKey === "gemini") return "Gemini 3.6 / Flash";
        if (modelKey === "gemini-pro") return "Gemini Pro";
        if (modelKey === "claude") return "Claude 3.5";
        if (modelKey === "groq") return "Groq Llama 3";
        if (modelKey === "ollama") return "Ollama Local";
        return "AI";
    }

    function isKeyAvailable(modelKey) {
        if (modelKey === "gemini" || modelKey === "gemini-pro") return root.statusGemini;
        if (modelKey === "claude") return root.statusClaude;
        if (modelKey === "groq") return root.statusGroq;
        if (modelKey === "ollama") return root.statusOllama;
        return false;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.scaled(8)

        // --- TOP MODEL SELECTOR & ACTION BAR ---
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(44)
            color: Qt.rgba(0, 0, 0, 0.35)
            radius: Theme.bubbleRadiusMedium
            border.color: Theme.glassBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(10)
                anchors.rightMargin: Theme.scaled(10)
                spacing: Theme.scaled(6)

                Text {
                    text: "󰚩"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(18)
                    color: Theme.accentColor
                }

                Text {
                    text: "MODEL:"
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.Black
                    font.letterSpacing: 1
                    color: Colors.on_surface_variant
                    visible: !Theme.isSmallScreen
                }

                // Model Selector Pills
                RowLayout {
                    spacing: Theme.scaled(4)
                    Layout.fillWidth: true

                    Repeater {
                        model: [
                            { id: "gemini", label: "Gemini", icon: "✦" },
                            { id: "claude", label: "Claude", icon: "󰘦" },
                            { id: "groq", label: "Groq Free", icon: "⚡" },
                            { id: "ollama", label: "Ollama", icon: "🦙" }
                        ]

                        delegate: Rectangle {
                            id: modelPill
                            height: Theme.scaled(30)
                            implicitWidth: pillRow.implicitWidth + Theme.scaled(14)
                            radius: 999
                            color: root.currentModel.startsWith(modelData.id)
                                ? Theme.accentColor 
                                : (pillMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.04))

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                id: pillRow
                                anchors.centerIn: parent
                                spacing: Theme.scaled(4)

                                Text {
                                    text: modelData.icon
                                    font.pixelSize: Theme.scaled(11)
                                    color: root.currentModel.startsWith(modelData.id) ? Colors.on_primary : Colors.on_surface
                                }

                                Text {
                                    text: modelData.label
                                    font.pixelSize: Theme.scaled(11)
                                    font.weight: Font.Bold
                                    color: root.currentModel.startsWith(modelData.id) ? Colors.on_primary : Colors.on_surface
                                }

                                Rectangle {
                                    width: Theme.scaled(6)
                                    height: Theme.scaled(6)
                                    radius: 999
                                    color: root.isKeyAvailable(modelData.id) ? "#4CAF50" : "#FF9800"
                                }
                            }

                            MouseArea {
                                id: pillMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.currentModel = modelData.id
                            }
                        }
                    }
                }

                // System Info Badge Button (/sys)
                Rectangle {
                    width: Theme.scaled(30); height: Theme.scaled(30)
                    radius: 999
                    color: sysBtnMouse.containsMouse ? Qt.rgba(1,0.71,0.55,0.2) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰍹"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        color: Theme.accentColor
                    }
                    MouseArea {
                        id: sysBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.fetchSysInfo()
                    }
                    ToolTip.visible: sysBtnMouse.containsMouse
                    ToolTip.text: "Query System Metrics (/sys)"
                }

                // Export Markdown Button (/export)
                Rectangle {
                    width: Theme.scaled(30); height: Theme.scaled(30)
                    radius: 999
                    color: expBtnMouse.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰈙"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        color: Colors.on_surface_variant
                    }
                    MouseArea {
                        id: expBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.exportChat()
                    }
                    ToolTip.visible: expBtnMouse.containsMouse
                    ToolTip.text: "Export Chat to Markdown (/export)"
                }

                // Add Key Button (/key)
                Rectangle {
                    width: Theme.scaled(30); height: Theme.scaled(30)
                    radius: 999
                    color: keyAddMouse.containsMouse ? Qt.rgba(1,0.71,0.55,0.2) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰌆"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        color: Theme.accentColor
                    }
                    MouseArea {
                        id: keyAddMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            inputArea.text = "/key " + root.currentModel + " ";
                            root.promptText = inputArea.text;
                            inputArea.forceActiveFocus();
                        }
                    }
                    ToolTip.visible: keyAddMouse.containsMouse
                    ToolTip.text: "Add/Set API Key (/key)"
                }

                // Clear Chat Button (/clear)
                Rectangle {
                    width: Theme.scaled(30); height: Theme.scaled(30)
                    radius: 999
                    color: clearMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.2) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰃢"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        color: clearMouse.containsMouse ? Colors.error : Colors.on_surface_variant
                    }
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.clearChat()
                    }
                    ToolTip.visible: clearMouse.containsMouse
                    ToolTip.text: "Clear Conversation (/clear)"
                }
            }
        }

        // Key warning banner if active model lacks API Key
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(28)
            radius: Theme.bubbleRadiusSmall
            color: Qt.rgba(1, 0.6, 0, 0.15)
            border.color: Qt.rgba(1, 0.6, 0, 0.4)
            border.width: 1
            visible: !root.isKeyAvailable(root.currentModel)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(10)
                anchors.rightMargin: Theme.scaled(10)
                spacing: Theme.scaled(6)

                Text {
                    text: "󰀦"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(13)
                    color: "#FFB74D"
                }
                Text {
                    Layout.fillWidth: true
                    text: root.currentModel === "ollama" 
                        ? "Ollama not running. Type `/key` for help or start Ollama."
                        : "API key for " + root.currentModel.toUpperCase() + " missing. Type `/key " + root.currentModel + " <YOUR_KEY>` to save it!"
                    font.pixelSize: Theme.scaled(10.5)
                    color: "#FFE0B2"
                    elide: Text.ElideRight
                }
                Rectangle {
                    height: Theme.scaled(20)
                    implicitWidth: keySetLabel.implicitWidth + Theme.scaled(12)
                    radius: 999
                    color: Theme.accentColor
                    Text {
                        id: keySetLabel
                        anchors.centerIn: parent
                        text: "Set Key"
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Bold
                        color: Colors.on_primary
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            inputArea.text = "/key " + root.currentModel + " ";
                            root.promptText = inputArea.text;
                            inputArea.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // --- CHAT MESSAGE HISTORY ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.35)
            radius: Theme.cardRadius
            border.color: Theme.glassBorder
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.scaled(8)
                visible: chatModel.count === 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰚩"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(40)
                    color: Theme.accentColor
                    opacity: 0.8
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Antigravity AI Agent"
                    font.pixelSize: Theme.scaled(15)
                    font.weight: Font.Bold
                    color: Colors.on_surface
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Commands: `/exec <cmd>`, `/sys`, `/key`, `/models`, `/export`, `@file path`"
                    font.pixelSize: Theme.scaled(11)
                    color: Colors.on_surface_variant
                }
            }

            ListView {
                id: chatListView
                anchors.fill: parent
                anchors.margins: Theme.scaled(12)
                spacing: Theme.scaled(12)
                model: chatModel
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: delegateItem
                    width: chatListView.width
                    implicitHeight: bubbleCol.implicitHeight + Theme.scaled(12)

                    ColumnLayout {
                        id: bubbleCol
                        width: parent.width
                        spacing: Theme.scaled(4)

                        RowLayout {
                            Layout.alignment: model.role === "user" ? Qt.AlignRight : Qt.AlignLeft
                            spacing: Theme.scaled(6)

                            Text {
                                text: model.role === "user" ? "You" : (model.modelTag || "AI Agent")
                                font.pixelSize: Theme.scaled(10)
                                font.weight: Font.Bold
                                color: model.role === "user" ? Theme.accentColor : Colors.on_surface_variant
                            }
                            Text {
                                text: model.timestamp || ""
                                font.pixelSize: Theme.scaled(9)
                                color: Qt.rgba(1, 1, 1, 0.4)
                            }
                        }

                        Rectangle {
                            id: msgBubble
                            Layout.alignment: model.role === "user" ? Qt.AlignRight : Qt.AlignLeft
                            
                            width: model.role === "user" 
                                ? Math.min(bubbleCol.width * 0.82, Math.max(Theme.scaled(80), userTextMeasurer.implicitWidth + Theme.scaled(28)))
                                : bubbleCol.width * 0.85

                            implicitHeight: bubbleInnerCol.implicitHeight + Theme.scaled(24)

                            color: model.role === "user" 
                                ? Colors.primary_container 
                                : Colors.surface_container_high

                            radius: Theme.bubbleRadiusMedium
                            border.color: model.role === "user" ? Qt.rgba(1, 0.71, 0.55, 0.3) : Colors.outline_variant
                            border.width: 1

                            Text {
                                id: userTextMeasurer
                                visible: false
                                text: model.content
                                font.pixelSize: Theme.scaled(12)
                                font.family: "Sans-Serif"
                            }

                            ColumnLayout {
                                id: bubbleInnerCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Theme.scaled(12)
                                spacing: Theme.scaled(6)

                                TextEdit {
                                    id: msgContentText
                                    Layout.fillWidth: true
                                    readOnly: true
                                    selectByMouse: true
                                    wrapMode: TextEdit.WrapAnywhere
                                    color: model.role === "user" ? Colors.on_primary_container : Colors.on_surface
                                    selectionColor: Theme.accentColor
                                    selectedTextColor: Colors.on_primary
                                    font.pixelSize: Theme.scaled(12)
                                    font.family: "Sans-Serif"
                                    text: model.content === "" && model.role === "assistant" && root.isStreaming
                                        ? "Thinking..." 
                                        : model.content

                                    opacity: model.content === "" && root.isStreaming ? 0.6 : 1.0
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignRight
                                    spacing: Theme.scaled(6)
                                    visible: model.role === "assistant" && model.content !== ""

                                    Rectangle {
                                        height: Theme.scaled(22)
                                        implicitWidth: runBtnText.implicitWidth + Theme.scaled(12)
                                        radius: 999
                                        color: runBtnMouse.containsMouse ? Theme.accentColor : Qt.rgba(1, 1, 1, 0.1)
                                        visible: model.content.indexOf("```bash") !== -1 || model.content.indexOf("```sh") !== -1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text {
                                                text: "󰆍"
                                                font.family: Theme.iconFont
                                                font.pixelSize: Theme.scaled(11)
                                                color: runBtnMouse.containsMouse ? Colors.on_primary : Theme.accentColor
                                            }
                                            Text {
                                                id: runBtnText
                                                text: "Run Cmd"
                                                font.pixelSize: Theme.scaled(10)
                                                font.weight: Font.Bold
                                                color: runBtnMouse.containsMouse ? Colors.on_primary : "#ffffff"
                                            }
                                        }

                                        MouseArea {
                                            id: runBtnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                let text = model.content;
                                                let startIdx = text.indexOf("```bash");
                                                if (startIdx === -1) startIdx = text.indexOf("```sh");
                                                if (startIdx !== -1) {
                                                    let codeChunk = text.substring(text.indexOf("\n", startIdx) + 1);
                                                    let endIdx = codeChunk.indexOf("```");
                                                    if (endIdx !== -1) codeChunk = codeChunk.substring(0, endIdx);
                                                    let cleanCmd = codeChunk.trim().replace(/^\$\s*/, "");
                                                    if (cleanCmd) root.executeCommand(cleanCmd);
                                                }
                                            }
                                        }
                                        ToolTip.visible: runBtnMouse.containsMouse
                                        ToolTip.text: "Execute Command in Terminal Engine"
                                    }

                                    Rectangle {
                                        width: Theme.scaled(22); height: Theme.scaled(22)
                                        radius: 999
                                        color: copyBtnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆏"
                                            font.family: Theme.iconFont
                                            font.pixelSize: Theme.scaled(11)
                                            color: Colors.on_surface_variant
                                        }

                                        MouseArea {
                                            id: copyBtnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.copyToClipboard(model.content)
                                        }
                                        ToolTip.visible: copyBtnMouse.containsMouse
                                        ToolTip.text: "Copy to Clipboard"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- BOTTOM INPUT AREA WITH EMBEDDED SUGGESTION CHIPS ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: inputCol.implicitHeight + Theme.scaled(16)
            color: Qt.rgba(0, 0, 0, 0.55)
            radius: Theme.bubbleRadiusMedium
            border.color: inputArea.activeFocus ? Theme.accentColor : Theme.glassBorder
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            ColumnLayout {
                id: inputCol
                anchors.fill: parent
                anchors.margins: Theme.scaled(8)
                spacing: Theme.scaled(6)

                // EMBEDDED SUGGESTION CHIPS BAR (100% Guaranteed Visible)
                Rectangle {
                    Layout.fillWidth: true
                    height: Theme.scaled(28)
                    color: Qt.rgba(1, 1, 1, 0.06)
                    radius: Theme.bubbleRadiusSmall
                    visible: root.getSuggestions(root.promptText).length > 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.scaled(8)
                        anchors.rightMargin: Theme.scaled(8)
                        spacing: Theme.scaled(6)

                        Text {
                            text: "SUGGESTIONS [Tab]:"
                            font.pixelSize: Theme.scaled(9)
                            font.weight: Font.Black
                            color: Theme.accentColor
                        }

                        Repeater {
                            model: root.getSuggestions(root.promptText)

                            delegate: Rectangle {
                                height: Theme.scaled(20)
                                implicitWidth: chipText.implicitWidth + Theme.scaled(16)
                                radius: 999
                                color: index === (root.suggestionIndex > 0 ? (root.suggestionIndex - 1 + root.getSuggestions(root.promptText).length) % root.getSuggestions(root.promptText).length : 0)
                                    ? Theme.accentColor 
                                    : (chipMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.12))

                                border.color: index === (root.suggestionIndex > 0 ? (root.suggestionIndex - 1 + root.getSuggestions(root.promptText).length) % root.getSuggestions(root.promptText).length : 0) ? Qt.rgba(1, 1, 1, 0.6) : "transparent"
                                border.width: 1

                                Text {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: (index === (root.suggestionIndex > 0 ? (root.suggestionIndex - 1 + root.getSuggestions(root.promptText).length) % root.getSuggestions(root.promptText).length : 0) ? "󰌒 " : "") + modelData
                                    font.pixelSize: Theme.scaled(9.5)
                                    font.weight: index === (root.suggestionIndex > 0 ? (root.suggestionIndex - 1 + root.getSuggestions(root.promptText).length) % root.getSuggestions(root.promptText).length : 0) ? Font.Bold : Font.Normal
                                    color: index === (root.suggestionIndex > 0 ? (root.suggestionIndex - 1 + root.getSuggestions(root.promptText).length) % root.getSuggestions(root.promptText).length : 0) ? Colors.on_primary : "#ffffff"
                                }

                                MouseArea {
                                    id: chipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.acceptSuggestion(modelData);
                                        inputArea.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }

                // TEXTAREA AND BUTTON ROW
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(8)

                    ScrollView {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(Theme.scaled(36), Math.min(Theme.scaled(90), inputArea.contentHeight))
                        clip: true

                        TextArea {
                            id: inputArea
                            placeholderText: "Ask AI or type /exec, /sys, /key, /models, /export, @file..."
                            placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                            color: "#ffffff"
                            font.pixelSize: Theme.scaled(12)
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true
                            background: null

                            onTextChanged: {
                                root.promptText = inputArea.text;
                                root.suggestionIndex = 0;
                            }

                            Keys.onTabPressed: (event) => {
                                event.accepted = true;
                                let sugs = root.getSuggestions(root.promptText);
                                if (sugs.length > 0) {
                                    let idx = root.suggestionIndex % sugs.length;
                                    let choice = sugs[idx];
                                    root.acceptSuggestion(choice);
                                    root.suggestionIndex = (idx + 1) % sugs.length;
                                }
                            }

                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                    event.accepted = true;
                                } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                                    event.accepted = true;
                                    root.sendMessage();
                                }
                            }
                        }
                    }

                    // Send / Stop Button
                    Rectangle {
                        width: Theme.scaled(36)
                        height: Theme.scaled(36)
                        radius: 999
                        color: root.isStreaming 
                            ? Colors.error 
                            : (sendBtnMouse.containsMouse ? Theme.accentColor : Qt.rgba(1, 0.71, 0.55, 0.8))

                        scale: sendBtnMouse.pressed ? 0.92 : (sendBtnMouse.containsMouse ? 1.05 : 1.0)
                        Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: root.isStreaming ? "󰅖" : "󰏵"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(16)
                            color: root.isStreaming ? Colors.on_error : Colors.on_primary
                        }

                        MouseArea {
                            id: sendBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (root.isStreaming) {
                                    root.stopStreaming();
                                } else {
                                    root.sendMessage();
                                }
                            }
                        }
                        ToolTip.visible: sendBtnMouse.containsMouse
                        ToolTip.text: root.isStreaming ? "Stop Generation" : "Send Prompt"
                    }
                }
            }
        }
    }
}
