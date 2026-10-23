import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls

import qs.config
import "../../components"

// FocusScope so forceActiveFocus() on the component reaches the inner field
FocusScope {
    id: root

    property string type: "text"
    property string size: "lg"
    property string icon: ""
    property string rightIcon: ""
    property string textColor: Colors.text
    property color backgroundColor: Qt.lighter(Colors.background, 1.8)

    property alias text: field.text
    property alias placeholderText: field.placeholderText

    property int radius: Settings.radiusSm
    property int fontSize: Settings.buttonFontSize[size]
    property int spacing: Settings.buttonPadding[size]
    // Sides without an icon get double padding
    property int paddingLeft: icon != "" ? spacing : spacing * 2
    property int paddingRight: rightIcon != "" ? spacing : spacing * 2

    property bool disabled: false

    // Same height as Button so they line up in a row
    implicitHeight: Settings.buttonHeight[size]
    implicitWidth: 200

    Layout.fillWidth: true

    signal accepted()
    signal rightIconClicked()

    Rectangle {
        anchors.fill: parent

        color: disabled ? Qt.darker(root.backgroundColor, 1.4) : root.backgroundColor
        radius: root.radius

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.paddingLeft
            anchors.rightMargin: root.paddingRight

            spacing: Settings.spacing * (size == "lg" ? 2 : 1)

            Icon {
                visible: root.icon != ""
                icon: root.icon
                size: Settings.buttonIconSize
                color: disabled ? Qt.darker(textColor, 1.8) : textColor
            }

            TextField {
                id: field

                focus: true
                enabled: !disabled

                Layout.fillWidth: true
                Layout.fillHeight: true

                echoMode: root.type == "password" ? TextInput.Password : TextInput.Normal
                padding: 0
                verticalAlignment: TextInput.AlignVCenter

                color: disabled ? Qt.darker(textColor, 1.8) : textColor
                placeholderTextColor: hovered ? Qt.darker(textColor, 3) : Qt.darker(textColor, 2)
                font.pixelSize: fontSize
                font.family: Settings.fontFamily

                background: null

                onAccepted: root.accepted()
            }

            Icon {
                visible: root.rightIcon != ""
                icon: root.rightIcon
                size: Settings.buttonIconSize
                color: disabled ? Qt.darker(textColor, 1.8) : textColor

                MouseArea {
                    anchors.fill: parent
                    enabled: !disabled
                    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: root.rightIconClicked()
                }
            }
        }
    }

    function disable() {
        disabled = true
    }

    function enable() {
        disabled = false
    }
}
