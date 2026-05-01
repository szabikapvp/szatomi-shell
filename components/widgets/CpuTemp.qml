import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../components/"

import qs.services
import qs.config

RowLayout {

    property int textWidth: 64

    Text {                        
        id: cpuText
        text: Processor.getTemp() ? Processor.getTemp() + " °C" : "--"
        color: Colors.text
        font.pixelSize: Settings.fontSize
        font.family: Settings.fontFamily
        font.bold: true
        Layout.preferredWidth: textWidth
        horizontalAlignment: Text.AlignHCenter
    } 
}