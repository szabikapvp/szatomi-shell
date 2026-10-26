import QtQuick
import QtQuick.Layouts
import "../../components/widgets"

import qs.config

// Title row of a control center page. Children are added after the title, as actions on the right
RowLayout {
    id: root

    property string title
    // Where the page sits, shown small above the title, like "Settings / Audio"
    property string path
    property bool showBack: true

    signal back()

    Layout.fillWidth: true
    spacing: Settings.spacing

    Button {
        visible: root.showBack
        icon: "arrow-left"
        iconOnly: true
        size: "md"
        type: "ghost"
        textColor: Colors.text
        Layout.fillWidth: false

        onClicked: root.back()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
            visible: root.path != ""
            text: root.path
            color: Qt.alpha(Colors.text, 0.6)
            font.pixelSize: Settings.fontSize - Settings.px(2)
            font.family: Settings.fontFamily
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: root.title
            color: Colors.text
            font.pixelSize: Settings.px(24)
            font.family: Settings.fontFamily
            font.weight: 900
            elide: Text.ElideRight
            Layout.fillWidth: true
            // A fixed height, filling would make the whole header take a share of the page's spare room
            Layout.preferredHeight: root.path != "" ? implicitHeight : Settings.px(48)
            verticalAlignment: Text.AlignVCenter
        }
    }
}
