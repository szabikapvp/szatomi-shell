pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// GPU load. AMD reports it directly, Intel only reports the time the GPU spent idle (RC6),
// so its load comes from how much of each interval wasn't idle
Singleton {
    id: root

    property bool supported: false
    property int usage: 0
    property int frequency: 0 // MHz, 0 when unknown

    // Recent usage, oldest first, one per update
    property var history: []
    readonly property int historyLength: 60

    property real lastIdle: -1
    property real lastTime: 0

    // shortcut: AMD and Intel i915 only; NVIDIA (nvidia-smi) and Intel xe (gtidle/idle_residency_ms) read as unsupported
    Process {
        id: proc
        command: ["sh", "-c", `
            for f in /sys/class/drm/card*/device/gpu_busy_percent; do
                [ -r "$f" ] && echo "busy $(cat "$f")" && exit
            done
            for d in /sys/class/drm/card*/gt/gt0; do
                [ -r "$d/rc6_residency_ms" ] && echo "idle $(cat "$d/rc6_residency_ms") $(cat "$d/rps_act_freq_mhz")" && exit
            done
        `]
        stdout: SplitParser {
            onRead: data => root.parse(data)
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: proc.running = true
    }

    function parse(line) {
        const parts = line.trim().split(" ")

        if (parts[0] == "busy") {
            record(parseInt(parts[1]))
        } else if (parts[0] == "idle") {
            const idle = parseFloat(parts[1])
            const now = Date.now()
            frequency = parseInt(parts[2]) || 0

            if (lastIdle >= 0 && now > lastTime) record(100 * (1 - (idle - lastIdle) / (now - lastTime)))
            lastIdle = idle
            lastTime = now
        }
    }

    function record(value) {
        if (isNaN(value)) return
        supported = true
        usage = Math.round(Math.max(0, Math.min(100, value)))
        history = history.concat([usage]).slice(-historyLength)
    }
}
