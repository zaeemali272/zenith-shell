pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: service

    property string storagePath: Quickshell.env("HOME") + "/.config/quickshell/productivity.json"
    
    // --- Reactive Properties (Source of Truth) ---
    property int duration: 0
    property int remaining: 0
    property bool running: false
    property bool isBeeping: false
    property var tasks: []

    signal refreshData()

    Component.onCompleted: load()

    function load() {
        loadProcess.running = true
    }

    function initData(parsed) {
        if (parsed) {
            tasks = parsed.tasks || [];
            if (parsed.timer) {
                duration = Math.max(0, parsed.timer.duration || 0);
                remaining = Math.max(0, parsed.timer.remaining || 0);
                running = (parsed.timer.running === true && remaining > 0);
            }
        }
        
        isBeeping = false;
        refreshData();
    }

    function save() {
        let data = {
            tasks: tasks,
            timer: {
                duration: duration,
                remaining: remaining,
                running: running
            }
        };
        
        let cmd = "mkdir -p " + Quickshell.env("HOME") + "/.config/quickshell && echo '" + JSON.stringify(data).replace(/'/g, "'\\''") + "' > " + storagePath;
        saveProcess.command = ["sh", "-c", cmd];
        saveProcess.running = true;
    }

    // --- Timer Actions ---
    function setDuration(secs) {
        stopBeeping();
        running = false;
        duration = Math.max(0, secs);
        remaining = duration;
        save();
    }

    function adjustDuration(delta) {
        if (running || isBeeping) return;
        
        // Prevent accidental double-increments
        let next = Math.max(0, duration + delta);
        if (next === duration) return;
        
        duration = next;
        remaining = duration;
        save();
    }

    function toggleTimer() {
        if (isBeeping) {
            dismissAlarm();
            return;
        }
        if (duration <= 0) return;
        
        running = !running;
        if (remaining <= 0) remaining = duration;
        save();
    }

    function resetTimer() {
        running = false;
        remaining = 0;
        duration = 0;
        stopBeeping();
        save();
    }

    function dismissAlarm() {
        stopBeeping();
        running = false;
        remaining = 0;
        duration = 0;
        save();
    }

    function stopBeeping() {
        isBeeping = false;
        // Kill the specific beep process and any global paplay instances instantly
        beepProcess.running = false;
        Quickshell.exec(["pkill", "paplay"]);
    }

    // --- Task Management ---
    function addTask(task) {
        tasks.push({ task: task, completed: false, id: Date.now() });
        save();
    }

    function removeTask(id) {
        tasks = tasks.filter(t => t.id !== id);
        save();
    }

    // --- Background Countdown ---
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (service.running) {
                if (service.remaining > 0) {
                    service.remaining--;
                } else {
                    service.running = false;
                    service.isBeeping = true;
                    Quickshell.exec(["notify-send", "Timer Expired", "Your timer has finished!", "-i", "alarm-clock", "-a", "Zenith Timer"]);
                }
                
                if (service.remaining % 10 === 0 || service.remaining === 0) {
                    service.save();
                }
            }
        }
    }

    // --- Sound Loop (QML Driven for better control) ---
    Timer {
        id: alarmLoop
        interval: 2000 // Repeat every 2 seconds
        running: service.isBeeping
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // Restart the beep process
            beepProcess.running = false;
            beepProcess.running = true;
        }
    }

    Process {
        id: beepProcess
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"]
    }

    Process { 
        id: loadProcess; 
        command: ["cat", service.storagePath]; 
        stdout: StdioCollector {
            onStreamFinished: {
                try { 
                    let parsed = JSON.parse(text);
                    initData(parsed);
                } catch(e) {
                    initData(null);
                }
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) initData(null);
        }
    }
    Process { id: saveProcess }
}
