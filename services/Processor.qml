pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    property int usage: 0
    property int temp: 0

    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    Process {
        id: usageProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var user = parseInt(parts[1]) || 0
                var nice = parseInt(parts[2]) || 0
                var system = parseInt(parts[3]) || 0
                var idle = parseInt(parts[4]) || 0
                var iowait = parseInt(parts[5]) || 0
                var irq = parseInt(parts[6]) || 0
                var softirq = parseInt(parts[7]) || 0

                var total = user + nice + system + idle + iowait + irq + softirq
                var idleTime = idle + iowait

                if (lastCpuTotal > 0) {
                    var totalDiff = total - lastCpuTotal
                    var idleDiff = idleTime - lastCpuIdle
                    if (totalDiff > 0) {
                        usage = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
                    }
                }
                lastCpuTotal = total
                lastCpuIdle = idleTime
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: tempProc
        command: ["sh", "-c", `sensors -j | jq -r '.. | .["Package id 0"]? | select(. != null) | .temp1_input'`]
        stdout: SplitParser {
            onRead: data => {
                temp = parseInt(data)
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            usageProc.running = true
            tempProc.running = true
        }
    }

    function getUsage() {
        return usage
    }
    
    function getTemp() {
        return temp
    }
}