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
            if (Audio.isMuted) return "volume-mute"
            if (Audio.getLevel() < 20) return "volume-0"
            if (Audio.getLevel() < 50) return "volume-1"
            return "volume-2"
        }
    }
}