import QtQuick
import Quickshell

import qs.config

// Small label that pops up beside an item, offset clear of whatever the item sits in
PopupWindow {
    id: root

    required property Item target
    property string text
    property bool shown: false
    // Opens upwards, for things near the bottom of the screen
    property bool above: true
    // Extra distance from the target's edge
    property int offset: Settings.windowSpacing

    anchor.item: target
    anchor.rect.x: 0
    anchor.rect.y: -offset
    anchor.rect.width: target.width
    anchor.rect.height: target.height + offset * 2
    anchor.edges: above ? Edges.Top : Edges.Bottom
    anchor.gravity: above ? Edges.Top : Edges.Bottom

    visible: shown && text != ""
    color: "transparent"

    implicitWidth: label.implicitWidth + Settings.spacing * 2
    implicitHeight: label.implicitHeight + Settings.spacing

    Rectangle {
        anchors.fill: parent
        radius: Settings.radiusSm
        color: Colors.background
        border.width: 1
        border.color: Colors.backgroundSubtle

        Text {
            id: label

            anchors.centerIn: parent
            text: root.text
            color: Colors.text
            font.pixelSize: Settings.fontSize - Settings.px(2)
            font.family: Settings.fontFamily
            font.bold: true
        }
    }
}
