import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../components"

import qs.config

// The time scales to fill the tile, tall tiles stack the hours over the minutes
Tile {
    id: root

    readonly property bool tall: rows > columns

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Settings.spacing * 2
        spacing: Settings.spacing

        StyledText {
            Layout.fillWidth: true
            Layout.fillHeight: true

            text: {
                const time = Qt.formatDateTime(clock.date, Settings.timeFormat)
                return root.tall ? time.replace(":", "\n") : time
            }
            color: Colors.text
            font.pixelSize: root.height
            font.bold: true
            fontSizeMode: Text.Fit
            minimumPixelSize: Settings.fontSize
            lineHeight: 0.9
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        StyledText {
            Layout.fillWidth: true

            text: Qt.formatDateTime(clock.date, Settings.longDateFormat)
            color: Qt.alpha(Colors.text, 0.6)
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize - Settings.px(2)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
