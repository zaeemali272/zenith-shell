import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import Quickshell.Notifications

Window {
    visible: true
    width: 400
    height: 300
    title: "Test Notification Emitter"

    Button {
        text: "Send Test Notification"
        anchors.centerIn: parent
        onClicked: {
            Notifications.send("Test App", "Test Summary", "This is a test notification body from Quickshell.", {
                "category": "test",
                "urgency": 1 // Normal
            });
            console.log("Test notification sent!");
        }
    }

    Component.onCompleted: {
        console.log("Test Notification Emitter started. Click the button to send a notification.");
    }
}
