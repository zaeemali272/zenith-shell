import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: alarmService

    property ListModel alarms: ListModel {}

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            let now = new Date();
            let h = now.getHours();
            let ampm = h >= 12 ? "PM" : "AM";
            let h12 = h % 12 || 12;
            let m = now.getMinutes();
            let d = now.getDay();
            
            for (let i = 0; i < alarms.count; i++) {
                let a = alarms.get(i);
                if (a.active && a.hour === h12 && a.minute === m && a.ampm === ampm && a["d" + d]) {
                    Quickshell.exec(["notify-send", "-u", "critical", "-t", "0", "Alarm", "Time to wake up!"]);
                }
            }
        }
    }

    function addAlarm() {
        alarms.append({ 
            hour: 12, 
            minute: 0, 
            ampm: "AM", 
            d0: false, d1: false, d2: false, d3: false, d4: false, d5: false, d6: false,
            active: true 
        });
    }

    function removeAlarm(index) {
        if (index >= 0 && index < alarms.count) {
            alarms.remove(index);
        }
    }

    function toggleAlarm(index) {
        if (index >= 0 && index < alarms.count) {
            let a = alarms.get(index);
            a.active = !a.active;
            alarms.set(index, a);
        }
    }

    function updateAlarm(index, property, value) {
        if (index >= 0 && index < alarms.count) {
            let a = alarms.get(index);
            a[property] = value;
            alarms.set(index, a);
        }
    }
}

