import QtQuick
import "../../" as Shell

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
        
        onStatusChanged: {
            if (status === Image.Ready) {
                let src = source.toString();
                if ((implicitWidth === 100 || implicitWidth === 128) && 
                    (implicitHeight === 100 || implicitHeight === 128) && 
                    src.includes("image://icon/")) {
                    root.tryNext();
                } else if (implicitWidth <= 2) {
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
        color: (Shell.Theme && Shell.Theme.surface0) ? Shell.Theme.surface0 : "#313244"
        radius: width / 4
        border.color: (Shell.Theme && Shell.Theme.surface1) ? Shell.Theme.surface1 : "#45475a"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: {
                if (!root.appName || root.appName === "") return "?";
                return root.appName.charAt(0).toUpperCase();
            }
            font.pixelSize: parent.height * 0.6
            font.bold: true
            color: (Shell.Theme && Shell.Theme.mauve) ? Shell.Theme.mauve : "#cba6f7"
        }
    }
}
