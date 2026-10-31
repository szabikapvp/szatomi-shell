import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"

import qs.services
import qs.config

RowLayout {
    id: root

    property int textWidth: Settings.px(64)
    property color color: Colors.text

    Text {                        
        id: cpuText
        text: Processor.getTemp() ? Processor.getTemp() + " °C" : "--"
        color: Processor.hot ? Colors.primary : root.color
        font.pixelSize: Settings.fontSize
        font.family: Settings.fontFamily
        font.bold: true
        Layout.preferredWidth: textWidth
        horizontalAlignment: Text.AlignHCenter
    } 
}