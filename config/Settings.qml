pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property string wallpaper: ""

    property int fontSize: 16
    property string fontFamily: "Space Grotesk"
    property string headerFont: "Dela Gothic One"

    property int windowSpacing: 8
    property int spacing: 10

    property int radiusSm: 8
    property int radiusMd: 16
    property int radiusLg: 32

    property int spinnerSize: 24

    property string dateFormat: "MM/dd ddd"
    property string timeFormat: "h:mm"

    // BAR

    property int barHeight: 44
    property string barPosition: "bottom"
    property bool barFloating: false
    property int workspaceCount: 9

    // OSD

    property int osdYPosition: barPosition == "bottom"
        ? barHeight + (windowSpacing * 2)
        : windowSpacing * 2

    // CONTROL CENTER

    property int wifiPageHeight: 500
    property int wifiRescanDelay: 1500
}