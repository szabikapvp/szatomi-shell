import QtQuick
import Quickshell
import QtQuick.Layouts

import qs.config

// One app in the launcher list. Hovering selects it, like moving there with the keys
Rectangle {
    id: root

    property DesktopEntry entry
    property bool selected: false

    signal hovered()
    signal clicked()

    implicitHeight: Settings.launcherItemHeight
    radius: Settings.radiusMd
    color: Qt.alpha(Colors.foreground, mouseArea.pressed ? 0.2 : selected ? 0.1 : 0)

    Behavior on color {
        ColorAnimation { duration: 100; easing.type: Easing.OutCubic }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovered()
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Settings.spacing
        anchors.rightMargin: Settings.spacing
        spacing: Settings.spacing

        Image {
            source: Quickshell.iconPath(root.entry.icon, "application-x-executable")
            sourceSize.width: Settings.launcherIconSize
            sourceSize.height: Settings.launcherIconSize
            Layout.preferredWidth: Settings.launcherIconSize
            Layout.preferredHeight: Settings.launcherIconSize
            fillMode: Image.PreserveAspectFit
        }

        Text {
            text: root.entry.name
            color: Colors.text
            font.pixelSize: Settings.launcherFontSize
            font.family: Settings.fontFamily
            font.bold: root.selected
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
