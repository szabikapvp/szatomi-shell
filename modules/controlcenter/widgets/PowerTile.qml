import QtQuick
import Quickshell

import qs.services

ButtonTile {
    id: root

    icon: "power"
    text: "Power"
    subtext: Quickshell.env("USER") ?? ""

    // The whole tile opens the power menu
    onClicked: Power.toggleMenu()
    onPageRequested: Power.toggleMenu()
}
