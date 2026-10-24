pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../components/"

Singleton {

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    property bool isMuted: Pipewire.defaultAudioSink?.audio.muted ?? false
    readonly property int reportedLevel: Pipewire.defaultAudioSink?.audio.volume != null
        ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) : 0

    // Touchpads and drags ask for changes far faster than Pipewire applies them, and sending every one
    // queues them up so the volume trails behind. So the latest request is shown right away
    // and sent at most once per writeInterval
    property real targetLevel: -1
    property bool writePending: false
    readonly property int writeInterval: 50

    readonly property int level: targetLevel >= 0 ? Math.round(targetLevel) : reportedLevel

    readonly property string icon: {
        if (isMuted) return "volume-mute"
        if (level < 20) return "volume-0"
        if (level < 50) return "volume-1"
        return "volume-2"
    }

    function getLevel() {
        return level
    }

    function adjust(delta) {
        setLevel((targetLevel >= 0 ? targetLevel : reportedLevel) + delta)
    }

    function setLevel(value) {
        targetLevel = Math.max(0, Math.min(100, value))
        targetReset.restart()

        if (writeThrottle.running) {
            writePending = true
        } else {
            write()
            writeThrottle.start()
        }
    }

    function write() {
        if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = targetLevel / 100
    }

    function toggleMute() {
        if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.muted = !isMuted
    }

    Timer {
        id: writeThrottle
        interval: writeInterval
        onTriggered: {
            if (!writePending) return
            writePending = false
            write()
            restart()
        }
    }

    // Once requests stop and the last one has gone out, the shown level follows Pipewire again
    Timer {
        id: targetReset
        interval: 500
        onTriggered: targetLevel = -1
    }
}
