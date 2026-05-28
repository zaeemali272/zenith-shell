import QtQuick
import "../../"

Item {
    id: root
    
    property var candidates: []
    property int currentIndex: -1
    property string fallbackIcon: "image://icon/application-x-executable"
    property string appName: ""
    
    readonly property bool showLetter: icon.status !== Image.Ready || isBroken
    property bool isBroken: false

    function tryNext() {
        if (currentIndex >= candidates.length - 1) {
            isBroken = true;
            return;
        }
        
        currentIndex++;
        let next = candidates[currentIndex];
        if (next && next !== "") {
            isBroken = false;
            icon.source = next;
        } else {
            tryNext();
        }
    }
    
    onCandidatesChanged: {
        currentIndex = -1;
        isBroken = false;
        tryNext();
    }

    Image {
        id: icon
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        visible: !root.showLetter
        
        // Suppress errors to stop the massive log spam
        autoTransform: true
        
        onStatusChanged: {
            if (status === Image.Ready) {
                // If the icon provider returned the generic "not found" checkerboard
                if (icon.source.toString().startsWith("image://icon/") && (icon.implicitWidth === 100 || icon.implicitWidth === 128)) {
                    root.tryNext();
                }
            } else if (status === Image.Error) {
                root.tryNext();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.showLetter
        color: Theme.surface0
        radius: width / 4
        border.color: Theme.surface1
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: {
                if (!root.appName || root.appName === "") return "?";
                return root.appName.charAt(0).toUpperCase();
            }
            font.pixelSize: parent.height * 0.6
            font.bold: true
            color: Theme.mauve
        }
    }
}
