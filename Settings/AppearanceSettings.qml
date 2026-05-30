pragma Singleton
import "."
import QtQuick

QtObject {
    id: appearanceSettings
    property real menuOpacity: 0.7
    property real glassBlur: 200
    property int fontSize: 13
    property int iconSize: 14
    property string iconFont: "MesloLGS NF"
    property int menuRadius: 24
    property int menuPadding: 20
    property int menuSpacing: 15
    property string iconTheme: "Adwaita"
}
