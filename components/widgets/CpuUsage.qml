import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../"

import qs.services
import qs.config

RowLayout {

    property int textWidth: Settings.px(42)

    Item {

        Layout.preferredWidth: Settings.px(18)
        Layout.preferredHeight: Settings.px(18)
        
        Layout.alignment: Qt.AlignVCenter

        Icon {
            icon: "cpu"
        }
    }

    Text {                        
        id: cpuText
        text: Processor.getUsage() ? Processor.getUsage() + "%" : "--"
        color: Colors.text
        font.pixelSize: Settings.fontSize
        font.family: Settings.fontFamily
        font.bold: true
        Layout.preferredWidth: textWidth
        horizontalAlignment: Text.AlignHCenter
    } 
}