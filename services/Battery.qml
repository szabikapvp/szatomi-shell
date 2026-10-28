pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

import qs.config

// Every battery combined into one, as UPower reports it. UPower hands out the device before it has read it,
// with everything at 0, so nothing should be shown until it's available
Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: device.ready && device.isPresent

    // UPower's percentage runs from 0 to 1
    readonly property int level: Math.round(device.percentage * 100)
    readonly property bool pluggedIn: !UPower.onBattery
    readonly property bool charging: device.state == UPowerDeviceState.Charging
    readonly property bool full: device.state == UPowerDeviceState.FullyCharged
    readonly property bool low: !pluggedIn && level <= Settings.batteryLowLevel

    // Seconds until full while charging, until empty otherwise. 0 while UPower is still estimating
    readonly property real timeLeft: charging ? device.timeToFull : device.timeToEmpty

    // Eight steps from empty to full, each covering an even share of the charge
    readonly property string icon: "battery-" + Math.max(0, Math.min(7, Math.round(level / 100 * 7)))

    readonly property string status: {
        if (full) return "Fully charged"
        if (charging) return timeLeft > 0 ? "Full in " + duration(timeLeft) : "Charging"
        if (pluggedIn) return "Plugged in"
        return timeLeft > 0 ? duration(timeLeft) + " left" : ""
    }

    function duration(seconds) {
        const minutes = Math.max(1, Math.round(seconds / 60))
        const hours = Math.floor(minutes / 60)
        if (hours == 0) return minutes + " min"
        return minutes % 60 == 0 ? hours + " h" : hours + " h " + minutes % 60 + " min"
    }
}
