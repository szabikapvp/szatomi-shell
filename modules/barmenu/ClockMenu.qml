import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"

import qs.config

// The time to the second, with the full date. A fixed width, so the time's proportional digits don't resize the panel
ColumnLayout {
    width: Settings.barMenuWidth
    spacing: 0

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    StyledText {
        // Seconds go right after the minutes, so 12 hour formats keep their AM/PM at the end
        text: Qt.formatDateTime(clock.date, Settings.timeFormat.replace("mm", "mm:ss"))
        tabular: false
        color: Colors.text
        font.pixelSize: Settings.fontSize * 2.5
        font.bold: true
        Layout.alignment: Qt.AlignHCenter
    }

    StyledText {
        text: Qt.formatDateTime(clock.date, Settings.longDateFormat)
        color: Qt.alpha(Colors.text, 0.6)
        font.family: Settings.fontFamily
        font.pixelSize: Settings.fontSize
        font.bold: true
        Layout.alignment: Qt.AlignHCenter
    }
}
