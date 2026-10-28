import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../components/widgets"

import qs.config
import qs.services
import qs.utils

// Asks to keep changed display settings, on every screen, since the control center may have moved or closed when
// displays came and went. The one on the focused screen takes the keyboard: Enter on Revert, Escape reverts too
PanelWindow {
    id: root

    property var modelData
    screen: modelData

    readonly property bool focused: Hyprland.focusedMonitor?.name == modelData?.name

    anchors.top: true
    margins.top: Settings.windowSpacing * 2

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Displays.pending && focused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    visible: Displays.pending || card.opacity > 0
    implicitWidth: card.width
    implicitHeight: card.height

    onVisibleChanged: if (visible && focused) revert.forceActiveFocus()

    Rectangle {
        id: card

        // The same inset all round, so the round Keep button sits evenly in the round card. The text adds its own on the left
        width: row.implicitWidth + Settings.spacing * 2
        height: row.implicitHeight + Settings.spacing * 2
        radius: height / 2
        color: Colors.background
        border.width: 1
        border.color: Colors.backgroundSubtle

        opacity: Displays.pending ? 1 : 0
        Behavior on opacity { Fade {} }

        // Reached from either button, keys they don't use go up to here
        Keys.onEscapePressed: Displays.revert()

        RowLayout {
            id: row

            anchors.centerIn: parent
            spacing: Settings.spacing

            Text {
                text: "Keep these display settings? Going back in " + Math.ceil(Displays.remaining / 1000) + " s"
                color: Colors.text
                font.pixelSize: Settings.fontSize
                font.family: Settings.fontFamily
                font.bold: true
                Layout.leftMargin: Settings.spacing
            }

            Button {
                id: revert

                size: "sm"
                icon: ""
                text: "Revert"
                type: "ghost"
                textColor: Colors.text
                Layout.fillWidth: false

                onClicked: Displays.revert()
            }

            Button {
                size: "sm"
                icon: ""
                text: "Keep"
                textColor: Colors.background
                Layout.fillWidth: false

                onClicked: Displays.keep()
            }
        }
    }
}
