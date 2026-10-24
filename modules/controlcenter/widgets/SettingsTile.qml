import QtQuick

ButtonTile {
    id: root

    icon: "settings"
    text: "Settings"
    subtext: "Customize"

    // Nothing to toggle, so the icon opens the page too
    onClicked: root.pageRequested()
}
