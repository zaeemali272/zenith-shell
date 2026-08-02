pragma Singleton
import QtQuick

QtObject {
    // Configurable intervals for recurring & repeating tasks (ms)
    property int fastPollInterval: 1000       // Telemetry, resource monitoring, active network bandwidth
    property int mediumPollInterval: 3000     // Active menu refreshes, MPRIS media updates
    property int slowPollInterval: 10000      // Background WiFi/Bluetooth status when popups closed
    property int lazyPollInterval: 60000      // System updates, battery check
    property int idlePollInterval: 300000     // Weather, calendar sync (5 mins)
    
    // Dynamic adaptive polling rate toggle
    property bool adaptivePollingEnabled: true
}
