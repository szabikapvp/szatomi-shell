import QtQuick
import QtQuick.Layouts

import qs.config

// One button per option, the picked one in the accent color. Wraps onto more lines when they don't fit
Flow {
    id: root

    // Each as { text, value }
    property var options: []
    property var current

    signal picked(var value)

    Layout.fillWidth: true
    spacing: Settings.spacing / 2

    Repeater {
        model: root.options

        Button {
            required property var modelData

            size: "sm"
            icon: ""
            text: modelData.text
            color: modelData.value === root.current ? Colors.primary : Qt.alpha(Colors.foreground, 0.1)
            textColor: Colors.text

            onClicked: root.picked(modelData.value)
        }
    }
}
