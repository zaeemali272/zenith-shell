import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." 

PopupWindow {
    id: root
    visible: false

    Loader {
        id: themeLoader
        source: "../ThemeLoader.qml"
    }

    implicitWidth: themeLoader.item ? themeLoader.item.scaled(300) : 300
    implicitHeight: themeLoader.item ? themeLoader.item.scaled(150) : 150
    color: "transparent"
    
    // Position it at the bottom-right
    anchor.rect: Qt.rect(Quickshell.screens[0].width - implicitWidth - 50, Quickshell.screens[0].height - implicitHeight - 50, 0, 0)

    Rectangle {
        anchors.fill: parent
        color: Theme.menuBackground
        radius: themeLoader.item ? themeLoader.item.scaled(16) : 16
        border.color: Theme.surface1
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: themeLoader.item ? themeLoader.item.scaled(20) : 20
            spacing: themeLoader.item ? themeLoader.item.scaled(10) : 10
            
            Text {
                text: "Theme Generated!"
                color: Theme.text
                font.bold: true
                font.pixelSize: themeLoader.item ? themeLoader.item.scaled(16) : 16
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: "Pick an accent color (Defaults to first)"
                color: Theme.subtext0
                font.pixelSize: themeLoader.item ? themeLoader.item.scaled(12) : 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: themeLoader.item ? themeLoader.item.scaled(10) : 10
                
                Repeater {
                    model: [Theme.primary, Theme.secondary, Theme.tertiary]
                    delegate: Rectangle {
                        width: themeLoader.item ? themeLoader.item.scaled(40) : 40; height: themeLoader.item ? themeLoader.item.scaled(40) : 40; radius: themeLoader.item ? themeLoader.item.scaled(20) : 20
                        color: modelData
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                themeLoader.item.setAccent(index);
                                root.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Automatically select the first color and close
    Component.onCompleted: {
        // Fallback for when loader is not yet ready
        if (themeLoader.item) {
            themeLoader.item.setAccent(0);
        } else {
            themeLoader.loaded.connect(function() { themeLoader.item.setAccent(0); });
        }
        
        // Timer to close after 5s if no selection made
        Qt.createQmlObject('import QtQuick; Timer { interval: 5000; running: true; onTriggered: root.visible = false }', root);
    }
}
