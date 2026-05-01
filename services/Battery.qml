pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../components/"

Singleton {

    property int level: 0
    property bool charging: false

    Process {
        id: batteryProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                level = parseInt(data)
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: chargingProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/status"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                charging = data == "Charging"
            }
        }
        Component.onCompleted: running = true
    }


    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            batteryProc.running = true
            chargingProc.running = true
        }
    }

    function getLevel() {
        return level
    }

    function isCharging() {
        return charging
    }
}