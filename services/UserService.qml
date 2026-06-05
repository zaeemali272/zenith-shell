pragma Singleton
import QtQuick
import Quickshell

QtObject {
    property string ppPath: Quickshell.env("HOME") + "/.config/quickshell/profilePicture"
    
    signal profilePictureChanged()

    function updateProfilePicture() {
        profilePictureChanged();
    }
}
