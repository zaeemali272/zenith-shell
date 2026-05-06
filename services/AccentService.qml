import QtQuick
import ".."

pragma Singleton
QtObject {
    signal requestColorPopup()
    
    property int activeColorIndex: 0
    property var colors: [Theme.primary, Theme.secondary, Theme.tertiary]
    
    function setAccent(index) {
        activeColorIndex = index;
        console.log("[Theme]: Accent set to " + colors[index]);
    }
}
