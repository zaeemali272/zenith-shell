pragma Singleton
import "."
import QtQuick

QtObject {
    property string backgroundStyle: "pills" // "full" or "pills"
    property string displayStyle: "numbers" // "numbers" or "icons"
    property int height: 10
    property int activeWidth: 42
    property int inactiveWidth: 10
    property int spacing: 6
    property int barMargins: 10
}
