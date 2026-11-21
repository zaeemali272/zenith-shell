import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../../../services"
import "../../../windows" as Win
import "../../../"

Rectangle {
    id: root

    property var notification: null
    property bool enableAutoDismiss: true
    property bool animateHeight: true
    property int itemIndex: 0
    property bool animateOut: true

    // Stability: Debounced hovered state
    property bool realHovered: false
    property bool isReplying: false

    Timer {
        id: unhoverTimer
        interval: 250
        onTriggered: {
            if (!mainMouseArea.containsMouse && !dismissMouse.containsMouse && !isReplying) {
                root.realHovered = false;
                autoDismissTimer.restart();
            }
        }
    }

    // --- ZENITH THEMEING ---
    color: enableAutoDismiss 
        ? Theme.glassBackground 
        : (mainMouseArea.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground)
    radius: Theme.scaled(14)
    border.color: isReplying 
        ? Theme.accentColor 
        : (enableAutoDismiss 
            ? Theme.glassBorder 
            : (mainMouseArea.containsMouse ? Theme.glassBorder : Theme.cardBorder))
    border.width: 1
    antialiasing: true
    clip: true

    implicitHeight: layout.implicitHeight + Theme.scaled(24)
    Layout.fillWidth: true

    Behavior on implicitHeight {
        enabled: root.animateHeight
        NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
    }

    // --- ANIMATIONS ---
    opacity: 0
    scale: 0.92
    transform: Translate { id: trans; x: 50 }

    Component.onCompleted: {
        appearAnim.start();
        updateCandidates();
    }

    ParallelAnimation {
        id: appearAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: Theme.animNormal; easing.type: Theme.animEasing }
        NumberAnimation { target: root; property: "scale"; to: 1.0; duration: Theme.animNormal; easing.type: Theme.elasticEasing }
        NumberAnimation { target: trans; property: "x"; to: 0; duration: Theme.animSlow; easing.type: Theme.elasticEasing }
    }

    property bool _leaving: false
    signal leaveFinished()

    function leave() {
        if (_leaving) return;
        _leaving = true;
        appearAnim.stop();
        leaveAnim.start();
    }

    SequentialAnimation {
        id: leaveAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 0; duration: Theme.animFast; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "scale"; to: 0.94; duration: Theme.animFast; easing.type: Easing.InCubic }
            NumberAnimation { target: trans; property: "x"; to: 60; duration: Theme.animFast; easing.type: Easing.InCubic }
        }
        ScriptAction { script: root.leaveFinished() }
    }

    function dismiss(removeFromHistory) {
        if (!notification) return;
        const id = notification.id;
        const finish = () => {
            if (removeFromHistory) NotificationService.removeNotification(id);
            else NotificationService.dismissNotification(id);
        };
        if (!animateOut) { finish(); return; }
        leaveFinished.connect(finish);
        leave();
    }

    function submitReply() {
        if (!replyInput.text || replyInput.text.trim() === "") return;
        NotificationService.sendReply(notification.id, replyInput.text.trim());
        root.isReplying = false;
        root.dismiss(false);
    }

    // --- AUTO DISMISS LOGIC ---
    Timer {
        id: autoDismissTimer
        interval: 4000
        running: !!notification && enableAutoDismiss && !root.realHovered && !root.isReplying
        repeat: false
        onTriggered: {
            if (!root.realHovered && !root.isReplying) root.dismiss(false);
        }
    }

    // --- DYNAMIC ICON RESOLUTION & WATERFALL ---
    property var iconCandidates: []
    property int currentCandidateIndex: -1
    property bool showFallbackLetter: false

    function getFallbackGlyph(appName, summary, body) {
        let text = ((appName || "") + " " + (summary || "") + " " + (body || "")).toLowerCase();
        if (text.includes("screenshot") || text.includes("snip") || text.includes("photo") || text.includes("camera") || text.includes("capture")) return "󰄄";
        if (text.includes("record") || text.includes("video") || text.includes("screencast")) return "󰕧";
        if (text.includes("terminal") || text.includes("shell") || text.includes("bash") || text.includes("zsh") || text.includes("cmd") || text.includes("console")) return "󰆍";
        if (text.includes("audio") || text.includes("volume") || text.includes("sound") || text.includes("music") || text.includes("speaker") || text.includes("song")) return "󰕾";
        if (text.includes("battery") || text.includes("power") || text.includes("charge")) return "󰁹";
        if (text.includes("bluetooth")) return "󰂯";
        if (text.includes("wifi") || text.includes("network") || text.includes("ethernet") || text.includes("internet")) return "󰤨";
        if (text.includes("bright") || text.includes("display")) return "󰃠";
        if (text.includes("color") || text.includes("pipette") || text.includes("picker")) return "󰈊";
        if (text.includes("mail") || text.includes("email") || text.includes("message") || text.includes("chat") || text.includes("discord") || text.includes("telegram")) return "󰭹";
        if (text.includes("system") || text.includes("setting") || text.includes("update") || text.includes("config")) return "󰒓";
        if (text.includes("download") || text.includes("save")) return "󰇚";
        return "󰂚";
    }

    function tryNextIcon() {
        currentCandidateIndex++;
        if (currentCandidateIndex < iconCandidates.length) {
            let nextSource = iconCandidates[currentCandidateIndex];
            if (nextSource && nextSource !== "") {
                iconImg.source = nextSource;
            } else {
                Qt.callLater(tryNextIcon);
            }
        } else {
            showFallbackLetter = true;
        }
    }

    function updateCandidates() {
        if (!notification) return;
        showFallbackLetter = false;

        let candidates = [];
        if (notification.iconCandidates && Array.isArray(notification.iconCandidates) && notification.iconCandidates.length > 0) {
            candidates = notification.iconCandidates;
        } else {
            candidates = Win.IconsFetcher.getIconCandidates(notification.appName || "", notification.desktopEntry || "", notification.rawIcon || notification.appIcon || "");
        }

        iconCandidates = candidates.filter((v, i, a) => v && v !== "" && a.indexOf(v) === i);
        currentCandidateIndex = -1;
        tryNextIcon();
    }

    onNotificationChanged: updateCandidates()

    // --- Main layout ---
    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.scaled(12)
        spacing: Theme.scaled(10)
        z: 2
        
        Layout.alignment: Qt.AlignVCenter 

        // Icon Container
        Rectangle {
            id: iconContainer
            Layout.preferredWidth: Theme.scaled(44)
            Layout.preferredHeight: Theme.scaled(44)
            Layout.alignment: Qt.AlignTop
            
            color: "transparent"
            radius: Theme.scaled(10)
            border.width: 0

            Image {
                id: iconImg
                anchors.centerIn: parent
                width: Theme.scaled(38)
                height: Theme.scaled(38)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                visible: !root.showFallbackLetter
                
                onStatusChanged: {
                    if (status === Image.Ready) {
                        if (iconImg.source.toString().startsWith("image://icon/") &&
                            iconImg.implicitWidth === 100 && iconImg.implicitHeight === 100) {
                            let iconName = iconImg.source.toString().replace("image://icon/", "");
                            if (!Quickshell.hasThemeIcon(iconName)) {
                                Qt.callLater(tryNextIcon);
                            }
                        }
                    } else if (status === Image.Error) {
                        Qt.callLater(tryNextIcon);
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.showFallbackLetter
                font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(26)
                color: Theme.accentColor
                text: root.getFallbackGlyph(
                    notification ? notification.appName : "",
                    notification ? notification.summary : "",
                    notification ? notification.body : ""
                )
            }
        }

        // Text & Content Section
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.scaled(4)

            // Header line: App Name + Timestamp
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(6)

                Label {
                    text: notification ? (notification.appName || "SYSTEM").toUpperCase() : ""
                    color: Theme.accentColor
                    font.pixelSize: Theme.scaled(10)
                    font.weight: Font.Black
                    font.letterSpacing: 1.2
                }

                Text {
                    text: "•"
                    color: Theme.subtext0
                    font.pixelSize: Theme.scaled(10)
                }

                Text {
                    text: notification ? (notification.timeStr || "now") : "now"
                    color: Theme.subtext0
                    font.pixelSize: Theme.scaled(10)
                }

                Item { Layout.fillWidth: true }
            }

            // Summary / Title
            Label {
                text: notification ? (notification.summary || "Notification") : ""
                color: "#ffffff"
                font.bold: true
                font.pixelSize: Theme.scaled(13)
                elide: root.realHovered ? Text.ElideNone : Text.ElideRight
                wrapMode: root.realHovered ? Text.Wrap : Text.NoWrap
                Layout.fillWidth: true
            }

            // Body
            Label {
                text: notification ? (notification.body || "") : ""
                color: Theme.subtext0
                font.pixelSize: Theme.scaled(11)
                wrapMode: root.realHovered ? Text.Wrap : Text.NoWrap
                elide: root.realHovered ? Text.ElideNone : Text.ElideRight
                maximumLineCount: root.realHovered ? 20 : 2
                Layout.fillWidth: true
                visible: text !== ""
            }

            // Inline Reply Field
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(6)
                visible: root.isReplying

                Rectangle {
                    Layout.fillWidth: true
                    height: Theme.scaled(28)
                    radius: Theme.scaled(6)
                    color: Theme.cardBackground
                    border.color: replyInput.activeFocus ? Theme.accentColor : Theme.glassBorder
                    border.width: 1

                    TextInput {
                        id: replyInput
                        anchors.fill: parent
                        anchors.leftMargin: Theme.scaled(8)
                        anchors.rightMargin: Theme.scaled(8)
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"
                        font.pixelSize: Theme.scaled(11)
                        selectByMouse: true
                        clip: true
                        onAccepted: root.submitReply()
                        Keys.onEscapePressed: root.isReplying = false

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: notification ? (notification.inlineReplyPlaceholder || "Reply...") : "Reply..."
                            color: Theme.subtext0
                            font.pixelSize: Theme.scaled(11)
                            visible: replyInput.text === "" && !replyInput.activeFocus
                        }
                    }
                }

                // Send Button
                Rectangle {
                    width: Theme.scaled(28)
                    height: Theme.scaled(28)
                    radius: Theme.scaled(6)
                    color: sendMouse.containsMouse ? Qt.lighter(Theme.accentColor, 1.1) : Theme.accentColor

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(12)
                        color: Colors.on_primary
                    }

                    MouseArea {
                        id: sendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submitReply()
                    }
                }
            }

            // Action Buttons Row (Click-to-action & Reply)
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(6)
                visible: !root.isReplying && ((notification && notification.actions && notification.actions.length > 0) || (notification && notification.hasInlineReply))

                // Reply Action Button
                Rectangle {
                    visible: Boolean(notification && notification.hasInlineReply)
                    height: Theme.scaled(24)
                    implicitWidth: replyBtnText.implicitWidth + Theme.scaled(16)
                    radius: Theme.scaled(6)
                    color: replyBtnMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                    border.color: Theme.glassBorder
                    border.width: 1

                    Text {
                        id: replyBtnText
                        anchors.centerIn: parent
                        text: "Reply"
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.DemiBold
                        color: Theme.accentColor
                    }

                    MouseArea {
                        id: replyBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.isReplying = true;
                            Qt.callLater(() => replyInput.forceActiveFocus());
                        }
                    }
                }

                // Dynamic Action Buttons
                Repeater {
                    model: (notification && notification.actions) ? notification.actions : []
                    delegate: Rectangle {
                        height: Theme.scaled(24)
                        implicitWidth: actBtnText.implicitWidth + Theme.scaled(16)
                        radius: Theme.scaled(6)
                        color: actBtnMouse.containsMouse ? Theme.cardBackgroundHover : Theme.cardBackground
                        border.color: Theme.glassBorder
                        border.width: 1

                        Text {
                            id: actBtnText
                            anchors.centerIn: parent
                            text: modelData.text || modelData.identifier || "Action"
                            font.pixelSize: Theme.scaled(10)
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }

                        MouseArea {
                            id: actBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.identifier === "inline-reply" || (modelData.text && modelData.text.toLowerCase().includes("reply"))) {
                                    root.isReplying = true;
                                    Qt.callLater(() => replyInput.forceActiveFocus());
                                } else {
                                    NotificationService.invokeAction(notification ? notification.id : 0, modelData.identifier, notification);
                                    root.dismiss(false);
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.preferredWidth: root.realHovered ? Theme.scaled(36) : Theme.scaled(8)
            Layout.minimumWidth: Layout.preferredWidth
        }
    }

    // Main Hover & Click-to-Action Area
    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        z: 1
        
        onEntered: {
            unhoverTimer.stop();
            root.realHovered = true;
            autoDismissTimer.stop();
        }
        
        onExited: unhoverTimer.restart();

        onClicked: {
            if (!root.isReplying) {
                NotificationService.invokeDefault(notification ? notification.id : 0, notification);
                root.dismiss(false);
            }
        }
    }

    // Dismiss Button (Top-Right)
    Item {
        id: dismissButton
        width: Theme.scaled(28); height: Theme.scaled(28)
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.scaled(8)
        z: 100
        visible: root.realHovered

        Rectangle {
            anchors.fill: parent
            radius: Theme.scaled(6)
            color: dismissMouse.containsMouse ? Theme.menuDarkHover : "transparent"
            border.width: 0
            scale: dismissMouse.pressed ? 0.92 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.animInstant; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.animInstant } }
            
            Text {
                anchors.centerIn: parent
                text: "󰅖"
                font.family: Theme.iconFont
                color: dismissMouse.containsMouse ? Theme.powerRed : Theme.subtext0
                font.pixelSize: Theme.scaled(16)
            }
        }

        MouseArea {
            id: dismissMouse
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                unhoverTimer.stop();
                root.realHovered = true;
            }
            onExited: unhoverTimer.restart();
            onClicked: {
                root.dismiss(true);
            }
        }
    }
}
