import QtQuick

import qs.services

SliderTile {
    icon: Brightness.icon
    value: Brightness.level

    onMoved: (value) => Brightness.setLevel(value)
}
