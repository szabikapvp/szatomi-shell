import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../components"
import qs.config
import qs.services

Item {
    id: root

    property color color: Colors.text

    Layout.preferredWidth: Settings.px(18)
    Layout.preferredHeight: Settings.px(18)
    Layout.alignment: Qt.AlignVCenter

    Icon {
        icon: Network.icon
        color: root.color
    }
}