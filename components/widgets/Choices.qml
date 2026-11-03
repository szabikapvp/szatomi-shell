import QtQuick
import QtQuick.Layouts

import qs.config

// One button per option joined into a single pill, the picked one in the accent color.
// Sized to fit the options, or stretched evenly when the layout gives it more room
RowLayout {
    id: root

    // Each as { text, value }
    property var options: []
    property var current

    signal picked(var value)

    Layout.fillWidth: true
    spacing: Settings.buttonGroupGap

    Repeater {
        model: root.options

        Button {
            required property var modelData
            required property int index

            size: "sm"
            icon: ""
            text: modelData.text
            centered: true
            joinedLeft: index > 0
            joinedRight: index < root.options.length - 1
            color: modelData.value === root.current ? Colors.primary : Qt.alpha(Colors.foreground, 0.1)
            textColor: Colors.text

            onClicked: root.picked(modelData.value)
        }
    }
}
