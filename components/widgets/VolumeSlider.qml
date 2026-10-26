import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services

// Volume from 0 to 1 with a mute button. Drags apply as they go, but moved() fires at most once per
// Audio.writeInterval, since Pipewire falls behind when sent every pointer move
RowLayout {
    id: root

    property real volume: 0
    property bool muted: false
    property bool showMute: true
    property string icon: "volume-2"

    signal moved(real volume)
    signal muteClicked()

    property real pending: -1

    Layout.fillWidth: true
    spacing: Settings.spacing

    Button {
        visible: root.showMute
        icon: root.muted ? "volume-mute" : root.icon
        iconOnly: true
        size: "sm"
        type: "ghost"
        textColor: root.muted ? Colors.primary : Colors.text
        Layout.fillWidth: false

        onClicked: root.muteClicked()
    }

    ValueSlider {
        id: slider

        live: true
        value: root.volume * 100
        opacity: root.muted ? 0.5 : 1

        onMoved: (value) => root.set(value / 100)
    }

    Text {
        text: Math.round(slider.shownValue) + "%"
        color: Colors.text
        font.pixelSize: Settings.fontSize - Settings.px(2)
        font.family: Settings.fontFamily
        font.bold: true
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: percentMetrics.advanceWidth("100%")
    }

    FontMetrics {
        id: percentMetrics
        font.family: Settings.fontFamily
        font.pixelSize: Settings.fontSize - Settings.px(2)
        font.bold: true
    }

    Timer {
        id: throttle
        interval: Audio.writeInterval
        onTriggered: if (root.pending >= 0) root.send()
    }

    function set(volume) {
        pending = volume
        if (!throttle.running) send()
    }

    function send() {
        moved(pending)
        pending = -1
        throttle.restart()
    }
}
