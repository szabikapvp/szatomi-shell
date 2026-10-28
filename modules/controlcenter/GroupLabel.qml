import QtQuick
import QtQuick.Layouts

import qs.config

// Small heading over a group of settings on a page
Text {
    Layout.fillWidth: true
    Layout.topMargin: Settings.spacing
    Layout.leftMargin: Settings.spacing * 1.5

    color: Qt.alpha(Colors.text, 0.5)
    font.pixelSize: Settings.fontSize - Settings.px(4)
    font.family: Settings.fontFamily
    font.bold: true
}
