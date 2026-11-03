import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../components"

import qs.config

StyledText {
    id:root

    Layout.preferredWidth: Settings.barDateWidth
    tabular: false
    horizontalAlignment: Text.AlignRight

    text: Qt.formatDateTime(new Date(), Settings.dateFormat)
    color: Colors.text
    font.pixelSize: Settings.fontSize
    font.family: Settings.fontFamily
    font.weight: 500

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.text = Qt.formatDateTime(new Date(), Settings.dateFormat)
        }
    }
}