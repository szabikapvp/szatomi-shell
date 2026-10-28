import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../components/widgets"

import qs.config
import qs.services

// One display in the Displays settings, with what it's set to. Clicking opens its page
Rectangle {
    id: root

    // From Displays.current
    required property var config

    signal clicked()

    // Tab reaches it, Enter or Space opens the display
    activeFocusOnTab: true
    Keys.onPressed: (event) => {
        if (event.key != Qt.Key_Return && event.key != Qt.Key_Enter && event.key != Qt.Key_Space) return
        root.clicked()
        event.accepted = true
    }

    FocusRing {}

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Settings.spacing

    radius: Settings.radiusSm
    color: mouseArea.containsMouse ? Qt.alpha(Colors.foreground, mouseArea.pressed ? 0.2 : 0.1) : "transparent"

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Settings.spacing
        anchors.verticalCenter: parent.verticalCenter

        spacing: Settings.spacing

        Icon {
            icon: root.config.builtin ? "computer" : "bt-display"
            size: Settings.buttonIconSize
            color: root.config.disabled ? Qt.alpha(Colors.text, 0.6) : Colors.text
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.config.label
                color: Colors.text
                font.pixelSize: Settings.fontSize
                font.family: Settings.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.config.name + (Displays.mainScreen?.name == root.config.name ? " · Main" : "") + " · " + (root.config.disabled ? "Off"
                    : root.config.mirror != "" ? "Mirroring"
                    : root.config.width + " × " + root.config.height + " · " + Math.round(root.config.refresh) + " Hz · " + Math.round(root.config.scale * 100) + "%")
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - Settings.px(4)
                font.family: Settings.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Icon {
            icon: "arrow-right"
            size: Settings.buttonIconSize
            color: Qt.alpha(Colors.text, 0.6)
        }
    }
}
