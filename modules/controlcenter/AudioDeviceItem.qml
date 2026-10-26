import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../components"
import "../../components/widgets"

import qs.config
import qs.services

// One audio device in the Audio settings. Clicking opens its page
Rectangle {
    id: root

    required property PwNode node
    readonly property bool isDefault: Audio.isDefault(node)

    signal clicked()

    // Tab reaches it, Enter or Space opens the device
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
            icon: Audio.nodeIcon(root.node)
            size: Settings.buttonIconSize
            color: root.isDefault ? Colors.primary : Colors.text
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: Audio.nodeName(root.node)
                color: Colors.text
                font.pixelSize: Settings.fontSize
                font.family: Settings.fontFamily
                font.bold: root.isDefault
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: (root.isDefault ? "Default · " : "") + (root.node.audio.muted ? "Muted" : Math.round(root.node.audio.volume * 100) + "%")
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - Settings.px(4)
                font.family: Settings.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Button {
            visible: !root.isDefault
            size: "sm"
            icon: ""
            text: "Set default"
            type: "ghost"
            textColor: Colors.text
            Layout.fillWidth: false

            onClicked: Audio.setDefault(root.node)
        }

        Icon {
            icon: "arrow-right"
            size: Settings.buttonIconSize
            color: Qt.alpha(Colors.text, 0.6)
        }
    }
}
