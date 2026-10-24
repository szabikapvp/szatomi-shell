import QtQuick
import QtQuick.Layouts
import "../../components/widgets"

import qs.config

ColumnLayout {
    id: root

    required property var grid

    signal back()

    readonly property var available: grid.catalog.entries.filter(entry => !grid.widgets.some(w => w.type === entry.type))

    spacing: Settings.spacing * 2

    PageHeader {
        title: "Add widget"
        onBack: root.back()
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.backgroundSubtle
    }

    // shortcut: no scrolling, fine while the catalog fits on screen; wrap in a ScrollView when it grows
    Repeater {
        model: root.available

        Button {
            required property var modelData
            readonly property bool hasRoom: root.grid.spotFor(modelData.type) !== null

            icon: modelData.icon
            text: hasRoom ? modelData.name : modelData.name + " (no room)"
            disabled: !hasRoom

            onClicked: {
                root.grid.add(modelData.type)
                root.back()
            }
        }
    }

    Text {
        visible: root.available.length === 0

        text: "Every widget is already placed"
        color: Colors.text
        font.pixelSize: Settings.fontSize
        font.family: Settings.fontFamily
        font.weight: 300
        Layout.fillWidth: true
        Layout.preferredHeight: Settings.px(64)
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
}
