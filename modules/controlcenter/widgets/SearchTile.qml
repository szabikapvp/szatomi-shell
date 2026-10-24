import QtQuick
import QtQuick.Layouts
import "../../../components"

import qs.config

// Looks like a search field, clicking it opens the launcher. Typing anywhere in the
// control center opens it too, so the field itself never takes the keys
Tile {
    id: root

    readonly property bool compact: columns == 1
    // Same gap beside the icon as above and below it
    readonly property real inset: (height - Settings.buttonIconSize) / 2

    radius: height / 2

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.alpha(Colors.foreground, area.pressed ? 0.1 : area.containsMouse ? 0.05 : 0)

        Behavior on color { enabled: root.settled; ColorAnimation { duration: 100; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        pressAndHoldInterval: Settings.controlCenterHoldDuration

        onClicked: root.pageRequested()
        onPressAndHold: root.held()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.compact ? 0 : root.inset
        anchors.rightMargin: root.compact ? 0 : root.inset
        spacing: Settings.spacing * 2

        Icon {
            icon: "search"
            size: Settings.buttonIconSize
            color: Colors.text
            Layout.alignment: root.compact ? Qt.AlignCenter : Qt.AlignVCenter
        }

        Text {
            visible: !root.compact
            text: "Search apps"
            color: Qt.darker(Colors.text, 2)
            font.pixelSize: Settings.fontSize
            font.family: Settings.fontFamily
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
