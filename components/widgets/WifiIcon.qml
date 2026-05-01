import QtQuick
import QtQuick.Controls
import Quickshell
import "../../components"
import qs.services

Item {
    id: root
    width: 18
    height: 18

    // cursorShape: Qt.PointingHandCursor
    // onClicked: Quickshell.execDetached(["kitty", "--class", "nmtui-float", "nmtui"])

    Icon {
        icon: Network.icon
    }
}