import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import "../../../.."

Rectangle {
    id: rootInput
    Layout.fillWidth: true
    implicitHeight: inputCol.implicitHeight + Theme.scaled(16)
    color: Qt.rgba(0, 0, 0, 0.55)
    radius: Theme.bubbleRadiusMedium
    border.color: inputArea.activeFocus ? Theme.accentColor : Theme.glassBorder
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    property bool isStreaming: false
    property string currentModel: "gemini"
    property int suggestionIndex: 0
    property var suggestions: []

    signal sendPromptRequested(string prompt)
    signal stopStreamingRequested()
    signal suggestionAccepted(string sug)
    signal textChangedSignal(string text)

    function focusInput() {
        inputArea.forceActiveFocus();
        inputArea.cursorPosition = inputArea.text.length;
    }

    function setInputText(t) {
        inputArea.text = t;
        inputArea.cursorPosition = inputArea.text.length;
    }

    function getModelIcon(mKey) {
        if (!mKey) return "✦";
        let k = mKey.toLowerCase();
        if (k.indexOf("claude") !== -1) return "󰘦";
        if (k.indexOf("ollama") !== -1) return "🦙";
        return "✦";
    }

    function getModelDisplayName(mKey) {
        if (!mKey) return "Gemini 2.5 Flash";
        let k = mKey.toLowerCase();
        if (k === "gemini") return "Gemini 2.5 Flash";
        if (k === "gemini-pro") return "Gemini 1.5 Pro";
        if (k === "claude") return "Claude 3.5 Sonnet";
        if (k === "ollama") return "Ollama Local";
        return mKey.toUpperCase();
    }

    // FLOATING PREDICTIVE SELECTION POPUP MENU (Dark Glass Matching Chat Container)
    Rectangle {
        id: popupMenu
        anchors.bottom: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: Theme.scaled(6)
        implicitHeight: popupCol.implicitHeight + Theme.scaled(12)
        visible: rootInput.suggestions && rootInput.suggestions.length > 0 && inputArea.activeFocus
        color: Colors.surface_container_high ? Colors.surface_container_high : Qt.rgba(0, 0, 0, 0.88)
        radius: Theme.bubbleRadiusMedium
        border.color: Theme.glassBorder
        border.width: 1

        ColumnLayout {
            id: popupCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.scaled(8)
            spacing: Theme.scaled(4)

            RowLayout {
                spacing: Theme.scaled(6)
                Text {
                    text: "⚡"
                    font.pixelSize: Theme.scaled(10)
                    color: Theme.accentColor
                }
                Text {
                    text: "SUGGESTIONS [Tab / Right Arrow]:"
                    font.pixelSize: Theme.scaled(9)
                    font.weight: Font.Black
                    color: Qt.rgba(1, 1, 1, 0.7)
                }
            }

            Repeater {
                model: rootInput.suggestions

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: Theme.scaled(26)
                    radius: Theme.bubbleRadiusSmall
                    color: index === (rootInput.suggestionIndex % rootInput.suggestions.length)
                        ? Theme.accentColor 
                        : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.scaled(8)
                        anchors.rightMargin: Theme.scaled(8)
                        spacing: Theme.scaled(6)

                        Text {
                            text: modelData.startsWith("@") ? "📁" : "⚡"
                            font.pixelSize: Theme.scaled(11)
                            color: index === (rootInput.suggestionIndex % rootInput.suggestions.length) 
                                ? Colors.on_primary 
                                : Theme.accentColor
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData
                            font.pixelSize: Theme.scaled(10.5)
                            font.weight: index === (rootInput.suggestionIndex % rootInput.suggestions.length) ? Font.Bold : Font.Normal
                            color: index === (rootInput.suggestionIndex % rootInput.suggestions.length) 
                                ? Colors.on_primary 
                                : "#ffffff"
                            elide: Text.ElideRight
                        }

                        Text {
                            text: index === (rootInput.suggestionIndex % rootInput.suggestions.length) ? "[Tab to select]" : ""
                            font.pixelSize: Theme.scaled(9)
                            font.weight: Font.Bold
                            color: Colors.on_primary
                            visible: index === (rootInput.suggestionIndex % rootInput.suggestions.length)
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            rootInput.suggestionAccepted(modelData);
                            rootInput.focusInput();
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: inputCol
        anchors.fill: parent
        anchors.margins: Theme.scaled(8)
        spacing: Theme.scaled(6)

        // TEXTAREA AND BUTTON ROW
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(8)

            // ACTIVE RUNNING MODEL INDICATOR BADGE
            Rectangle {
                height: Theme.scaled(24)
                implicitWidth: modelBadgeRow.implicitWidth + Theme.scaled(12)
                radius: 999
                color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.18)
                border.color: Qt.rgba(Theme.accentColor.r, Theme.accentColor.g, Theme.accentColor.b, 0.4)
                border.width: 1

                RowLayout {
                    id: modelBadgeRow
                    anchors.centerIn: parent
                    spacing: Theme.scaled(4)

                    Text {
                        text: rootInput.getModelIcon(rootInput.currentModel)
                        font.pixelSize: Theme.scaled(10)
                        color: Theme.accentColor
                    }

                    Text {
                        text: rootInput.getModelDisplayName(rootInput.currentModel).toUpperCase()
                        font.pixelSize: Theme.scaled(9)
                        font.weight: Font.Black
                        color: Colors.on_surface
                    }
                }

                ToolTip.visible: badgeMouse.containsMouse
                ToolTip.text: "Active AI Model Engine: " + rootInput.getModelDisplayName(rootInput.currentModel)

                MouseArea {
                    id: badgeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            ScrollView {
                Layout.fillWidth: true
                implicitHeight: Math.max(Theme.scaled(36), Math.min(Theme.scaled(90), inputArea.contentHeight))
                clip: true

                Item {
                    anchors.fill: parent

                    // INLINE GHOST PREDICTION OVERLAY TEXT
                    Text {
                        id: ghostTextOverlay
                        anchors.fill: parent
                        leftPadding: inputArea.leftPadding
                        topPadding: inputArea.topPadding
                        rightPadding: inputArea.rightPadding
                        bottomPadding: inputArea.bottomPadding
                        font: inputArea.font
                        color: Qt.rgba(1, 1, 1, 0.35)
                        wrapMode: TextEdit.Wrap
                        text: {
                            if (!rootInput.suggestions || rootInput.suggestions.length === 0) return "";
                            let activeIdx = rootInput.suggestionIndex % rootInput.suggestions.length;
                            let topSug = rootInput.suggestions[activeIdx];
                            let current = inputArea.text;
                            if (current.length > 0 && topSug.toLowerCase().startsWith(current.toLowerCase())) {
                                return current + topSug.substring(current.length);
                            }
                            return "";
                        }
                    }

                    TextArea {
                        id: inputArea
                        anchors.fill: parent
                        placeholderText: "Ask AI or type /exec, /sys, /key, /models, /export, @file..."
                        placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                        color: "#ffffff"
                        font.pixelSize: Theme.scaled(12)
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        background: null

                        onTextChanged: {
                            rootInput.suggestionIndex = 0;
                            rootInput.textChangedSignal(inputArea.text);
                        }

                        Keys.onTabPressed: (event) => {
                            event.accepted = true;
                            if (rootInput.suggestions && rootInput.suggestions.length > 0) {
                                let idx = rootInput.suggestionIndex % rootInput.suggestions.length;
                                let choice = rootInput.suggestions[idx];
                                rootInput.suggestionAccepted(choice);
                                rootInput.suggestionIndex = (idx + 1) % rootInput.suggestions.length;
                            }
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Right && inputArea.cursorPosition === inputArea.text.length) {
                                if (rootInput.suggestions && rootInput.suggestions.length > 0) {
                                    event.accepted = true;
                                    let idx = rootInput.suggestionIndex % rootInput.suggestions.length;
                                    rootInput.suggestionAccepted(rootInput.suggestions[idx]);
                                }
                            } else if (event.key === Qt.Key_Down) {
                                if (rootInput.suggestions && rootInput.suggestions.length > 0) {
                                    event.accepted = true;
                                    rootInput.suggestionIndex = (rootInput.suggestionIndex + 1) % rootInput.suggestions.length;
                                }
                            } else if (event.key === Qt.Key_Up) {
                                if (rootInput.suggestions && rootInput.suggestions.length > 0) {
                                    event.accepted = true;
                                    rootInput.suggestionIndex = (rootInput.suggestionIndex - 1 + rootInput.suggestions.length) % rootInput.suggestions.length;
                                }
                            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                event.accepted = true;
                            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                                event.accepted = true;
                                if (inputArea.text.trim() !== "") {
                                    rootInput.sendPromptRequested(inputArea.text);
                                }
                            }
                        }
                    }
                }
            }

            // Send / Stop Button
            Rectangle {
                width: Theme.scaled(36)
                height: Theme.scaled(36)
                radius: 999
                color: rootInput.isStreaming 
                    ? Colors.error 
                    : (sendBtnMouse.containsMouse ? Theme.accentColor : Qt.rgba(1, 0.71, 0.55, 0.8))

                scale: sendBtnMouse.pressed ? 0.92 : (sendBtnMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: rootInput.isStreaming ? "󰅖" : "󰏵"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(16)
                    color: rootInput.isStreaming ? Colors.on_error : Colors.on_primary
                }

                MouseArea {
                    id: sendBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (rootInput.isStreaming) {
                            rootInput.stopStreamingRequested();
                        } else {
                            if (inputArea.text.trim() !== "") {
                                rootInput.sendPromptRequested(inputArea.text);
                            }
                        }
                    }
                }
                ToolTip.visible: sendBtnMouse.containsMouse
                ToolTip.text: rootInput.isStreaming ? "Stop Generation" : "Send Prompt"
            }
        }
    }
}
