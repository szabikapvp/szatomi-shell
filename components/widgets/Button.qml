import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls

import qs.config
import qs.utils
import "../../components"

Item {
    id: root
    
    property string type: "primary"
    property string size: "lg" 
    property string icon: "no-wifi"
    property string text: "Placeholder"
    property string color: Colors.foreground
    property string textColor: Colors.background
    
    property int radius:  999 //(size == "lg" || size == "md") ? Settings.radiusMd : Settings.radiusSm
    property bool bold: true
    property bool iconOnly: false
    property bool rightSide: false

    property int fontSize: Settings.buttonFontSize[size]
    property int spacing: Settings.buttonPadding[size]
    // Sides without an icon get double padding
    property int paddingLeft: icon != "" ? spacing : spacing * 2
    property int paddingRight: rightSide ? spacing : (iconOnly ? spacing : spacing * 2)

    property bool disabled: false

    implicitHeight: Settings.buttonHeight[size]
    implicitWidth: content.implicitWidth + paddingLeft + paddingRight

    Layout.fillWidth: true

    // Sinks the moment it's pressed, before the click lands
    scale: mouseArea.pressed || rightMouseArea.pressed ? Settings.pressScale : 1
    Behavior on scale { Anim { fast: true } }

    signal clicked()
    signal rightSideClicked()

    // Tab reaches it, Enter or Space presses it
    activeFocusOnTab: !disabled
    Keys.onPressed: (event) => {
        if (event.key != Qt.Key_Return && event.key != Qt.Key_Enter && event.key != Qt.Key_Space) return
        root.clicked()
        event.accepted = true
    }

    FocusRing {}

    MouseArea {
        id: mouseArea

        enabled: !disabled

        hoverEnabled: true
        anchors.fill: parent
        
        cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Rectangle {
        id: buttonRect
        
        anchors.fill: parent

        color: {

            switch (root.type) {
                case "primary":

                    if (disabled) return Qt.darker(root.color, 2)

                    if (mouseArea.containsMouse) {
                        if (mouseArea.pressed) return Qt.darker(root.color, Colors.active)
                        else return Qt.darker(root.color, Colors.hover)
                    } else return root.color

                case "ghost":

                    if (disabled) return "transparent"

                    if (mouseArea.containsMouse) {
                        if (mouseArea.pressed) return Qt.alpha(root.color, 0.2)
                        else return Qt.alpha(root.color, 0.1)
                    } else return "transparent"
            }
        }
        radius: root.radius

        Behavior on color {
            ColorAnim {}
        }
    
        RowLayout {
            id: content

            x: root.paddingLeft
            anchors.verticalCenter: parent.verticalCenter
            // width: parent.width - (root.spacing * 2) - (root.rightSide ? Settings.buttonIconSize + root.spacing : 0)

            spacing: Settings.spacing * (size == "lg" ? 2 : 1)

            Icon {
                visible: root.icon != ""
                icon: root.icon
                size: Settings.buttonIconSize
                color: disabled ? Qt.darker(textColor, 1.8) : textColor
            }

            Text {
                visible: !iconOnly
                text: root.text
                color: disabled ? Qt.darker(textColor, 1.8) : textColor
                font.pixelSize: fontSize
                font.family: Settings.fontFamily
                font.bold: root.bold
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }
        }   

        Icon {

            anchors.right: parent.right
            anchors.rightMargin: spacing

            anchors.verticalCenter: parent.verticalCenter

            visible: root.rightSide
            icon: "arrow-right"
            size: Settings.buttonIconSize
            color: textColor
        }
    }

    
    Rectangle {
        
        visible: root.rightSide

        width: parent.width / 2
        height: parent.height
        anchors.right: parent.right
        
        topRightRadius: root.radius
        bottomRightRadius: root.radius

        color: "transparent"

        MouseArea {
            id: rightMouseArea

            enabled: !disabled

            anchors.fill: parent
            cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: root.rightSideClicked()
        }
    }
    
    function disable() {
        disabled = true
    }

    function enable() {
        disabled = false
    }
}