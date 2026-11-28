pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

Item {
    id: service

    property date today: new Date()
    property var holidays: []
    property var customEvents: []
    property bool loadingHolidays: false
    property int loadedYear: -1
    property string loadedCountry: ""

    readonly property string effectiveCountryCode: {
        let code = GeneralSettings.autoDetectCountry
            ? (Variables.countryCode || "PK")
            : (GeneralSettings.customCountryCode || "PK");
        return code.trim().toUpperCase() || "PK";
    }

    readonly property string holidaysPath: PathSettings.stateDir + "/events.json"
    readonly property string customEventsPath: PathSettings.stateDir + "/calendar_events.json"

    signal dataUpdated()

    function formatDateKey(d) {
        if (!d) return "";
        return Qt.formatDate(d, "yyyy-MM-dd");
    }

    function isoWeekNumber(d) {
        let target = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        let dayNr = (target.getDay() + 6) % 7;
        target.setDate(target.getDate() - dayNr + 3);
        let firstThursday = target.valueOf();
        target.setMonth(0, 1);
        if (target.getDay() !== 4) {
            target.setMonth(0, 1 + ((4 - target.getDay()) + 7) % 7);
        }
        return 1 + Math.ceil((firstThursday - target) / 604800000);
    }

    function daysUntilLabel(dateStr) {
        if (!dateStr) return "";
        let parts = dateStr.split("-");
        if (parts.length !== 3) return "";
        let target = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
        let now = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        let diff = Math.round((target - now) / 86400000);
        if (diff === 0) return "Today";
        if (diff === 1) return "Tomorrow";
        if (diff === -1) return "Yesterday";
        if (diff > 1) return "In " + diff + "d";
        return Math.abs(diff) + "d ago";
    }

    function ensureYearLoaded(year) {
        let y = year || today.getFullYear();
        let cc = effectiveCountryCode;
        if (loadedYear === y && loadedCountry === cc) return;
        fetchHolidays(y, cc);
    }

    function fetchHolidays(year, country) {
        let y = year || today.getFullYear();
        let cc = (country || effectiveCountryCode).trim().toUpperCase();
        loadedYear = y;
        loadedCountry = cc;
        loadingHolidays = true;
        fetchProc.command = ["bash", PathSettings.scriptsDir + "/fetch_events.sh", y.toString(), cc];
        fetchProc.running = false;
        fetchProc.running = true;
    }

    function reloadHolidaysFromDisk() {
        readHolidaysProc.running = false;
        readHolidaysProc.running = true;
    }

    function reloadCustomEventsFromDisk() {
        readCustomProc.running = false;
        readCustomProc.running = true;
    }

    function _saveCustomEvents() {
        let payload = JSON.stringify(customEvents, null, 2);
        let b64 = Qt.btoa(unescape(encodeURIComponent(payload)));
        saveCustomProc.command = [
            "bash", "-c",
            "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" | base64 -d > \"$1\"",
            "_", customEventsPath, b64
        ];
        saveCustomProc.running = false;
        saveCustomProc.running = true;
    }

    function addEvent(dateStr, title, timeStr, category, notes) {
        let cleanTitle = (title || "").trim();
        if (!cleanTitle || !dateStr) return false;
        let next = customEvents.slice();
        next.push({
            id: Date.now().toString(36) + "_" + Math.floor(Math.random() * 10000).toString(36),
            date: dateStr,
            name: cleanTitle,
            time: (timeStr || "").trim(),
            category: category || "event",
            notes: (notes || "").trim(),
            type: "personal"
        });
        next.sort((a, b) => (a.date + " " + (a.time || "")).localeCompare(b.date + " " + (b.time || "")));
        customEvents = next;
        _saveCustomEvents();
        dataUpdated();
        return true;
    }

    function removeEvent(id) {
        if (!id) return;
        customEvents = customEvents.filter(e => e.id !== id);
        _saveCustomEvents();
        dataUpdated();
    }

    function eventsForDate(dateStr) {
        if (!dateStr) return [];
        let list = [];
        for (let i = 0; i < customEvents.length; i++) {
            if (customEvents[i].date === dateStr) {
                list.push(customEvents[i]);
            }
        }
        if (GeneralSettings.showHolidays) {
            for (let j = 0; j < holidays.length; j++) {
                if (holidays[j].date === dateStr) {
                    list.push(holidays[j]);
                }
            }
        }
        return list;
    }

    function hasPersonalEvent(dateStr) {
        for (let i = 0; i < customEvents.length; i++) {
            if (customEvents[i].date === dateStr) return true;
        }
        return false;
    }

    function hasHoliday(dateStr) {
        if (!GeneralSettings.showHolidays) return false;
        for (let i = 0; i < holidays.length; i++) {
            if (holidays[i].date === dateStr) return true;
        }
        return false;
    }

    function upcomingEvents(filterType) {
        let todayStr = formatDateKey(today);
        let combined = [];
        if (filterType !== "holidays") {
            for (let i = 0; i < customEvents.length; i++) {
                if (customEvents[i].date >= todayStr) combined.push(customEvents[i]);
            }
        }
        if (filterType !== "personal" && GeneralSettings.showHolidays) {
            for (let j = 0; j < holidays.length; j++) {
                if (holidays[j].date >= todayStr) combined.push(holidays[j]);
            }
        }
        combined.sort((a, b) => (a.date + " " + (a.time || "99:99")).localeCompare(b.date + " " + (b.time || "99:99")));
        return combined;
    }

    onEffectiveCountryCodeChanged: {
        if (loadedYear > 0) {
            fetchHolidays(loadedYear, effectiveCountryCode);
        }
    }

    // Keep `today` fresh across midnight
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            let now = new Date();
            if (now.toDateString() !== service.today.toDateString()) {
                service.today = now;
            }
        }
    }

    Process {
        id: readHolidaysProc
        command: ["cat", service.holidaysPath]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    let parsed = JSON.parse(text);
                    if (Array.isArray(parsed)) {
                        service.holidays = parsed;
                        service.dataUpdated();
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: readCustomProc
        command: ["cat", service.customEventsPath]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    let parsed = JSON.parse(text);
                    if (Array.isArray(parsed)) {
                        service.customEvents = parsed;
                        service.dataUpdated();
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: fetchProc
        onExited: {
            service.loadingHolidays = false;
            service.reloadHolidaysFromDisk();
        }
    }

    Process {
        id: saveCustomProc
    }

    Component.onCompleted: {
        reloadHolidaysFromDisk();
        reloadCustomEventsFromDisk();
        ensureYearLoaded(today.getFullYear());
    }
}
