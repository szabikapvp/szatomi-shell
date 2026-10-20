import Quickshell
import QtQuick
import QtQuick.Layouts

import qs.config

Text {
    id:root

    Layout.preferredWidth: 84
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