import QtQuick
import Quickshell

Image {
    id: root
    
    property var candidates: []
    property int currentIndex: -1
    property string fallbackIcon: "image://icon/application-x-executable"
    
    fillMode: Image.PreserveAspectFit
    smooth: true
    asynchronous: true
    
    function tryNext() {
        if (currentIndex >= candidates.length - 1) {
            if (source.toString() !== fallbackIcon) {
                source = fallbackIcon;
            }
            return;
        }
        
        currentIndex++;
        let next = candidates[currentIndex];
        if (next && next !== "") {
            source = next;
        } else {
            tryNext();
        }
    }
    
    onCandidatesChanged: {
        currentIndex = -1;
        tryNext();
    }
    
    onStatusChanged: {
        if (status === Image.Ready) {
            // Match NotificationItem.qml detection logic
            if (implicitWidth === 100 && implicitHeight === 100 && source.toString().includes("image://icon/")) {
                tryNext();
            } else if (implicitWidth <= 2) {
                tryNext();
            }
        } else if (status === Image.Error) {
            tryNext();
        }
    }
}
