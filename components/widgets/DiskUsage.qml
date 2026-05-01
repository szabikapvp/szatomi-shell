import Quickshell
import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import "../../components"

import qs.service
import qs.config


RowLayout {

    property int textWidth: 42

    Item {

        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        
        Layout.alignment: Qt.AlignVCenter

        Icon {
            path: "file:///home/tomi/.config/quickshell/icons/disk.svg"
        }
    }

    Text {                        
        id: diskText
        text: Disk.getUsage() ? Disk.getUsage() + "%" : "--"
        color: Colors.text
        font.pixelSize: Settings.fontSize
        font.family: Settings.fontFamily
        font.bold: true
        Layout.preferredWidth: textWidth
        horizontalAlignment: Text.AlignHCenter
    } 
}