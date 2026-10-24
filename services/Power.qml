pragma Singleton

import QtQuick
import Quickshell

import qs.config

// Power menu state, shared so the bar and the control center can both open it
Singleton {
    property bool menuOpen: false
    property string pending: ""

    function toggleMenu() {
        menuOpen = !menuOpen
    }

    // Waits for the menu to finish closing, since a lock screen stops its frames mid animation
    // and the half closed menu would flash back after unlocking
    function run(action) {
        menuOpen = false
        pending = action
        delay.restart()
    }

    Timer {
        id: delay
        // Double, so the hidden window's last frame is on screen before the command runs
        interval: Settings.popDuration * 2
        onTriggered: Quickshell.execDetached(Settings.powerCommands[pending])
    }
}
