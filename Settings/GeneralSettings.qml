pragma Singleton
import "."
import QtQuick

QtObject {
    // Feature Toggles
    property bool enableMedia: true
    property bool enableWeather: true
    property bool enableTodoList: true
    property bool enableResources: true
    property bool enablePowerProfiles: true

    // Location & Calendar
    property bool autoDetectCountry: true
    property string customCountryCode: "PK"
    property int firstDayOfWeek: 0        // 0 = Sunday, 1 = Monday, 6 = Saturday
    property bool showWeekNumbers: false
    property bool showHolidays: true
    
    // Quick Settings
    property int debounceInterval: 200
    property int hideTimerInterval: 250
}
