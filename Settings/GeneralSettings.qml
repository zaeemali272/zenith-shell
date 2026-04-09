import QtQuick
import Quickshell
pragma Singleton

QtObject {
    // Enable / Disable features
    property bool enableNotifications: true
    property bool enableMedia: true
    property bool enableWeather: true
    property bool enableTodoList: true
    property bool enableResources: true
    property bool enablePowerProfiles: true
    
    // Bar settings
    property bool barEntryAnimation: true
    property int barAnimationDuration: 800
    
    // Quick Settings
    property int debounceInterval: 500
    property int hideTimerInterval: 300
    
    // Media settings
    property bool truncateTrackTitle: true
    property int maxTrackTitleLength: 85
}
