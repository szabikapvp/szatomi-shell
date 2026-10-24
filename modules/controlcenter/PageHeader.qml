import QtQuick
import QtQuick.Layouts
import "../../components/widgets"

import qs.config

// Title row of a control center page. Children are added after the title, as actions on the right
RowLayout {
    id: root

    property string title
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

    Text {
        text: root.title
        color: Colors.text
        font.pixelSize: Settings.px(24)
        font.family: Settings.fontFamily
        font.weight: 900
        Layout.fillWidth: true
        Layout.preferredHeight: Settings.px(48)
        verticalAlignment: Text.AlignVCenter
    }
}
