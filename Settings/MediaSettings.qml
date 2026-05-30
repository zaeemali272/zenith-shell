pragma Singleton
import "."
import QtQuick

QtObject {
    property bool truncateTrackTitle: true
    property int maxTrackTitleLength: 85
    property bool autoManageMediaFocus: true
}
