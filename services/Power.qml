pragma Singleton

import QtQuick
import Quickshell

import qs.config

// Runs power actions once the control center has closed. A lock screen stops its frames mid animation,
// so the half closed panel would flash back after unlocking
Singleton {
    property string pending: ""

    function run(action) {
        pending = action
        delay.restart()
    }

    Timer {
        id: delay
        // Double, so the hidden window's last frame is on screen before the command runs
        interval: Settings.motionDuration * 2
        onTriggered: Quickshell.execDetached(Settings.powerCommands[pending])
    }
}
