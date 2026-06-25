pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: service

    property string configDir: Quickshell.env("HOME") + "/.config/quickshell"
    property string ppPath: configDir + "/profilePicture"
    
    property string username: "Zaeem"
    property string location: "Lahore, Pakistan"
    
    signal profilePictureChanged()

    onUsernameChanged: save()
    onLocationChanged: save()

    Component.onCompleted: {
        setupProc.running = true;
        whoamiProc.running = true;
        load();
    }

    Process {
        id: setupProc
        command: ["mkdir", "-p", configDir]
    }

    Process {
        id: whoamiProc
        command: ["whoami"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (service.username === "Zaeem") { 
                    let name = text.trim();
                    if (name !== "") service.username = name;
                }
            }
        }
    }

    function updateProfilePicture() {
        profilePictureChanged();
    }

    function save() {
        let data = {
            username: username,
            location: location
        };
        let dataStr = JSON.stringify(data).replace(/'/g, "'\\''");
        saveProc.command = ["sh", "-c", "mkdir -p " + configDir + " && echo '" + dataStr + "' > " + configDir + "/user.json"];
        saveProc.running = true;
    }

    function load() {
        loadProc.running = true;
    }

    Process {
        id: loadProc
        command: ["cat", configDir + "/user.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(text);
                    if (data.username) service.username = data.username;
                    if (data.location) service.location = data.location;
                } catch (e) {}
            }
        }
    }

    Process { id: saveProc }
}
