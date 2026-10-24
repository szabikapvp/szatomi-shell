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
    property int level: Pipewire.defaultAudioSink?.audio.volume != null 
        ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) : 0

    readonly property string icon: {
        if (isMuted) return "volume-mute"
        if (level < 20) return "volume-0"
        if (level < 50) return "volume-1"
        return "volume-2"
    }

    function getLevel() {
        return level
    }

    // Scrolling asks for changes faster than Pipewire reports them back, so they build on the last request
    property real targetLevel: -1

    Timer {
        id: targetReset
        interval: 500
        onTriggered: targetLevel = -1
    }

    function adjust(delta) {
        const base = targetLevel >= 0 ? targetLevel : level
        targetLevel = Math.max(0, Math.min(100, base + delta))
        targetReset.restart()
        setLevel(targetLevel)
    }

    function toggleMute() {
        if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.muted = !isMuted
    }

    function setLevel(value) {
        if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(100, value)) / 100
    }
}