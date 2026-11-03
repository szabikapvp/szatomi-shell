import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../components"

import qs.config

StyledText {
    id: root

    property int fontSize: Settings.fontSize
    property int weight: 700

    Layout.preferredWidth: Settings.barTimeWidth
    tabular: false
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: Qt.formatDateTime(new Date(), Settings.timeFormat)
    color: Colors.text
    font.pixelSize: fontSize
    font.family: Settings.fontFamily
    font.weight: weight

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.text = Qt.formatDateTime(new Date(), Settings.timeFormat)
        }
    }
}