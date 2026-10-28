import QtQuick
import QtQuick.Layouts

import qs.config

// A titled card like a settings row, children stack below the title
Rectangle {
    id: section

    property string title
    property string description
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + Settings.spacing * 3

    radius: Settings.radiusMd
    color: Colors.backgroundSubtle

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Settings.spacing * 1.5
        anchors.verticalCenter: parent.verticalCenter

        spacing: Settings.spacing

        ColumnLayout {
            visible: section.title != "" || section.description != ""
            Layout.fillWidth: true
            spacing: Settings.px(2)

            Text {
                visible: text != ""
                text: section.title
                color: Colors.text
                font.pixelSize: Settings.fontSize
                font.family: Settings.fontFamily
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                visible: text != ""
                text: section.description
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - Settings.px(2)
                font.family: Settings.fontFamily
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            id: body

            Layout.fillWidth: true
            spacing: Settings.spacing / 2
        }
    }
}
