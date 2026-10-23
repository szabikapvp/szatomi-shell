import QtQuick
import Quickshell

ButtonTile {
    id: root

    icon: "power"
    text: "Power"
    subtext: Quickshell.env("USER") ?? ""

    // Nothing to toggle, so the icon opens the page too
    onClicked: root.pageRequested()
}
