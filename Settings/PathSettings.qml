pragma Singleton
import "."
import QtQuick
import Quickshell

QtObject {
    readonly property string home: Quickshell.env("HOME")
    readonly property string shellDir: Quickshell.env("ZENITH_ROOT") || (home + "/.config/quickshell")
    readonly property string scriptsDir: shellDir + "/scripts"
    readonly property string configDir: home + "/.config"
    readonly property string cacheDir: home + "/.cache"
}
