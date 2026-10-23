pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

QtObject {
    id: root

    property bool nightLight: false
    property bool dnd: false
    property bool micMuted: false

    readonly property bool caffeineActive: CaffeineService.active

    function toggleCaffeine() {
        CaffeineService.toggle();
    }

    function toggleDnd() {
        dnd = !dnd;
        notifyProc.command = ["notify-send", "-a", "Do Not Disturb", "-i", "notifications-disabled",
            dnd ? "Do Not Disturb Enabled" : "Do Not Disturb Disabled",
            dnd ? "Notification popups silenced." : "Normal notification popups resumed."];
        notifyProc.running = true;
    }

    function toggleNightLight() {
        if (nightLight) {
            nlProc.command = ["sh", "-c", "PIDS=$(pidof .gammastep-wrapped gammastep 2>/dev/null); [ -n \"$PIDS\" ] && kill -TERM $PIDS 2>/dev/null || pkill -INT -x .gammastep-wrap 2>/dev/null || true"];
            nightLight = false;
        } else {
            nlProc.command = ["sh", "-c", "PIDS=$(pidof .gammastep-wrapped gammastep 2>/dev/null); [ -n \"$PIDS\" ] && kill -TERM $PIDS 2>/dev/null; gammastep -O 3800 >/dev/null 2>&1 &"];
            nightLight = true;
        }
        nlProc.running = true;
    }

    function toggleMicMute() {
        micProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"];
        micProc.running = true;
        Qt.callLater(() => refreshMicState());
    }

    function refreshMicState() {
        checkMicProc.command = ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true"];
        checkMicProc.running = true;
        checkNlProc.command = ["sh", "-c", "pidof .gammastep-wrapped gammastep >/dev/null 2>&1 && echo 'RUNNING' || echo 'STOPPED'"];
        checkNlProc.running = true;
    }

    function triggerScreenshot(mode) {
        MenuService.closeAll();
        let m = mode || "region";
        let script = PathSettings.home + "/.config/hypr/hyprland/scripts/screenshot.sh";
        // Give 250ms for menus to dismiss cleanly
        delayTimer.callback = () => {
            toolProc.command = ["sh", "-c", "if [ -x \"" + script + "\" ]; then \"" + script + "\" " + m + "; else grim -g \"$(slurp)\" - | wl-copy; fi"];
            toolProc.running = true;
        };
        delayTimer.restart();
    }

    function triggerColorPicker() {
        MenuService.closeAll();
        delayTimer.callback = () => {
            toolProc.command = ["sh", "-c", "COLOR=$(hyprpicker -a) && [ -n \"$COLOR\" ] && notify-send -a 'Color Picker' -i 'color-picker' 'Color Copied' \"Hex: $COLOR\""];
            toolProc.running = true;
        };
        delayTimer.restart();
    }

    property Timer delayTimer: Timer {
        id: delayTimer
        interval: 220
        repeat: false
        property var callback: null
        onTriggered: {
            if (callback) callback();
        }
    }

    // Process runners
    property Process toolProc: Process { id: toolProc }
    property Process notifyProc: Process { id: notifyProc }
    property Process nlProc: Process { id: nlProc }
    property Process micProc: Process { id: micProc }

    property Process checkMicProc: Process {
        id: checkMicProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.micMuted = text.includes("[MUTED]");
            }
        }
    }

    property Process checkNlProc: Process {
        id: checkNlProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.nightLight = text.trim() === "RUNNING";
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshMicState()
    }
}
