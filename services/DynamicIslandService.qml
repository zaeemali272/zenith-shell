import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

QtObject {
    id: root

    property string activeMode: "" // "", "launcher", "clipboard", "emoji"
    readonly property bool active: activeMode !== ""
    property string query: ""
    property int selectedIndex: 0
    property string selectedCategory: "All"

    // --- LAUNCHER DATA ---
    property string storagePath: Quickshell.env("HOME") + "/.config/quickshell/app_usage.json"
    property var usageMap: ({})
    property var allAppsCache: []
    property var displayedApps: []

    // --- CLIPBOARD DATA ---
    property var rawClipHistory: []
    property var displayedClips: []

    // --- EMOJI DATA ---
    property var allEmojisCache: []
    property var displayedEmojis: []
    readonly property string jsonPath: (Quickshell.env("ZENITH_ROOT") || (Quickshell.env("HOME") + "/.config/quickshell")) + "/assets/emojis.json"
    readonly property var emojiCategories: ["All", "Smileys", "People", "Animals", "Food", "Activities", "Travel", "Objects", "Symbols", "Flags"]

    // --- HELPER PROCESSES ---
    property var shellProc: Process { id: execProc }

    // Desktop entries connection
    property var appConn: Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.rebuildAppCache(); }
        function onRowsInserted() { root.rebuildAppCache(); }
        function onModelReset() { root.rebuildAppCache(); }
    }

    // App usage loader
    property var loadUsageProc: Process {
        id: loadUsage
        command: ["cat", root.storagePath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.usageMap = JSON.parse(text) || {};
                } catch(e) {
                    root.usageMap = {};
                }
                if (root.activeMode === "launcher") root.rebuildFiltered();
            }
        }
        onExited: (code) => {
            if (code !== 0 && root.activeMode === "launcher") root.rebuildFiltered();
        }
    }

    // App usage saver
    property var saveUsageProc: Process { id: saveUsage }

    // Cliphist loader
    property var loadClipProc: Process {
        id: loadClip
        command: ["sh", "-c", "cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseCliphistOutput(text);
            }
        }
    }

    // Emoji loader
    property var loadEmojiProc: Process {
        id: loadEmoji
        command: ["cat", root.jsonPath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text) || [];
                    root.buildEmojiCache(parsed);
                } catch(e) {
                    root.allEmojisCache = [];
                    root.rebuildFiltered();
                }
            }
        }
    }

    Component.onCompleted: {
        rebuildAppCache();
        loadUsage.running = true;
    }

    // --- CONTROLS ---

    function open(mode) {
        let validMode = mode || "launcher";
        if (validMode !== "launcher" && validMode !== "clipboard" && validMode !== "emoji") {
            validMode = "launcher";
        }
        
        if (typeof CenterState !== "undefined") CenterState.close();
        if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();

        query = "";
        selectedIndex = 0;
        selectedCategory = "All";
        activeMode = validMode;

        if (validMode === "launcher") {
            if (allAppsCache.length === 0) rebuildAppCache();
            else rebuildFiltered();
        } else if (validMode === "clipboard") {
            loadClipHistory();
        } else if (validMode === "emoji") {
            if (allEmojisCache.length === 0) {
                loadEmoji.running = false;
                loadEmoji.running = true;
            } else {
                rebuildFiltered();
            }
        }
    }

    function close() {
        activeMode = "";
        query = "";
        selectedIndex = 0;
    }

    function toggle(mode) {
        if (activeMode === mode || (mode === "" && active)) {
            close();
        } else {
            open(mode);
        }
    }

    function setMode(mode) {
        if (activeMode === mode) return;
        query = "";
        selectedIndex = 0;
        activeMode = mode;
        if (mode === "clipboard" && rawClipHistory.length === 0) {
            loadClipHistory();
        } else if (mode === "emoji" && allEmojisCache.length === 0) {
            loadEmoji.running = false;
            loadEmoji.running = true;
        } else {
            rebuildFiltered();
        }
    }

    function cycleMode() {
        if (activeMode === "launcher") setMode("clipboard");
        else if (activeMode === "clipboard") setMode("emoji");
        else setMode("launcher");
    }

    function setCategory(cat) {
        selectedCategory = cat;
        selectedIndex = 0;
        rebuildFiltered();
    }

    // --- REBUILD FILTERED RESULTS ---

    function rebuildFiltered() {
        selectedIndex = 0;
        if (activeMode === "launcher") rebuildLauncherFiltered();
        else if (activeMode === "clipboard") rebuildClipboardFiltered();
        else if (activeMode === "emoji") rebuildEmojiFiltered();
    }

    // --- LAUNCHER LOGIC ---

    function rebuildAppCache() {
        let rawApps = DesktopEntries.applications.values || [];
        let cache = [];

        for (let i = 0; i < rawApps.length; i++) {
            let entry = rawApps[i];
            if (!entry || !entry.name || entry.noDisplay) continue;

            let name = entry.name || "";
            let appId = entry.id || "";
            let genericName = entry.genericName || "";
            let comment = entry.comment || "";
            let categories = entry.categories || "";

            cache.push({
                entry: entry,
                id: appId,
                name: name,
                icon: entry.icon || "",
                genericName: genericName,
                comment: comment,
                searchKey: (name + " " + appId + " " + genericName + " " + comment + " " + categories).toLowerCase()
            });
        }

        allAppsCache = cache;
        if (activeMode === "launcher") rebuildLauncherFiltered();
    }

    function evalMath(expr) {
        try {
            let clean = expr.trim();
            if (!/^[\d\s\+\-\*\/\%\(\)\.\^]+$/.test(clean)) return null;
            if (!/[\+\-\*\/\%\^]/.test(clean)) return null;
            
            clean = clean.replace(/\^/g, '**');
            let val = Function('"use strict"; return (' + clean + ')')();
            if (typeof val === "number" && !isNaN(val) && isFinite(val)) {
                let formatted = Number.isInteger(val) ? val.toString() : val.toFixed(4).replace(/\.?0+$/, '');
                return formatted;
            }
        } catch(e) {}
        return null;
    }

    function rebuildLauncherFiltered() {
        let q = query.toLowerCase().trim();

        if (q === "") {
            displayedApps = [];
            return;
        }

        let results = [];

        // Math calculation
        let mathRes = evalMath(query);
        if (mathRes !== null) {
            results.push({
                isMath: true,
                result: mathRes,
                name: query.trim() + " = " + mathRes,
                genericName: "Calculation Result (Press Enter to copy)",
                icon: "calculator",
                id: "math_calc",
                score: 100000
            });
        }

        // Filter pre-indexed apps
        for (let i = 0; i < allAppsCache.length; i++) {
            let app = allAppsCache[i];
            let nameLower = app.name.toLowerCase();
            let idLower = app.id.toLowerCase();

            if (app.searchKey.includes(q)) {
                let usage = usageMap[app.id] || 0;
                let score = usage * 1000;

                if (nameLower === q) score += 5000;
                else if (nameLower.startsWith(q)) score += 2000;
                else if (nameLower.includes(q)) score += 1000;
                else if (idLower.includes(q)) score += 500;

                results.push({
                    isMath: false,
                    entry: app.entry,
                    id: app.id,
                    name: app.name,
                    icon: app.icon,
                    genericName: app.genericName,
                    comment: app.comment,
                    score: score
                });
            }
        }

        results.sort((a, b) => {
            if (b.score !== a.score) return b.score - a.score;
            return a.name.localeCompare(b.name);
        });

        displayedApps = results.slice(0, 4);
    }

    function saveAppUsage() {
        saveUsage.command = [
            "python3", "-c",
            "import json, os, sys; p=sys.argv[1]; d=sys.argv[2]; os.makedirs(os.path.dirname(p), exist_ok=True); f=open(p, 'w'); f.write(d); f.close()",
            storagePath,
            JSON.stringify(usageMap)
        ];
        saveUsage.running = true;
    }

    function recordAppUsage(appId) {
        if (!appId) return;
        let count = usageMap[appId] || 0;
        usageMap[appId] = count + 1;
        saveAppUsage();
    }

    function launchApp(appItem) {
        if (!appItem) return;
        
        if (appItem.isMath) {
            execProc.command = ["sh", "-c", "echo -n '" + appItem.result + "' | wl-copy 2>/dev/null || true"];
            execProc.running = true;
            close();
            return;
        }

        if (appItem.entry) {
            recordAppUsage(appItem.id);
            appItem.entry.execute();
            close();
        }
    }

    // --- CLIPBOARD LOGIC ---

    function loadClipHistory() {
        loadClip.running = false;
        loadClip.running = true;
    }

    function parseCliphistOutput(text) {
        if (!text) {
            rawClipHistory = [];
            rebuildClipboardFiltered();
            return;
        }

        let lines = text.split("\n");
        let items = [];

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            if (!line.trim()) continue;

            let tabIdx = line.indexOf("\t");
            if (tabIdx !== -1) {
                let clipId = line.substring(0, tabIdx).trim();
                let clipText = line.substring(tabIdx + 1);

                items.push({
                    id: clipId,
                    preview: clipText,
                    searchKey: clipText.toLowerCase()
                });
            }
        }

        rawClipHistory = items;
        rebuildClipboardFiltered();
    }

    function rebuildClipboardFiltered() {
        let q = query.toLowerCase().trim();

        if (q === "") {
            displayedClips = rawClipHistory.slice(0, 15);
            return;
        }

        let results = [];
        for (let i = 0; i < rawClipHistory.length; i++) {
            let item = rawClipHistory[i];
            if (item.searchKey.includes(q)) {
                results.push(item);
            }
        }

        displayedClips = results.slice(0, 15);
    }

    function copyClipItem(clipItem) {
        if (!clipItem || !clipItem.id) return;
        execProc.command = ["sh", "-c", "cliphist decode " + clipItem.id + " | wl-copy"];
        execProc.running = true;
        close();
    }

    function deleteClipItem(clipItem) {
        if (!clipItem || !clipItem.id) return;
        execProc.command = ["sh", "-c", "cliphist delete <<'EOF'\n" + clipItem.id + "\t" + clipItem.preview + "\nEOF"];
        execProc.running = true;
        loadClipHistory();
    }

    // --- EMOJI LOGIC ---

    function buildEmojiCache(rawList) {
        let cache = [];
        for (let i = 0; i < rawList.length; i++) {
            let item = rawList[i];
            if (!item) continue;
            let emojiChar = item.char || item.emoji || "";
            if (!emojiChar) continue;
            let name = item.name || "";
            let category = item.cat || item.category || "All";
            let keywords = Array.isArray(item.tags || item.keywords) ? (item.tags || item.keywords).join(" ") : (item.tags || item.keywords || "");

            cache.push({
                emoji: emojiChar,
                name: name,
                category: category,
                keywords: keywords,
                searchKey: (name + " " + category + " " + keywords).toLowerCase()
            });
        }
        allEmojisCache = cache;
        rebuildEmojiFiltered();
    }

    function rebuildEmojiFiltered() {
        let q = query.toLowerCase().trim();
        let cat = selectedCategory;

        let results = [];
        for (let i = 0; i < allEmojisCache.length; i++) {
            let item = allEmojisCache[i];
            
            if (cat !== "All" && item.category !== cat) continue;

            if (q === "" || item.searchKey.includes(q)) {
                results.push(item);
            }
        }

        displayedEmojis = results.slice(0, 120);
    }

    function copyEmoji(emojiChar) {
        if (!emojiChar) return;
        execProc.command = ["sh", "-c", "echo -n '" + emojiChar + "' | wl-copy"];
        execProc.running = true;
        close();
    }
}
