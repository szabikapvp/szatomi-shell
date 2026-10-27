import QtQuick
import QtQuick.Layouts
import "../../../components"

import qs.config
import qs.utils

// One row tall. A single cell shows only the icon, wider tiles add a title and a subtitle.
// The icon runs clicked(), the rest of the tile and right clicks open the page
Tile {
    id: root

    property string icon
    property string text
    property string subtext
    property bool active: false
    property bool disabled: false

    signal clicked()

    interactive: true
    onActivated: if (!disabled) clicked()

    readonly property bool compact: columns == 1
    readonly property int inset: (height - Settings.buttonHeight.lg) / 2

    radius: height / 2

    // Hover layer for the area outside the icon
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.alpha(Colors.foreground, bodyArea.pressed ? 0.1 : bodyArea.containsMouse ? 0.05 : 0)

        Behavior on color { enabled: root.settled; ColorAnim {} }
    }

    MouseArea {
        id: bodyArea

        anchors.fill: parent
        visible: !root.compact
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        pressAndHoldInterval: Settings.controlCenterHoldDuration

        onClicked: root.pageRequested()
        onPressAndHold: root.held()
    }

    Rectangle {
        id: badge

        x: root.compact ? 0 : root.inset
        y: root.compact ? 0 : root.inset
        width: root.compact ? root.width : Settings.buttonHeight.lg
        height: root.compact ? root.height : Settings.buttonHeight.lg
        radius: height / 2

        color: root.active ? Colors.primary : (root.compact ? "transparent" : Qt.alpha(Colors.foreground, 0.1))
        opacity: root.disabled ? 0.4 : 1

        Behavior on color { enabled: root.settled; ColorAnim {} }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.alpha(Colors.foreground, iconArea.pressed ? 0.2 : iconArea.containsMouse ? 0.1 : 0)

            Behavior on color { enabled: root.settled; ColorAnim {} }
        }

        Icon {
            anchors.centerIn: parent
            icon: root.icon
            size: Settings.buttonIconSize
            color: Colors.text
        }

        MouseArea {
            id: iconArea

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
            pressAndHoldInterval: Settings.controlCenterHoldDuration

            onClicked: (mouse) => {
                if (mouse.button == Qt.RightButton) root.pageRequested()
                else if (!root.disabled) root.clicked()
            }
            onPressAndHold: root.held()
        }
    }

    ColumnLayout {
        visible: !root.compact

        anchors.left: badge.right
        anchors.right: parent.right
        anchors.leftMargin: Settings.spacing
        anchors.rightMargin: root.inset
        anchors.verticalCenter: parent.verticalCenter

        spacing: 0

        Text {
            text: root.text
            color: Colors.text
            font.pixelSize: Settings.fontSize
            font.family: Settings.fontFamily
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            visible: text != ""
            text: root.subtext
            color: Qt.alpha(Colors.text, 0.6)
            font.pixelSize: Settings.fontSize - Settings.px(2)
            font.family: Settings.fontFamily
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
