pragma Singleton
import "."
import QtQuick

QtObject {
    property string backgroundStyle: "pills" // "full" or "pills"
    property string displayStyle: "hybrid" // "numbers", "icons", or "hybrid"
    property int height: 10
    property int activeWidth: 42
    property int inactiveWidth: 10
    property int spacing: 6
    property int barMargins: 10
}
