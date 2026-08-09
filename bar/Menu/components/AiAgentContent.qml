import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."
import "../../.."
import "./ai"

Rectangle {
    id: root
    color: "transparent"

    property string currentModel: "gemini"
    property bool isStreaming: false
    property string scriptPath: Quickshell.env("HOME") + "/zenith-shell/scripts/ai_agent.py"
    property string promptText: ""

    property bool statusGemini: false
    property bool statusClaude: false
    property bool statusOllama: false
    property string keysFilePath: ""

    ListModel { id: chatModel }

    function focusInput() {
        inputBar.focusInput();
    }

    Component.onCompleted: {
        root.loadHistory();
        root.refreshKeys();
        Qt.callLater(() => inputBar.focusInput());
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
                                    ? curMsg.content + "\\n\\n⚠️ " + event.message 
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

        onExited: (code) => { root.isStreaming = false; }
    }

    Process {
        id: dynamicSuggestProc
        running: false
        stdout: SplitParser {
            onRead: (dataStr) => {
                try {
                    let res = JSON.parse(dataStr.trim());
                    if (res.type === "dir_suggestions" && Array.isArray(res.suggestions)) {
                        inputBar.suggestions = res.suggestions;
                    } else if (res.type === "model_suggestions" && Array.isArray(res.suggestions)) {
                        inputBar.suggestions = res.suggestions;
                    }
                } catch (e) {}
            }
        }
    }

    Process { id: copyProc }

    function getSuggestions(text) {
        if (!text) return [];
        let trimText = text.replace(/^\s+/, "");
        if (!trimText) return [];

        let currentProvider = (root.currentModel || "gemini").toLowerCase();
        let subModels = {
            "gemini": ["/models gemini 2.5 Flash", "/models gemini 1.5 Pro", "/models gemini 2.0 Flash"],
            "gemini-pro": ["/models gemini 1.5 Pro", "/models gemini 2.5 Flash"],
            "claude": ["/models claude 3.5 Sonnet", "/models claude 3 Opus", "/models claude 3 Haiku"],
            "groq": ["/models groq Llama 3.3 70B", "/models groq Mixtral 8x7b"],
            "ollama": ["/models ollama llama3", "/models ollama mistral", "/models ollama codellama"]
        };
        let keyProviders = ["gemini", "claude", "groq"];
        let lower = trimText.toLowerCase();

        if (lower.startsWith("/models") || lower.startsWith("/model") || lower.startsWith("model") || lower.startsWith("/m")) {
            let activeModels = subModels[currentProvider] || subModels["gemini"];
            let matches = activeModels.filter(m => m.toLowerCase().startsWith(lower));
            return matches.length > 0 ? matches : activeModels;
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
            let pathPrefix = lower.replace("@file", "").replace("@", "").trim();
            let baseFiles = [
                "@file /home/zaeem/zenith-shell/Theme.qml",
                "@file /home/zaeem/zenith-shell/Colors.qml",
                "@file /home/zaeem/zenith-shell/scripts/ai_agent.py",
                "@file /home/zaeem/zenith-shell/bar/Menu/ControlCenter.qml",
                "@file /home/zaeem/.config/hypr/hyprland.conf"
            ];
            if (!pathPrefix) return baseFiles;
            let matches = baseFiles.filter(f => f.toLowerCase().indexOf(pathPrefix) !== -1);
            return matches.length > 0 ? matches : baseFiles;
        }

        return [];
    }

    function acceptSuggestion(sug) {
        if (!sug) return;
        let cleanSug = sug.replace(" <API_KEY>", "").replace(" /path/to/file", "");
        let finalText = cleanSug + (cleanSug.endsWith(" ") ? "" : " ");
        inputBar.setInputText(finalText);
        root.promptText = finalText;

        if (cleanSug.startsWith("/models ")) {
            let targetModel = cleanSug.split(" ")[1].trim().toLowerCase();
            if (["gemini", "gemini-pro", "claude", "groq", "ollama"].indexOf(targetModel) !== -1) {
                root.currentModel = targetModel;
            }
        }
    }

    function copyToClipboard(textToCopy) {
        copyProc.command = ["sh", "-c", "printf \x27%s\x27 " + JSON.stringify(textToCopy) + " | wl-copy 2>/dev/null || printf \x27%s\x27 " + JSON.stringify(textToCopy) + " | xclip -selection clipboard 2>/dev/null"];
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
        if (aiProcess.running) { aiProcess.running = false; }
        root.isStreaming = false;
    }

    function saveKey(provider, keyValue) {
        let req = { action: "save_key", provider: provider, key: keyValue };
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
                let statusText = "🔑 **API Key Configuration & Status**\\n\\n" +
                    "• **Gemini**: " + (root.statusGemini ? "✅ Active" : "❌ Missing") + "\\n" +
                    "• **Claude**: " + (root.statusClaude ? "✅ Active" : "❌ Missing") + "\\n" +
                    "• **Groq**: " + (root.statusGroq ? "✅ Active" : "❌ Missing") + "\\n" +
                    "• **Ollama**: " + (root.statusOllama ? "✅ Server Active" : "❌ Server Unreachable") + "\\n\\n" +
                    "**To save an API key locally**:\\n" +
                    "`/key gemini AIzaSy...`\\n" +
                    "`/key claude sk-ant-...`\\n" +
                    "`/key groq gsk_...`\\n\\n" +
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
                let modelsText = "🤖 **Available AI Models**\\n\\n" +
                    "1. `/models gemini` - Google Gemini 3.6 / Flash\\n" +
                    "2. `/models gemini-pro` - Google Gemini Pro\\n" +
                    "3. `/models claude` - Anthropic Claude 3.5 Sonnet\\n" +
                    "4. `/models groq` - Groq Free Tier (Llama 3.3 70B)\\n" +
                    "5. `/models ollama` - Ollama Local Model\\n\\n" +
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
            let helpText = "💡 **Zenith Antigravity Desktop AI Commands**\\n\\n" +
                "• `/exec <bash_command>` : Run shell command (e.g. `/exec free -h`)\\n" +
                "• `/sys` : Query active window & system metrics\\n" +
                "• `/export` : Export chat history to Markdown file\\n" +
                "• `/key <provider> <API_KEY>` : Store API key locally\\n" +
                "• `/models <name>` : Switch active model (gemini, claude, groq, ollama)\\n" +
                "• `@file /path/to/file` : Attach file contents directly into prompt\\n" +
                "• `/clear` : Clear history\\n" +
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

    function processSendPrompt(textRaw) {
        let text = textRaw.trim();
        if (text === "" || root.isStreaming) return;

        if (text.startsWith("/")) {
            inputBar.setInputText("");
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

        inputBar.setInputText("");
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

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.scaled(8)

        // --- TOP MODEL SELECTOR & ACTION BAR ---
        AiHeaderBar {
            Layout.fillWidth: true
            currentModel: root.currentModel
            statusGemini: root.statusGemini
            statusClaude: root.statusClaude
            statusOllama: root.statusOllama

            onSelectModel: (mId) => root.currentModel = mId
            onFetchSysInfoRequested: root.fetchSysInfo()
            onExportChatRequested: root.exportChat()
            onKeyHelpRequested: {
                inputBar.setInputText("/key " + root.currentModel + " ");
                root.promptText = "/key " + root.currentModel + " ";
                inputBar.focusInput();
            }
            onClearChatRequested: root.clearChat()
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

                delegate: AiMessageBubble {
                    msgRole: model.role
                    msgContent: model.content
                    msgTag: model.modelTag
                    msgTime: model.timestamp
                    isStreaming: root.isStreaming

                    onCopyRequested: (txt) => root.copyToClipboard(txt)
                    onRunCmdRequested: (cmd) => root.executeCommand(cmd)
                }
            }
        }

        // --- BOTTOM INPUT AREA ---
        AiInputBar {
            id: inputBar
            Layout.fillWidth: true
            isStreaming: root.isStreaming
            currentModel: root.currentModel
            
            onTextChangedSignal: (txt) => {
                root.promptText = txt;
                inputBar.suggestionIndex = 0;
                let lower = txt.trim().toLowerCase();

                if (lower.startsWith("@")) {
                    dynamicSuggestProc.running = false;
                    dynamicSuggestProc.command = ["python3", "-u", root.scriptPath, "--scan-dir", txt];
                    dynamicSuggestProc.running = true;
                } else if (lower.startsWith("/m") || lower.startsWith("/model")) {
                    dynamicSuggestProc.running = false;
                    dynamicSuggestProc.command = ["python3", "-u", root.scriptPath, "--get-models", root.currentModel];
                    dynamicSuggestProc.running = true;
                } else if (lower.startsWith("/")) {
                    let baseCmds = ["/exec", "/sys", "/export", "/key", "/models", "/help", "/clear"];
                    inputBar.suggestions = baseCmds.filter(c => c.startsWith(lower));
                } else {
                    inputBar.suggestions = [];
                }
            }
            onSendPromptRequested: (prompt) => root.processSendPrompt(prompt)
            onStopStreamingRequested: root.stopStreaming()
            onSuggestionAccepted: (sug) => root.acceptSuggestion(sug)
        }
    }
}
