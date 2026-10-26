import QtQuick
import Quickshell
import QtQuick.Layouts
import "../../components"

import qs.config

// One app or command in the launcher list. Hovering selects it, like moving there with the keys
Rectangle {
    id: root

    property string text
    // An app's icon from the theme, or one of the shell's own for commands
    property string image
    property string icon
    // Dim text on the right, a command's keyword
    property string detail
    property color detailColor: Qt.alpha(Colors.text, 0.6)
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
            visible: root.image != ""
            source: root.image
            sourceSize.width: Settings.launcherIconSize
            sourceSize.height: Settings.launcherIconSize
            Layout.preferredWidth: Settings.launcherIconSize
            Layout.preferredHeight: Settings.launcherIconSize
            fillMode: Image.PreserveAspectFit
        }

        Icon {
            visible: root.icon != ""
            icon: root.icon
            size: Settings.buttonIconSize
            // Centered in the space an app icon takes, so names line up
            Layout.preferredWidth: Settings.launcherIconSize
        }

        Text {
            text: root.text
            color: Colors.text
            font.pixelSize: Settings.launcherFontSize
            font.family: Settings.fontFamily
            font.bold: root.selected
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            visible: text != ""
            text: root.detail
            color: root.detailColor
            font.pixelSize: Settings.launcherFontSize - Settings.px(4)
            font.family: Settings.fontFamily
        }
    }
}
