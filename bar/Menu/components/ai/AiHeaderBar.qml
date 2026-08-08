import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../../../.."

ColumnLayout {
    id: rootHeader
    spacing: Theme.scaled(6)

    property string currentModel: "gemini"
    property bool statusGemini: false
    property bool statusClaude: false
    property bool statusGroq: false
    property bool statusOllama: false

    signal selectModel(string modelId)
    signal fetchSysInfoRequested()
    signal exportChatRequested()
    signal keyHelpRequested()
    signal clearChatRequested()

    function isKeyAvailable(modelKey) {
        if (modelKey === "gemini" || modelKey === "gemini-pro") return statusGemini;
        if (modelKey === "claude") return statusClaude;
        if (modelKey === "groq") return statusGroq;
        if (modelKey === "ollama") return statusOllama;
        return false;
    }

    // Top Bar Container
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
                        height: Theme.scaled(30)
                        implicitWidth: pillRow.implicitWidth + Theme.scaled(14)
                        radius: 999
                        color: rootHeader.currentModel.startsWith(modelData.id)
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
                                color: rootHeader.currentModel.startsWith(modelData.id) ? Colors.on_primary : Colors.on_surface
                            }

                            Text {
                                text: modelData.label
                                font.pixelSize: Theme.scaled(11)
                                font.weight: Font.Bold
                                color: rootHeader.currentModel.startsWith(modelData.id) ? Colors.on_primary : Colors.on_surface
                            }

                            Rectangle {
                                width: Theme.scaled(6)
                                height: Theme.scaled(6)
                                radius: 999
                                color: rootHeader.isKeyAvailable(modelData.id) ? "#4CAF50" : "#FF9800"
                            }
                        }

                        MouseArea {
                            id: pillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: rootHeader.selectModel(modelData.id)
                        }
                    }
                }
            }

            // /sys button
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
                    onClicked: rootHeader.fetchSysInfoRequested()
                }
                ToolTip.visible: sysBtnMouse.containsMouse
                ToolTip.text: "Query System Metrics (/sys)"
            }

            // /export button
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
                    onClicked: rootHeader.exportChatRequested()
                }
                ToolTip.visible: expBtnMouse.containsMouse
                ToolTip.text: "Export Chat to Markdown (/export)"
            }

            // /key button
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
                    onClicked: rootHeader.keyHelpRequested()
                }
                ToolTip.visible: keyAddMouse.containsMouse
                ToolTip.text: "Add/Set API Key (/key)"
            }

            // /clear button
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
                    onClicked: rootHeader.clearChatRequested()
                }
                ToolTip.visible: clearMouse.containsMouse
                ToolTip.text: "Clear Conversation (/clear)"
            }
        }
    }

    // Key missing warning banner
    Rectangle {
        Layout.fillWidth: true
        height: Theme.scaled(28)
        radius: Theme.bubbleRadiusSmall
        color: Qt.rgba(1, 0.6, 0, 0.15)
        border.color: Qt.rgba(1, 0.6, 0, 0.4)
        border.width: 1
        visible: !rootHeader.isKeyAvailable(rootHeader.currentModel)

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
                text: rootHeader.currentModel === "ollama" 
                    ? "Ollama not running. Type `/key` for help or start Ollama."
                    : "API key for " + rootHeader.currentModel.toUpperCase() + " missing. Type `/key " + rootHeader.currentModel + " <YOUR_KEY>` to save it!"
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
                    onClicked: rootHeader.keyHelpRequested()
                }
            }
        }
    }
}
