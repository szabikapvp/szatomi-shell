import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../components"

import qs.services

Item {
    
    Layout.preferredWidth: 18
    Layout.preferredHeight: 18
    Layout.alignment: Qt.AlignVCenter

    Icon {
        icon: {
            if (Brightness.getLevel() <= 30) return "brightness-1"
            if (Brightness.getLevel() <= 60) return "brightness-2"
            return "brightness-3"
        }
    }
}