import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
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
    property var suggestions: []
    property int suggestionIndex: 0

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
            visible: rootInput.suggestions && rootInput.suggestions.length > 0

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
                    model: rootInput.suggestions

                    delegate: Rectangle {
                        height: Theme.scaled(20)
                        implicitWidth: chipText.implicitWidth + Theme.scaled(16)
                        radius: 999
                        color: index === (rootInput.suggestionIndex > 0 ? (rootInput.suggestionIndex - 1 + rootInput.suggestions.length) % rootInput.suggestions.length : 0)
                            ? Theme.accentColor 
                            : (chipMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.12))

                        border.color: index === (rootInput.suggestionIndex > 0 ? (rootInput.suggestionIndex - 1 + rootInput.suggestions.length) % rootInput.suggestions.length : 0) ? Qt.rgba(1, 1, 1, 0.6) : "transparent"
                        border.width: 1

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: (index === (rootInput.suggestionIndex > 0 ? (rootInput.suggestionIndex - 1 + rootInput.suggestions.length) % rootInput.suggestions.length : 0) ? "󰌒 " : "") + modelData
                            font.pixelSize: Theme.scaled(9.5)
                            font.weight: index === (rootInput.suggestionIndex > 0 ? (rootInput.suggestionIndex - 1 + rootInput.suggestions.length) % rootInput.suggestions.length : 0) ? Font.Bold : Font.Normal
                            color: index === (rootInput.suggestionIndex > 0 ? (rootInput.suggestionIndex - 1 + rootInput.suggestions.length) % rootInput.suggestions.length : 0) ? Colors.on_primary : "#ffffff"
                        }

                        MouseArea {
                            id: chipMouse
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
                        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
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
