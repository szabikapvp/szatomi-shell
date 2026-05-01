import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../components"

import qs.services
import qs.config

RowLayout {

    property int textWidth: 42

    Item {

        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        
        Layout.alignment: Qt.AlignVCenter

        Icon {
            icon: "ram"
        }
    }

    Text {                        
        id: memText
        text: Memory.getUsage() ? Memory.getUsage() + "%" : "--"
        color: Colors.text
        font.pixelSize: Settings.fontSize
        font.family: Settings.fontFamily
        font.bold: true
        Layout.preferredWidth: textWidth
        horizontalAlignment: Text.AlignHCenter
    } 
}