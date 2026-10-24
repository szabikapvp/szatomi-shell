import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../components"

import qs.config
import qs.services

Item {
    
    Layout.preferredWidth: Settings.px(18)
    Layout.preferredHeight: Settings.px(18)
    Layout.alignment: Qt.AlignVCenter

    Icon {
        icon: Brightness.icon
    }
}