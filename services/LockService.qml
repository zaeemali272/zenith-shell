// services/LockService.qml
//
// State for the session lock: whether it should be engaged, the password
// buffer and the PAM conversation. The lock surfaces (windows/lock) read this
// directly instead of receiving objects through per-screen surface
// properties, which arrived undefined and left the password field wired to
// nothing.
//
// Authenticates against /etc/pam.d/zenith-lock when the system provides it
// (zenith-nixos: security.pam.services.zenith-lock) and the universal "login"
// stack otherwise. Escape hatch from a TTY if PAM is misconfigured:
//     quickshell ipc call zenith:lock unlock
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

pragma Singleton

Singleton {
    id: root

    enum State { None, Failed, Error, MaxTries }

    // Desired state. WlSessionLock binds to it; the surfaces clear it once
    // their exit animation has finished.
    property bool locked: false

    // Raised by PAM on success (or the TTY escape hatch); surfaces animate
    // out and then drop `locked`.
    signal unlockRequested()
    signal flash()
    signal escapePressed()

    readonly property bool authenticating: passwd.active
    property string buffer: ""
    property int state: LockService.State.None
    property string message: ""

    function lock() {
        if (locked) return;
        MenuService.closeAll();
        reset();
        locked = true;
    }

    function unlock() {
        if (locked) unlockRequested();
    }

    function reset() {
        passwd.abort();
        passwd._responded = false;
        buffer = "";
        _pendingPassword = "";
        state = LockService.State.None;
        message = "";
    }

    function handleKey(event) {
        if (passwd.active || state === LockService.State.MaxTries) return;

        // Clear previous error message as soon as user types or fixes password
        if (state !== LockService.State.None && state !== LockService.State.MaxTries) {
            state = LockService.State.None;
            message = "";
        }

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            submit();
        } else if (event.key === Qt.Key_Backspace) {
            buffer = (event.modifiers & Qt.ControlModifier) ? "" : buffer.slice(0, -1);
        } else if (event.key === Qt.Key_Escape) {
            buffer = "";
            escapePressed();
        } else if (event.text && /^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            buffer += event.text;
        }
    }

    property string _pendingPassword: ""

    function submit() {
        if (buffer.length > 0) {
            if (passwd.active) passwd.abort();
            passwd._responded = false;
            _pendingPassword = buffer;
            buffer = "";
            passwd.start();
        }
    }

    // PAM directory and service detection:
    // Uses the dedicated zenith-lock PAM service provided by zenith-nixos
    // (/etc/static/pam.d/zenith-lock), with fallback to the system login stack.
    property string pamConfigDir: "/etc/static/pam.d"
    property string pamConfig: "zenith-lock"

    Process {
        running: true
        command: [
            "sh", "-c",
            "if [ -f /etc/static/pam.d/zenith-lock ]; then printf '/etc/static/pam.d:zenith-lock'; " +
            "elif [ -f /.host-etc/pam.d/zenith-lock ]; then printf '/.host-etc/pam.d:zenith-lock'; " +
            "elif [ -f /etc/pam.d/zenith-lock ]; then printf '/etc/pam.d:zenith-lock'; " +
            "elif [ -f /etc/static/pam.d/login ]; then printf '/etc/static/pam.d:login'; " +
            "elif [ -f /.host-etc/pam.d/login ]; then printf '/.host-etc/pam.d:login'; " +
            "else printf '/etc/pam.d:login'; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(":");
                if (parts.length === 2 && parts[0] && parts[1]) {
                    if (root.pamConfigDir !== parts[0]) root.pamConfigDir = parts[0];
                    if (root.pamConfig !== parts[1]) root.pamConfig = parts[1];
                }
            }
        }
    }

    PamContext {
        id: passwd
        configDirectory: root.pamConfigDir
        config: root.pamConfig
        user: Variables.user || Quickshell.env("USER") || ""

        onMessageChanged: {
            if (message.startsWith("The account is locked")) root.message = message;
        }

        property bool _responded: false

        function handlePrompt() {
            if (responseRequired && !_responded && root._pendingPassword.length > 0) {
                _responded = true;
                respond(root._pendingPassword);
            }
        }

        onResponseRequiredChanged: {
            if (!responseRequired) _responded = false;
            handlePrompt();
        }
        onPamMessage: handlePrompt()

        onError: (err) => console.warn("zenith lock: pam error", err, "(config " + root.pamConfigDir + "/" + root.pamConfig + ")")
        onCompleted: (res) => {
            _responded = false;
            root._pendingPassword = "";
            if (res === PamResult.Success) {
                root.state = LockService.State.None;
                root.unlockRequested();
                return;
            }
            if (res === PamResult.MaxTries) root.state = LockService.State.MaxTries;
            else if (res === PamResult.Error) root.state = LockService.State.Error;
            else root.state = LockService.State.Failed;
            root.flash();
            stateReset.restart();
        }
    }

    Timer {
        id: stateReset
        interval: 4000
        onTriggered: if (root.state !== LockService.State.MaxTries) root.state = LockService.State.None
    }
}
