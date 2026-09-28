import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../Settings"
pragma Singleton

Singleton {
    id: service

    // --- Core Unified State ---
    property var trackedPlayer: null
    property bool isActuallyPlaying: false
    property real currentPos: 0
    property string currentTrackId: ""
    property bool mediaFocus: true

    property real _basePosSec: 0
    property double _baseTimeMs: 0

    function normalizeTimeSec(val) {
        let n = Number(val);
        if (isNaN(n) || n <= 0) return 0;
        
        // Thresholds based on max media length (12 hours = 43,200 seconds):
        // 1. Microseconds: > 43,200,000 (e.g. 1,044,000,000µs for 17min video) -> divide by 1,000,000
        // 2. Milliseconds: 43,200 < val <= 43,200,000 (e.g. 1,044,000ms for 17min video) -> divide by 1,000
        // 3. Seconds: <= 43,200 (e.g. 1044s for 17min video)
        if (n > 43200000) {
            return n / 1000000.0;
        } else if (n > 43200) {
            return n / 1000.0;
        }
        return n;
    }

    function getTrackLengthSec() {
        if (!trackedPlayer || !trackedPlayer.length) return 0;
        return normalizeTimeSec(trackedPlayer.length);
    }

    function syncPosition(rawPos) {
        if (!trackedPlayer) return;
        let posVal = (rawPos !== undefined) ? rawPos : trackedPlayer.position;
        let sec = normalizeTimeSec(posVal);
        _basePosSec = sec;
        _baseTimeMs = Date.now();
        currentPos = sec;
    }

    function getCurrentPosSec() {
        if (!trackedPlayer) return 0;
        
        let len = getTrackLengthSec();
        let pos = _basePosSec;
        
        if (isActuallyPlaying && _baseTimeMs > 0) {
            let elapsedSec = (Date.now() - _baseTimeMs) / 1000.0;
            pos = _basePosSec + elapsedSec;
        }
        
        if (len > 0 && pos > len) pos = len;
        return Math.max(0, pos);
    }

    function getProgressRatio() {
        let len = getTrackLengthSec();
        if (len <= 0) return 0;
        let pos = getCurrentPosSec();
        let ratio = pos / len;
        if (isNaN(ratio) || !isFinite(ratio)) return 0;
        return Math.max(0, Math.min(1, ratio));
    }
    
    // --- "Unbreakable" Variables ---
    property var _playerStack: ([])        
    property var _playerStates: ({})       
    property bool _initialized: false
    property bool _isResetting: false
    
    // --- Configuration: Fickle Sources ---
    readonly property var fickleIdentities: [
        "zen", "chrom", "fox", "brave", "vivaldi", "opera", "edge", 
        "chromium", "webkit", "anime", "youtube", "netflix", "twitch", "crunchyroll"
    ]
    
    // --- Configuration: Blacklist (Chat apps, etc) ---
    readonly property var blacklistIdentities: [
        "whatsapp", "telegram", "messenger", "discord", "slack", "chating", "chat"
    ]

    // --- Helper Logic ---
    function formatMediaTitle(title, identity) {
        if (!title) return "Unknown Media";
        let id = identity ? identity.toLowerCase() : "";
        
        if (id.includes("mpv") || id.includes("vlc") || id.includes("celluloid")) {
            title = title.replace(/\.(mp3|mp4|mkv|avi|flac|wav|ogg|webm|mov|m4a|wmv|mpg|mpeg)$/i, "");
            title = title.replace(/\s*[\(\[].*?[\)\]]/g, "");
        }
        
        title = title.replace(/ - YouTube$/i, "");
        title = title.replace(/ — Mozilla Firefox$/i, "");
        title = title.replace(/ - Google Chrome$/i, "");
        
        return title.trim() || "Media";
    }

    function formatMediaMetadata(fullText, limit, overflowThreshold) {
        if (!fullText) return "";
        let lim = limit || 34;
        let thresh = (overflowThreshold !== undefined) ? overflowThreshold : 5;
        
        if (fullText.length <= lim + thresh) {
            return fullText;
        }
        
        let target = fullText.substring(0, lim);
        let lastSpace = target.lastIndexOf(" ");
        if (lastSpace > 8) {
            return target.substring(0, lastSpace) + "...";
        }
        return target.substring(0, lim - 3) + "...";
    }

    function isFickle(player) {
        if (!player) return false;
        let id = player.identity.toLowerCase();
        let title = (player.trackTitle || "").toLowerCase();
        for (let i = 0; i < fickleIdentities.length; i++) {
            let term = fickleIdentities[i];
            if (id.includes(term) || title.includes(term)) return true;
        }
        return false;
    }
    
    function isBlacklisted(player) {
        if (!player) return false;
        let id = player.identity.toLowerCase();
        for (let i = 0; i < blacklistIdentities.length; i++) {
            if (id.includes(blacklistIdentities[i])) return true;
        }
        return false;
    }

    function manageFocus(newPlayer) {
        if (!newPlayer || !_initialized || !MediaSettings.autoManageMediaFocus || !service.mediaFocus) return;
        if (newPlayer.playbackState !== MprisPlaybackState.Playing) return;
        if (isBlacklisted(newPlayer)) return;

        let players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            let other = players[i];
            if (other && other !== newPlayer && other.playbackState === MprisPlaybackState.Playing) {
                if (service.trackedPlayer === other && !isBlacklisted(other)) {
                    let idx = _playerStack.indexOf(other);
                    if (idx !== -1) _playerStack.splice(idx, 1);
                    _playerStack.push(other);
                }
                other.pause();
            }
        }
    }

    function updateTrackedPlayer(newPlayer) {
        if (!newPlayer) return;
        
        if (newPlayer.playbackState === MprisPlaybackState.Playing) {
            manageFocus(newPlayer);
        }

        if (service.trackedPlayer !== newPlayer) {
            service.trackedPlayer = newPlayer;
            service.currentTrackId = ""; 
            syncPosition(newPlayer.position);
        }
    }

    // --- Heartbeat Engine ---
    Timer {
        id: engineTimer
        interval: 1000
        running: Mpris.players.values.length > 0
        repeat: true
        onTriggered: {
            let players = Mpris.players.values;

            if (!trackedPlayer) {
                isActuallyPlaying = false;
                return;
            }

            isActuallyPlaying = (trackedPlayer.playbackState === MprisPlaybackState.Playing);

            if (!_isResetting && trackedPlayer) {
                let rawSec = normalizeTimeSec(trackedPlayer.position || 0);
                if (rawSec > 0 && Math.abs(rawSec - getCurrentPosSec()) > 2.5) {
                    syncPosition(trackedPlayer.position);
                }
            }

            // Auto-focus onto active playing player if current tracked player stops
            if (!isActuallyPlaying && service.mediaFocus) {
                let active = players.find(p => p !== trackedPlayer && p.playbackState === MprisPlaybackState.Playing && !isBlacklisted(p));
                if (active) updateTrackedPlayer(active);
            }
        }
    }

    Timer {
        id: resetTimer
        repeat: false
        onTriggered: {
            if (trackedPlayer) currentPos = trackedPlayer.position;
            _isResetting = false;
        }
    }

    function triggerReset() {
        _isResetting = true;
        currentPos = 0;
        resetTimer.interval = isFickle(trackedPlayer) ? 2000 : 800;
        resetTimer.restart();
    }

    // --- Event Handlers ---
    Instantiator {
        model: Mpris.players
        onObjectAdded: (key, obj) => {
            if (service.mediaFocus && (!service.trackedPlayer || obj.playbackState === MprisPlaybackState.Playing))
                updateTrackedPlayer(obj);
        }
        onObjectRemoved: (key, obj) => {
            let idx = _playerStack.indexOf(obj);
            if (idx !== -1) _playerStack.splice(idx, 1);
            
            if (service.trackedPlayer === obj) {
                let players = Mpris.players.values;
                let next = players.find(p => p.playbackState === MprisPlaybackState.Playing && !isBlacklisted(p));
                
                service.trackedPlayer = next ? next : (players.length > 0 ? players[0] : null);
            }
        }
        delegate: Connections {
            target: modelData
            ignoreUnknownSignals: true
            
            function onPlaybackStateChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    updateTrackedPlayer(modelData);
                    if (service.trackedPlayer === modelData) service.syncPosition(modelData.position);
                } else if (service.trackedPlayer === modelData && service.mediaFocus) {
                    let players = Mpris.players.values;
                    let active = players.find(p => p !== modelData && p.playbackState === MprisPlaybackState.Playing && !isBlacklisted(p));
                    
                    if (active) {
                        updateTrackedPlayer(active);
                    }
                }
            }
            
            function onMetadataChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    updateTrackedPlayer(modelData);
                }
                
                if (service.trackedPlayer === modelData) {
                    let newId = String(modelData.trackTitle + modelData.trackArtist);
                    if (newId !== service.currentTrackId) {
                        service.currentTrackId = newId;
                        service.triggerReset();
                    }
                }
            }

            function onPositionChanged() {
                if (service.trackedPlayer === modelData && !service._isResetting) {
                    service.syncPosition(modelData.position);
                }
            }
        }
    }

    Timer {
        id: initTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: _initialized = true
    }

    Component.onCompleted: {
        if (!service.mediaFocus) return;
        let players = Mpris.players.values;
        let active = players.find(p => p.playbackState === MprisPlaybackState.Playing && !isBlacklisted(p));
        if (active) {
            updateTrackedPlayer(active);
        } else if (players.length > 0) {
            trackedPlayer = players[0];
        }
    }
}
