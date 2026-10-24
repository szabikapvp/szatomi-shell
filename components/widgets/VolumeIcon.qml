import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../components"

import qs.config
import qs.services

Item {
    id: root

    property color color: Colors.text

    Layout.preferredWidth: 18
    Layout.preferredHeight: 18
    Layout.alignment: Qt.AlignVCenter

    Icon {
        icon: Audio.icon
        color: root.color
    }
}