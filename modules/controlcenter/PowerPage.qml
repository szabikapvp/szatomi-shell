import QtQuick
import QtQuick.Layouts
import "../../components/widgets"
import "widgets"

import qs.config
import qs.services

// A single row of round power actions, styled like the grid's one cell buttons
RowLayout {
    id: root

    signal back()
    signal closeRequested()

    readonly property int preferredWidth: implicitWidth
    // Concentric with the round buttons, so the panel rounds fully too
    readonly property int cornerRadius: Settings.controlCenterCellSize / 2

    // Actions that end the session need a second click
    property string armed: ""

    spacing: Settings.spacing

    Timer {
        id: disarm
        interval: Settings.powerConfirmTimeout
        onTriggered: root.armed = ""
    }

    Repeater {
        model: [
            { action: "lock", icon: "lock", text: "Lock", confirm: false },
            { action: "sleep", icon: "sleep", text: "Sleep", confirm: false },
            { action: "logout", icon: "logout", text: "Log out", confirm: true },
            { action: "restart", icon: "reload", text: "Restart", confirm: true },
            { action: "shutdown", icon: "power", text: "Shut down", confirm: true }
        ]

        ButtonTile {
            id: button

            required property var modelData
            readonly property bool isArmed: root.armed == modelData.action
            property bool tooltipReady: false

            icon: modelData.icon
            active: isArmed
            Layout.preferredWidth: Settings.controlCenterCellSize
            Layout.preferredHeight: Settings.controlCenterCellSize

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

    function run(item) {
        if (item.confirm && armed != item.action) {
            armed = item.action
            disarm.restart()
            return
        }

        root.closeRequested()
        Power.run(item.action)
    }
}
