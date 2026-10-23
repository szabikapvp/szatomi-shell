import QtQuick
import Quickshell
import QtQuick.Layouts
import "../../components/widgets"

import qs.config

ColumnLayout {
    id: root

    signal back()
    signal closeRequested()

    // Actions that end the session need a second click
    property string armed: ""

    spacing: Settings.spacing * 2

    Timer {
        id: disarm
        interval: Settings.powerConfirmTimeout
        onTriggered: root.armed = ""
    }

    PageHeader {
        title: "Power"
        onBack: root.back()
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.backgroundSubtle
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
            required property var modelData
            readonly property bool isArmed: root.armed == modelData.action

            icon: modelData.icon
            text: isArmed ? "Click again to " + modelData.text.toLowerCase() : modelData.text
            color: isArmed ? Colors.primary : Colors.foreground
            textColor: isArmed ? Colors.text : Colors.background

            onClicked: root.run(modelData)
        }
    }

    function run(item) {
        if (item.confirm && armed != item.action) {
            armed = item.action
            disarm.restart()
            return
        }

        Quickshell.execDetached(Settings.powerCommands[item.action])
        root.closeRequested()
    }
}
