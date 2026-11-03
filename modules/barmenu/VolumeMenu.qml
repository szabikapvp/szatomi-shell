import QtQuick
import "../../components/widgets"

import qs.config
import qs.services

// Volume of the default output, its icon mutes it
Item {
    // Fits the mute button's pill
    readonly property real innerRadius: Settings.buttonHeight.sm / 2

    width: Settings.barMenuWidth
    height: slider.implicitHeight

    VolumeSlider {
        id: slider

        anchors.fill: parent
        // The percentage has no button padding of its own like the icon does
        anchors.rightMargin: Settings.barMenuPadding

        volume: Audio.level / 100
        muted: Audio.isMuted
        icon: Audio.icon

        onMoved: (volume) => Audio.setLevel(volume * 100)
        onMuteClicked: Audio.toggleMute()
    }
}
