import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../components/widgets"

import qs.config
import qs.services
import qs.utils

// Small row of power actions in the middle of the screen. Clicking anywhere else closes it
PanelWindow {
    id: root

    // Actions that end the session need a second click
    property string armed: ""

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Stays up until the pop out and fade finish
    visible: panel.progress > 0
    onVisibleChanged: armed = ""

    Connections {
        target: Power
        function onMenuOpenChanged() {
            if (Power.menuOpen) panel.popIn()
            else panel.popOut()
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Power.menuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    Timer {
        id: disarm
        interval: Settings.powerConfirmTimeout
        onTriggered: root.armed = ""
    }

    // Fades with the pop, so both finish together
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colors.background, Settings.powerMenuDim * panel.progress)

        MouseArea {
            anchors.fill: parent
            onClicked: Power.menuOpen = false
        }
    }

    PopMask {
        id: panel

        anchors.centerIn: parent
        width: row.implicitWidth + Settings.spacing * 2
        height: row.implicitHeight + Settings.spacing * 2

        fromCenter: true
        fromBottom: Settings.barPosition == "bottom"
        radius: Settings.radiusLg

        Rectangle {
            anchors.fill: parent

            radius: Settings.radiusLg
            color: Colors.background
            border.width: 1
            border.color: Colors.backgroundSubtle

            // Keeps clicks between the buttons from closing the menu
            MouseArea { anchors.fill: parent }

            RowLayout {
                id: row

                anchors.centerIn: parent
                spacing: Settings.spacing / 2

                Shortcut {
                    sequences: Settings.backShortcuts
                    onActivated: Power.menuOpen = false
                }

                Repeater {
                    model: [
                        { action: "lock", icon: "lock", text: "Lock", confirm: false },
                        { action: "sleep", icon: "sleep", text: "Sleep", confirm: false },
                        { action: "logout", icon: "logout", text: "Log out", confirm: true },
                        { action: "restart", icon: "reload", text: "Restart", confirm: true },
                        { action: "shutdown", icon: "power", text: "Shut down", confirm: true }
                    ]

                    Button {
                        id: button

                        required property var modelData
                        readonly property bool isArmed: root.armed == modelData.action
                        property bool tooltipReady: false

                        icon: modelData.icon
                        iconOnly: true
                        size: "lg"
                        type: isArmed ? "primary" : "ghost"
                        color: isArmed ? Colors.primary : Colors.foreground
                        textColor: Colors.text
                        Layout.fillWidth: false

                        onClicked: root.run(modelData)

                    HoverHandler {
                        id: hover
                        onHoveredChanged: {
                            button.tooltipReady = false
                            if (hovered) hoverDelay.restart()
                            else hoverDelay.stop()
                        }
                    }

                    Timer {
                        id: hoverDelay
                        interval: Settings.tooltipDelay
                        onTriggered: button.tooltipReady = true
                    }

                    Tooltip {
                        target: button
                        text: button.isArmed ? "Click again to " + button.modelData.text.toLowerCase() : button.modelData.text
                        // Arming shows the warning right away
                        shown: hover.hovered && (button.tooltipReady || button.isArmed)
                    }
                }
            }
        }
    }
    }

    function run(item) {
        if (item.confirm && armed != item.action) {
            armed = item.action
            disarm.restart()
            return
        }

        Power.run(item.action)
    }
}
