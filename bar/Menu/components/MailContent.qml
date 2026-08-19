// Newest mail, read over IMAP.
//
// Nothing runs until the tab is on screen -- opening a network connection for a
// tab nobody has looked at is work for nothing. The list is headers only
// (sender, subject, date); bodies would be megabytes for no visible gain.
//
// With no account configured the tab is a connect prompt rather than an error,
// the same shape the Todoist tab uses.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../"
import "../../../services"
import "../../../Settings"

ColumnLayout {
    id: root
    spacing: Theme.scaled(10)

    property bool started: false
    property bool loading: false
    property string errorText: ""
    property bool needsConfig: !MailService.hasConfig
    property int unread: 0

    // Open message. Empty uid means the list is showing.
    property string openUid: ""
    property string openFrom: ""
    property string openSubject: ""
    property string openDate: ""
    property string openBody: ""
    property string openMessageId: ""
    property var openAttachments: []
    property bool openWasHtml: false
    property bool openLoading: false

    function openMessage(index) {
        var row = mailModel.get(index);
        if (!row) return;
        root.markRead(index);
        root.openUid = row.uid;
        root.openFrom = row.sender;
        root.openSubject = row.subject;
        root.openDate = "";
        root.openBody = "";
        root.openAttachments = [];
        root.openLoading = true;
        bodyProc.command = ["python3", MailService.script, "body", row.uid];
        bodyProc.running = false;
        bodyProc.running = true;
    }

    function closeMessage() {
        root.openUid = "";
        root.openBody = "";
        root.openAttachments = [];
    }

    readonly property string appPasswordUrl: "https://myaccount.google.com/apppasswords"

    function startIfNeeded() {
        if (started || !visible) return;
        started = true;
        refresh();
    }
    onVisibleChanged: { startIfNeeded(); if (started && visible) refresh(); }
    Component.onCompleted: startIfNeeded()

    function refresh() {
        if (loading || !MailService.hasConfig) return;
        loading = true;
        errorText = "";
        listProc.running = false;
        listProc.running = true;
    }

    function relative(ts) {
        if (!ts) return "";
        var diff = Math.floor(Date.now() / 1000) - ts;
        if (diff < 60)     return "now";
        if (diff < 3600)   return Math.floor(diff / 60) + "m";
        if (diff < 86400)  return Math.floor(diff / 3600) + "h";
        if (diff < 604800) return Math.floor(diff / 86400) + "d";
        return Qt.formatDateTime(new Date(ts * 1000), "d MMM");
    }

    ListModel { id: mailModel }

    Process {
        id: listProc
        command: ["python3", MailService.script, "list", "25"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                var res = {};
                try { res = JSON.parse(String(text).trim().split("\n").pop()); }
                catch (e) { root.errorText = "Mail fetch produced no usable result."; return; }

                if (res.type === "list") {
                    root.unread = res.unread || 0;
                    MailService.unread = root.unread;
                    MailService.connected = true;
                    MailService.account = res.user || "";
                    mailModel.clear();
                    for (var i = 0; i < res.messages.length; i++) {
                        var m = res.messages[i];
                        mailModel.append({
                            uid: String(m.uid), sender: String(m["from"] || ""),
                            addr: String(m.addr || ""), subject: String(m.subject || ""),
                            ts: m.ts | 0, unread: !!m.unread
                        });
                    }
                } else {
                    root.errorText = res.message || "Could not load mail.";
                    root.needsConfig = !!res.needs_config;
                    MailService.authFailed = !!res.auth;
                    MailService.offline = !!res.offline;
                }
            }
        }
    }

    Process { id: markProc }
    Process { id: openProc }

    Process {
        id: bodyProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.openLoading = false;
                var res = {};
                try { res = JSON.parse(String(text).trim().split("\n").pop()); }
                catch (e) { root.openBody = "Could not read this message."; return; }

                if (res.type === "body") {
                    root.openFrom = res["from"] || root.openFrom;
                    root.openSubject = res.subject || root.openSubject;
                    root.openDate = res.date || "";
                    root.openBody = res.body || "(no text content)";
                    root.openMessageId = res.message_id || "";
                    root.openAttachments = res.attachments || [];
                    root.openWasHtml = !!res.html;
                } else {
                    root.openBody = res.message || "Could not read this message.";
                }
            }
        }
    }

    function openInBrowser() {
        // Gmail can be searched by RFC822 message id, which is the only handle
        // IMAP gives us that the web client also understands.
        var url = root.openMessageId !== ""
                ? "https://mail.google.com/mail/u/0/#search/rfc822msgid:" + encodeURIComponent(root.openMessageId)
                : "https://mail.google.com/";
        openProc.command = ["xdg-open", url];
        openProc.running = false;
        openProc.running = true;
    }

    function markRead(index) {
        var row = mailModel.get(index);
        if (!row || !row.unread) return;
        mailModel.setProperty(index, "unread", false);
        root.unread = Math.max(0, root.unread - 1);
        MailService.unread = root.unread;
        markProc.command = ["python3", MailService.script, "read", row.uid];
        markProc.running = false;
        markProc.running = true;
    }

    // ---------------- header ----------------
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.scaled(8)

        Text {
            text: MailService.account !== "" ? MailService.account : "Mail"
            color: Theme.accentColor
            font.pixelSize: Theme.scaled(12)
            font.weight: Font.Black
            elide: Text.ElideRight
            // Measured against the tab, not the row: reading the row's own
            // width from a child that determines it makes Qt Quick
            // Layouts recurse ("Detected recursive rearrange").
            Layout.maximumWidth: root.width * 0.55
        }
        Rectangle {
            visible: root.unread > 0
            width: unreadLabel.implicitWidth + Theme.scaled(12)
            height: Theme.scaled(18)
            radius: height / 2
            color: Theme.accentColor
            Text {
                id: unreadLabel
                anchors.centerIn: parent
                text: root.unread + " new"
                color: Theme.base
                font.pixelSize: Theme.scaled(9)
                font.weight: Font.Black
            }
        }
        Item { Layout.fillWidth: true }
        Rectangle {
            width: Theme.scaled(56); height: Theme.scaled(24)
            radius: Theme.scaled(8)
            visible: MailService.hasConfig
            color: refreshMouse.containsMouse ? Theme.surfaceContainerHigh : Qt.rgba(0, 0, 0, 0.3)
            border.color: Theme.glassBorder; border.width: 1
            Text {
                anchors.centerIn: parent
                text: root.loading ? "..." : "refresh"
                color: Theme.subtext1
                font.pixelSize: Theme.scaled(9)
                font.weight: Font.Bold
            }
            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.refresh()
            }
        }

        // Always reachable, so a wrong password never leaves the tab with no
        // way back to the form.
        Rectangle {
            width: Theme.scaled(50); height: Theme.scaled(24)
            radius: Theme.scaled(8)
            visible: MailService.hasConfig
            color: resetMouse.containsMouse ? Theme.powerRed : Qt.rgba(0, 0, 0, 0.3)
            border.color: Theme.glassBorder; border.width: 1
            Text {
                anchors.centerIn: parent
                text: "reset"
                color: resetMouse.containsMouse ? Theme.base : Theme.subtext1
                font.pixelSize: Theme.scaled(9)
                font.weight: Font.Bold
            }
            MouseArea {
                id: resetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    MailService.clearAccount();
                    mailModel.clear();
                    root.unread = 0;
                    root.errorText = "";
                    root.needsConfig = true;
                    userInput.text = "";
                    passInput.text = "";
                }
            }
        }
    }

    // ---------------- connect prompt ----------------
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: connectCol.implicitHeight + Theme.scaled(24)
        visible: root.needsConfig || MailService.authFailed || !MailService.hasConfig
        radius: Theme.cardRadius
        color: Qt.rgba(0, 0, 0, 0.35)
        border.color: Theme.accentColor
        border.width: 1

        ColumnLayout {
            id: connectCol
            // Left/right/top rather than fill: the card's height is derived
            // from this column's implicitHeight, and anchoring the column to
            // the card's height as well makes each depend on the other, which
            // Qt Quick Layouts reports as a recursive rearrange.
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.scaled(12)
            spacing: Theme.scaled(8)

            Text {
                text: MailService.authFailed ? "Those credentials were rejected"
                                             : "Connect a mail account"
                color: Theme.text
                font.pixelSize: Theme.scaled(12)
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "Gmail needs an App Password, not your account password - "
                    + "2-step verification has to be on to create one. The server "
                    + "is worked out from your address."
                color: Theme.subtext0
                font.pixelSize: Theme.scaled(10)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(6)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaled(28)
                    radius: Theme.scaled(8)
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.color: userInput.activeFocus ? Theme.accentColor : Theme.glassBorder
                    border.width: 1
                    TextInput {
                        id: userInput
                        anchors.fill: parent
                        anchors.margins: Theme.scaled(8)
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.pixelSize: Theme.scaled(11)
                        selectByMouse: true
                        clip: true
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "you@gmail.com"
                            color: Theme.subtext0
                            font.pixelSize: Theme.scaled(11)
                            visible: userInput.text === ""
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaled(28)
                    radius: Theme.scaled(8)
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.color: passInput.activeFocus ? Theme.accentColor : Theme.glassBorder
                    border.width: 1
                    TextInput {
                        id: passInput
                        anchors.fill: parent
                        anchors.margins: Theme.scaled(8)
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.pixelSize: Theme.scaled(11)
                        echoMode: TextInput.Password
                        selectByMouse: true
                        clip: true
                        onAccepted: MailService.saveAccount(userInput.text, passInput.text, "")
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "app password"
                            color: Theme.subtext0
                            font.pixelSize: Theme.scaled(11)
                            visible: passInput.text === ""
                        }
                    }
                }
                Rectangle {
                    width: Theme.scaled(58); height: Theme.scaled(28)
                    radius: Theme.scaled(8)
                    color: saveMouse.containsMouse ? Theme.accentColor : Theme.surface1
                    Text {
                        anchors.centerIn: parent
                        text: "connect"
                        color: saveMouse.containsMouse ? Theme.base : Theme.subtext1
                        font.pixelSize: Theme.scaled(9)
                        font.weight: Font.Black
                    }
                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MailService.saveAccount(userInput.text, passInput.text, "")
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.scaled(16)
                Text {
                    id: linkText
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Create one: Google Account -> Security -> App passwords"
                    color: linkMouse.containsMouse ? Theme.accentColor : Theme.subtext0
                    font.pixelSize: Theme.scaled(10)
                    font.underline: linkMouse.containsMouse
                }
                MouseArea {
                    id: linkMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        openProc.command = ["xdg-open", root.appPasswordUrl];
                        openProc.running = false;
                        openProc.running = true;
                    }
                }
            }
        }
    }

    // ---------------- messages ----------------
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Theme.cardRadius
        color: Qt.rgba(0, 0, 0, 0.3)
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        ListView {
            id: mailList
            anchors.fill: parent
            anchors.margins: Theme.scaled(8)
            clip: true
            spacing: Theme.scaled(4)
            model: mailModel
            visible: mailModel.count > 0
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            FastWheel {}

            delegate: Rectangle {
                id: mailRow
                required property int index
                required property string sender
                required property string subject
                required property int ts
                required property bool unread

                width: mailList.width
                height: rowCol.implicitHeight + Theme.scaled(14)
                radius: Theme.scaled(8)
                color: rowMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Theme.scaled(4)
                    width: Theme.scaled(3)
                    height: parent.height * 0.55
                    radius: 2
                    color: Theme.accentColor
                    visible: mailRow.unread
                }

                ColumnLayout {
                    id: rowCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Theme.scaled(14)
                    anchors.rightMargin: Theme.scaled(8)
                    spacing: Theme.scaled(2)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.scaled(6)
                        Text {
                            Layout.fillWidth: true
                            text: mailRow.sender
                            color: mailRow.unread ? Theme.text : Theme.subtext1
                            font.pixelSize: Theme.scaled(11)
                            font.weight: mailRow.unread ? Font.Bold : Font.Normal
                            elide: Text.ElideRight
                        }
                        Text {
                            text: root.relative(mailRow.ts)
                            color: Theme.subtext0
                            font.pixelSize: Theme.scaled(9)
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: mailRow.subject
                        color: mailRow.unread ? Theme.subtext1 : Theme.subtext0
                        font.pixelSize: Theme.scaled(10)
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openMessage(mailRow.index)
                }
            }
        }

        // ---------------- reader ----------------
        Rectangle {
            anchors.fill: parent
            visible: root.openUid !== ""
            color: Theme.menuBackground
            radius: Theme.cardRadius

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.scaled(12)
                spacing: Theme.scaled(8)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(8)

                    Rectangle {
                        width: Theme.scaled(46); height: Theme.scaled(24)
                        radius: Theme.scaled(8)
                        color: backMouse.containsMouse ? Theme.surfaceContainerHigh : Qt.rgba(0, 0, 0, 0.35)
                        border.color: Theme.glassBorder; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "back"; color: Theme.subtext1
                            font.pixelSize: Theme.scaled(9); font.weight: Font.Bold
                        }
                        MouseArea {
                            id: backMouse
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeMessage()
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: Theme.scaled(74); height: Theme.scaled(24)
                        radius: Theme.scaled(8)
                        color: browserMouse.containsMouse ? Theme.accentColor : Qt.rgba(0, 0, 0, 0.35)
                        border.color: Theme.glassBorder; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "in browser"
                            color: browserMouse.containsMouse ? Theme.base : Theme.subtext1
                            font.pixelSize: Theme.scaled(9); font.weight: Font.Bold
                        }
                        MouseArea {
                            id: browserMouse
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openInBrowser()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.openSubject
                    color: Theme.text
                    font.pixelSize: Theme.scaled(13)
                    font.weight: Font.Bold
                    wrapMode: Text.WordWrap
                }
                Text {
                    Layout.fillWidth: true
                    text: root.openFrom + (root.openDate !== "" ? "   -   " + root.openDate : "")
                    color: Theme.subtext0
                    font.pixelSize: Theme.scaled(10)
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.openAttachments.length > 0
                    text: root.openAttachments.length + " attachment"
                        + (root.openAttachments.length === 1 ? "" : "s")
                        + ": " + root.openAttachments.join(", ")
                    color: Theme.accentColor
                    font.pixelSize: Theme.scaled(9)
                    elide: Text.ElideRight
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.glassBorder
                }

                Flickable {
                    id: bodyView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: bodyText.implicitHeight
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    FastWheel {}

                    TextEdit {
                        id: bodyText
                        width: bodyView.width
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        text: root.openLoading ? "Loading message..." : root.openBody
                        color: Theme.subtext1
                        font.pixelSize: Theme.scaled(11)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.openWasHtml && !root.openLoading
                    text: "HTML mail, shown as text"
                    color: Theme.subtext0
                    font.pixelSize: Theme.scaled(9)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - Theme.scaled(40)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Theme.subtext0
            font.pixelSize: Theme.scaled(11)
            visible: mailModel.count === 0 && root.openUid === ""
            text: root.needsConfig     ? "No account connected yet"
                : root.loading         ? "Loading mail..."
                : root.errorText !== "" ? root.errorText
                                       : "Inbox is empty"
        }
    }
}
