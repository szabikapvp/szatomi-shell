pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property string wallpaper: ""

    property int fontSize: 16
    property string fontFamily: "Bricolage Grotesque"
    property string headerFont: "Dela Gothic One"

    property int barMargin: 8
    property int gap: 10

    property int radiusSm: 8
    property int radiusMd: 16
    property int radiusLg: 32

    property string dateFormat: "MM/dd ddd"
    property string timeFormat: "h:mm"

}