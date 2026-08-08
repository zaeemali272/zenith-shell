import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."
import "../../../"
import "../../services"
import "../../Settings"

Rectangle {
    id: root
    color: "transparent"

    property string currentModel: "gemini" // "gemini", "claude", "groq", "ollama"
    property bool isStreaming: false
    property string scriptPath: Quickshell.env("HOME") + "/zenith-shell/scripts/ai_agent.py"

    // Key / Service detection status
    property bool statusGemini: false
    property bool statusClaude: false
    property bool statusGroq: false
    property bool statusOllama: false
    property string keysFilePath: ""

    ListModel { id: chatModel }

    // --- KEY STATUS PROCESS ---
    Process {
        id: keyCheckProc
        command: ["python3", "-u", root.scriptPath, "--check-keys"]
        running: true
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

    // --- STREAMING & COMMAND PROCESS ---
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
                        root.refreshKeys();
                    }
                } catch (e) {}
            }
        }

        onExited: (code) => {
            root.isStreaming = false;
        }
    }

    // Clipboard copy process
    Process { id: copyProc }

    function copyToClipboard(textToCopy) {
        copyProc.command = ["sh", "-c", "printf '%s' " + JSON.stringify(textToCopy) + " | wl-copy 2>/dev/null || printf '%s' " + JSON.stringify(textToCopy) + " | xclip -selection clipboard 2>/dev/null"];
        copyProc.running = true;
    }

    function refreshKeys() {
        keyCheckProc.running = false;
        keyCheckProc.running = true;
    }

    function clearChat() {
        stopStreaming();
        chatModel.clear();
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

    function handleSlashCommand(inputRaw) {
        let text = inputRaw.trim();
        let parts = text.split(" ");
        let cmd = parts[0].toLowerCase();
        let args = parts.slice(1);

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
                if (["gemini", "claude", "groq", "ollama"].indexOf(targetModel) !== -1) {
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
                        content: "Unknown model `" + targetModel + "`. Available: `gemini`, `claude`, `groq`, `ollama`",
                        modelTag: "System",
                        timestamp: Qt.formatTime(new Date(), "hh:mm A")
                    });
                }
            } else {
                let modelsText = "🤖 **Available AI Models**\n\n" +
                    "1. `/models gemini` - Google Gemini 2.0 Flash\n" +
                    "2. `/models claude` - Anthropic Claude 3.5 Sonnet\n" +
                    "3. `/models groq` - Groq Free Tier (Llama 3.3 70B)\n" +
                    "4. `/models ollama` - Ollama Local Model\n\n" +
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
            let helpText = "💡 **Zenith AI Slash Commands**\n\n" +
                "• `/key <provider> <API_KEY>` : Store API key locally (e.g. `/key gemini AIza...`)\n" +
                "• `/key` : Check API key status & file path\n" +
                "• `/models` : List models or switch model (e.g. `/models claude`)\n" +
                "• `@file /path/to/file` : Attach file contents directly into prompt\n" +
                "• `/clear` : Clear conversation history\n" +
                "• `/help` : Show command help";
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

        // Check if input is a slash command
        if (text.startsWith("/")) {
            inputArea.text = "";
            handleSlashCommand(text);
            return;
        }

        // Add user message
        chatModel.append({
            role: "user",
            content: text,
            modelTag: root.currentModel,
            timestamp: Qt.formatTime(new Date(), "hh:mm A")
        });

        // Clear input field
        inputArea.text = "";

        // Add assistant placeholder item
        let modelDisplayName = getModelDisplayName(root.currentModel);
        chatModel.append({
            role: "assistant",
            content: "",
            modelTag: modelDisplayName,
            timestamp: Qt.formatTime(new Date(), "hh:mm A")
        });

        chatListView.positionViewAtEnd();
        root.isStreaming = true;

        // Build messages payload
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
            system_prompt: "You are a helpful, concise AI Desktop Assistant integrated into the Zenith Linux desktop shell control center. Provide clean markdown answers."
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
        if (modelKey === "gemini") return root.statusGemini;
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
                            color: root.currentModel === modelData.id 
                                ? Theme.accentColor 
                                : (pillMouse.containsMouse ? Qt.rgba(255,255,255,0.12) : Qt.rgba(255,255,255,0.04))

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                id: pillRow
                                anchors.centerIn: parent
                                spacing: Theme.scaled(4)

                                Text {
                                    text: modelData.icon
                                    font.pixelSize: Theme.scaled(11)
                                    color: root.currentModel === modelData.id ? Colors.on_primary : Colors.on_surface
                                }

                                Text {
                                    text: modelData.label
                                    font.pixelSize: Theme.scaled(11)
                                    font.weight: Font.Bold
                                    color: root.currentModel === modelData.id ? Colors.on_primary : Colors.on_surface
                                }

                                // Status Dot
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

                // Add Key Button
                Rectangle {
                    width: Theme.scaled(30); height: Theme.scaled(30)
                    radius: 999
                    color: keyAddMouse.containsMouse ? Qt.rgba(255,182,141,0.2) : "transparent"
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
                            inputArea.forceActiveFocus();
                        }
                    }
                    ToolTip.visible: keyAddMouse.containsMouse
                    ToolTip.text: "Add/Set API Key (/key)"
                }

                // Refresh Keys Status Button
                Rectangle {
                    width: Theme.scaled(30); height: Theme.scaled(30)
                    radius: 999
                    color: keyRefMouse.containsMouse ? Qt.rgba(255,255,255,0.15) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        color: Colors.on_surface_variant
                    }
                    MouseArea {
                        id: keyRefMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.refreshKeys()
                    }
                    ToolTip.visible: keyRefMouse.containsMouse
                    ToolTip.text: "Check API Keys Status"
                }

                // Clear Chat Button
                Rectangle {
                    width: Theme.scaled(30); height: Theme.scaled(30)
                    radius: 999
                    color: clearMouse.containsMouse ? Qt.rgba(255,80,80,0.2) : "transparent"
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
                    ToolTip.text: "Clear Conversation"
                }
            }
        }

        // Key warning banner if active model lacks API Key
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(28)
            radius: Theme.bubbleRadiusSmall
            color: Qt.rgba(255, 152, 0, 0.15)
            border.color: Qt.rgba(255, 152, 0, 0.4)
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
                            inputArea.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // --- CHAT MESSAGE HISTORY (ListView) ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.35)
            radius: Theme.cardRadius
            border.color: Theme.glassBorder
            border.width: 1
            clip: true

            // Welcome view if chat is empty
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
                    text: "Zenith AI Assistant"
                    font.pixelSize: Theme.scaled(15)
                    font.weight: Font.Bold
                    color: Colors.on_surface
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Commands: `/key <provider> <key>`, `/models`, `@file /path/to/file`"
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

                delegate: Item {
                    id: delegateItem
                    width: chatListView.width
                    height: bubbleCol.implicitHeight + Theme.scaled(6)

                    ColumnLayout {
                        id: bubbleCol
                        width: parent.width
                        spacing: Theme.scaled(4)

                        // Role & Timestamp Header
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

                        // Message Bubble Container - DARK THEME INTEGRATED
                        Rectangle {
                            id: msgBubble
                            Layout.alignment: model.role === "user" ? Qt.AlignRight : Qt.AlignLeft
                            
                            // Explicit robust width calculation preventing vertical squeezing bug
                            width: model.role === "user" 
                                ? Math.min(bubbleCol.width * 0.82, Math.max(Theme.scaled(80), userTextMeasurer.implicitWidth + Theme.scaled(28)))
                                : bubbleCol.width * 0.85

                            height: bubbleInnerCol.implicitHeight + Theme.scaled(20)

                            // Theme Container Colors
                            color: model.role === "user" 
                                ? Colors.primary_container 
                                : Colors.surface_container_high

                            radius: Theme.bubbleRadiusMedium
                            border.color: model.role === "user" ? Qt.rgba(1, 0.71, 0.55, 0.3) : Colors.outline_variant
                            border.width: 1

                            // Hidden text measurer for user messages
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

                                // Assistant action row (Copy response button)
                                RowLayout {
                                    Layout.alignment: Qt.AlignRight
                                    visible: model.role === "assistant" && model.content !== ""

                                    Rectangle {
                                        width: Theme.scaled(22); height: Theme.scaled(22)
                                        radius: 999
                                        color: copyBtnMouse.containsMouse ? Qt.rgba(255,255,255,0.15) : "transparent"

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

        // --- COMMAND HINT CHIPS (Shows when typing / or @) ---
        Rectangle {
            Layout.fillWidth: true
            height: Theme.scaled(32)
            color: Qt.rgba(0, 0, 0, 0.4)
            radius: Theme.bubbleRadiusSmall
            visible: inputArea.text.startsWith("/") || inputArea.text.startsWith("@")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.scaled(10)
                anchors.rightMargin: Theme.scaled(10)
                spacing: Theme.scaled(6)

                Text {
                    text: "SUGGESTIONS:"
                    font.pixelSize: Theme.scaled(9)
                    font.weight: Font.Black
                    color: Theme.accentColor
                }

                Repeater {
                    model: inputArea.text.startsWith("@") 
                        ? ["@file /path/to/file"] 
                        : ["/key gemini <KEY>", "/key claude <KEY>", "/key groq <KEY>", "/models", "/help", "/clear"]

                    delegate: Rectangle {
                        height: Theme.scaled(22)
                        implicitWidth: chipText.implicitWidth + Theme.scaled(12)
                        radius: 999
                        color: chipMouse.containsMouse ? Theme.accentColor : Qt.rgba(255,255,255,0.1)

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: Theme.scaled(10)
                            color: chipMouse.containsMouse ? Colors.on_primary : "#ffffff"
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                inputArea.text = modelData + " ";
                                inputArea.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        // --- BOTTOM INPUT AREA ---
        Rectangle {
            Layout.fillWidth: true
            height: Math.max(Theme.scaled(50), Math.min(Theme.scaled(110), inputArea.contentHeight + Theme.scaled(20)))
            color: Qt.rgba(0, 0, 0, 0.45)
            radius: Theme.bubbleRadiusMedium
            border.color: inputArea.activeFocus ? Theme.accentColor : Theme.glassBorder
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(8)
                spacing: Theme.scaled(8)

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        id: inputArea
                        placeholderText: "Ask AI or type /key, /models, /help, @file path..."
                        placeholderTextColor: Qt.rgba(255, 255, 255, 0.4)
                        color: "#ffffff"
                        font.pixelSize: Theme.scaled(12)
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        background: null

                        Keys.onPressed: (event) => {
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
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
                        : (sendBtnMouse.containsMouse ? Theme.accentColor : Qt.rgba(255, 182, 141, 0.8))

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
