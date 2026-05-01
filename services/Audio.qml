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

    function getLevel() {
        return level
    }
}