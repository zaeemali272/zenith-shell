import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../Settings"
pragma Singleton

Singleton {
    id: service

    property var trackedPlayer: null
    property var lastPlayer: null
    property bool _initialized: false

    Timer {
        id: initTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: service._initialized = true
    }

    function updateTrackedPlayer(newPlayer) {
        if (!newPlayer) return;
        
        if (service.trackedPlayer !== newPlayer) {
            service.trackedPlayer = newPlayer;
        }

        if (newPlayer.playbackState === MprisPlaybackState.Playing && service._initialized && GeneralSettings.autoManageMediaFocus) {
            let players = Mpris.players.values;
            for (let i = 0; i < players.length; i++) {
                let other = players[i];
                if (other && other !== newPlayer && other.playbackState === MprisPlaybackState.Playing) {
                    service.lastPlayer = other;
                    other.pause();
                }
            }
        }
    }

    Instantiator {
        model: Mpris.players
        onObjectAdded: (key, obj) => {
            if (!service.trackedPlayer || obj.playbackState === MprisPlaybackState.Playing)
                service.updateTrackedPlayer(obj);
        }
        onObjectRemoved: (key, obj) => {
            if (service.trackedPlayer === obj) {
                let players = Mpris.players.values;
                let active = players.find(p => p.playbackState === MprisPlaybackState.Playing);
                service.trackedPlayer = active ? active : (players.length > 0 ? players[0] : null);
            }
            if (service.lastPlayer === obj) {
                service.lastPlayer = null;
            }
        }
        delegate: Connections {
            target: modelData
            ignoreUnknownSignals: true
            
            function onPlaybackStateChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    updateTrackedPlayer(modelData);
                } else if (service.trackedPlayer === modelData) {
                    if (modelData.playbackState === MprisPlaybackState.Paused || modelData.playbackState === MprisPlaybackState.Stopped) {
                        let players = Mpris.players.values;
                        let active = players.find(p => p.playbackState === MprisPlaybackState.Playing);
                        if (active) {
                            updateTrackedPlayer(active);
                        } else if (service.lastPlayer && GeneralSettings.autoManageMediaFocus) {
                            let stillExists = false;
                            for (let i = 0; i < players.length; i++) {
                                if (players[i] === service.lastPlayer) {
                                    stillExists = true;
                                    break;
                                }
                            }
                            if (stillExists) {
                                if (service.lastPlayer.playbackState !== MprisPlaybackState.Playing) {
                                    service.lastPlayer.play();
                                    service.trackedPlayer = service.lastPlayer;
                                    service.lastPlayer = null;
                                }
                            } else {
                                service.lastPlayer = null;
                            }
                        }
                    }
                }
            }
            
            function onMetadataChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    updateTrackedPlayer(modelData);
                }
            }
        }
    }

    Component.onCompleted: {
        let players = Mpris.players.values;
        let active = players.find(p => p.playbackState === MprisPlaybackState.Playing);
        service.trackedPlayer = active ? active : (players.length > 0 ? players[0] : null);
    }
}
