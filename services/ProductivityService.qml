pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "NotificationService.qml" as NotifService 

Item {
    id: service

    property string storagePath: Quickshell.env("HOME") + "/.config/quickshell/productivity.json"
    property var data: ({ tasks: [], timers: [] })
    property var activeTimer: null
    property bool timerRunning: false
    property bool isBeeping: false
    signal refreshData()

    Component.onCompleted: load()

    function load() {
        loadProcess.running = true
    }

    function save() {
        let cmd = "mkdir -p " + Quickshell.env("HOME") + "/.config/quickshell && echo '" + JSON.stringify(data).replace(/'/g, "'\\''") + "' > " + storagePath;
        saveProcess.command = ["sh", "-c", cmd];
        saveProcess.running = true;
        // Update active timer ref and signal
        activeTimer = data.timers.find(t => t.running) || null;
        timerRunning = data.timers.some(t => t.running);
        refreshData();
    }

    // Task Management
    function addTask(task) {
        data.tasks.push({ task: task, completed: false, id: Date.now() })
        save()
    }

    function removeTask(id) {
        data.tasks = data.tasks.filter(t => t.id !== id)
        save()
    }

    // Timer Management
    function addTimer(duration) {
        data.timers.push({ duration: duration, remaining: duration, running: false, finished: false, id: Date.now() })
        save()
    }

    function toggleTimer(id) {
        let timer = data.timers.find(t => t.id === id)
        if (timer) {
            timer.running = !timer.running
            save()
        }
    }

    function stopBeeping() {
        service.isBeeping = false;
        Quickshell.exec(["pkill", "paplay"]);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!data || !data.timers) return;

            let changed = false;
            let shouldBeep = false;

            data.timers.forEach(t => {
                if (t.running) {
                    console.log("DEBUG: Timer ID:", t.id, "Remaining:", t.remaining, "Finished:", t.finished);
                    if (t.remaining > 0) {
                        t.remaining--;
                        changed = true;
                    }

                    if (t.remaining <= 0 && !t.finished) {
                        console.log("Timer", t.id, "expired! Triggering audio alerts.");
                        t.running = false;
                        t.finished = true;
                        shouldBeep = true;
                    }
                }
            })
            if (shouldBeep) {
                console.log("EXEC: Starting beep loop with paplay");
                service.isBeeping = true;
                // Redirecting paplay output to a log file to see potential errors
                let soundCmd = "/usr/bin/paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga > /tmp/zenith_audio.log 2>&1 &";
                Quickshell.exec(["sh", "-c", soundCmd]);
                console.log("Audio process started. Check /tmp/zenith_audio.log for errors.");
            }

            // Ensure UI stays reactive
            service.activeTimer = data.timers.find(t => t.running) || null;
            service.timerRunning = data.timers.some(t => t.running);
            service.refreshData();

            if (changed || shouldBeep) {
                let newData = { tasks: data.tasks, timers: data.timers };
                data = newData;
                save();
            }
        }
    }

    Process { id: loadProcess; command: ["cat", service.storagePath]; onStdoutChanged: { try { service.data = JSON.parse(stdout.toString()); } catch(e) {} } }
    Process { id: saveProcess }
}
