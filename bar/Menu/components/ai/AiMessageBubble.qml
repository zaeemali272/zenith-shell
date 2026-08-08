import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../../../.."

Item {
    id: rootDelegate
    width: ListView.view ? ListView.view.width : (parent ? parent.width : 0)
    height: implicitHeight
    implicitHeight: bubbleCol.implicitHeight + Theme.scaled(12)

    property string msgRole: "user"
    property string msgContent: ""
    property string msgTag: ""
    property string msgTime: ""
    property bool isStreaming: false

    signal copyRequested(string text)
    signal runCmdRequested(string cmd)

    ColumnLayout {
        id: bubbleCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.scaled(4)

        // Role & Timestamp Header
        RowLayout {
            Layout.alignment: rootDelegate.msgRole === "user" ? Qt.AlignRight : Qt.AlignLeft
            spacing: Theme.scaled(6)

            Text {
                text: rootDelegate.msgRole === "user" ? "You" : (rootDelegate.msgTag || "AI Agent")
                font.pixelSize: Theme.scaled(10)
                font.weight: Font.Bold
                color: rootDelegate.msgRole === "user" ? Theme.accentColor : Colors.on_surface_variant
            }
            Text {
                text: rootDelegate.msgTime || ""
                font.pixelSize: Theme.scaled(9)
                color: Qt.rgba(1, 1, 1, 0.4)
            }
        }

        // Message Bubble Container
        Rectangle {
            id: msgBubble
            Layout.alignment: rootDelegate.msgRole === "user" ? Qt.AlignRight : Qt.AlignLeft
            
            width: rootDelegate.msgRole === "user" 
                ? Math.min(bubbleCol.width * 0.82, Math.max(Theme.scaled(80), userTextMeasurer.implicitWidth + Theme.scaled(28)))
                : bubbleCol.width * 0.85

            implicitHeight: bubbleInnerCol.implicitHeight + Theme.scaled(24)
            height: implicitHeight

            color: rootDelegate.msgRole === "user" 
                ? Colors.primary_container 
                : Colors.surface_container_high

            radius: Theme.bubbleRadiusMedium
            border.color: rootDelegate.msgRole === "user" ? Qt.rgba(1, 0.71, 0.55, 0.3) : Colors.outline_variant
            border.width: 1

            Text {
                id: userTextMeasurer
                visible: false
                text: rootDelegate.msgContent
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
                    color: rootDelegate.msgRole === "user" ? Colors.on_primary_container : Colors.on_surface
                    selectionColor: Theme.accentColor
                    selectedTextColor: Colors.on_primary
                    font.pixelSize: Theme.scaled(12)
                    font.family: "Sans-Serif"
                    text: rootDelegate.msgContent === "" && rootDelegate.msgRole === "assistant" && rootDelegate.isStreaming
                        ? "Thinking..." 
                        : rootDelegate.msgContent

                    opacity: rootDelegate.msgContent === "" && rootDelegate.isStreaming ? 0.6 : 1.0
                }

                // Assistant action bar (Copy & Quick Run Command buttons)
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: Theme.scaled(8)
                    visible: rootDelegate.msgRole === "assistant" && rootDelegate.msgContent !== ""

                    Rectangle {
                        height: Theme.scaled(24)
                        implicitWidth: runBtnRow.implicitWidth + Theme.scaled(16)
                        radius: 999
                        color: runBtnMouse.containsMouse ? Theme.accentColor : Qt.rgba(1, 1, 1, 0.1)
                        visible: rootDelegate.msgContent.indexOf("```bash") !== -1 || rootDelegate.msgContent.indexOf("```sh") !== -1

                        RowLayout {
                            id: runBtnRow
                            anchors.centerIn: parent
                            spacing: Theme.scaled(4)
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
                                let text = rootDelegate.msgContent;
                                let startIdx = text.indexOf("```bash");
                                if (startIdx === -1) startIdx = text.indexOf("```sh");
                                if (startIdx !== -1) {
                                    let codeChunk = text.substring(text.indexOf("\n", startIdx) + 1);
                                    let endIdx = codeChunk.indexOf("```");
                                    if (endIdx !== -1) codeChunk = codeChunk.substring(0, endIdx);
                                    let cleanCmd = codeChunk.trim().replace(/^\$\s*/, "");
                                    if (cleanCmd) rootDelegate.runCmdRequested(cleanCmd);
                                }
                            }
                        }
                        ToolTip.visible: runBtnMouse.containsMouse
                        ToolTip.text: "Execute Command in Terminal Engine"
                    }

                    Rectangle {
                        width: Theme.scaled(24); height: Theme.scaled(24)
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
                            onClicked: rootDelegate.copyRequested(rootDelegate.msgContent)
                        }
                        ToolTip.visible: copyBtnMouse.containsMouse
                        ToolTip.text: "Copy to Clipboard"
                    }
                }
            }
        }
    }
}
