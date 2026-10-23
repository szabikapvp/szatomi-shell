import QtQuick

import qs.services

SliderTile {
    icon: Audio.icon
    value: Audio.level

    onMoved: (value) => Audio.setLevel(value)
}
