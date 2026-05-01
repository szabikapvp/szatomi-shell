import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls

import qs.config
import "../../components"

Item {
    id: root
    
    property string type: "primary"
    property string icon: "no-wifi"
    property string text: "Placeholder"
    property string color: Colors.foreground
    property string textColor: Colors.background
    property string size: "lg" 
    property int radius: Settings.radiusMd
    property bool bold: true

    property bool iconOnly: false
    property bool rightSide: false

    Layout.fillWidth: true
    Layout.preferredWidth: iconOnly ? (size == "lg" ? 64 : 46) : 172

    height: size == "lg" ? 64 : 46

    signal clicked()
    signal rightSideClicked()

    MouseArea {
        id: mouseArea

        hoverEnabled: true
        anchors.fill: parent
        
        // height: parent.height
        // width: rightSide ? parent.width / 2 : parent.width

        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Rectangle {
        id: buttonRect
        anchors.fill: parent
        color: {

            switch (root.type) {
                case "primary":

                    if (mouseArea.containsMouse) {
                        if (mouseArea.pressed) return Qt.darker(root.color, 1.8)
                        else return Qt.darker(root.color, 1.3)
                    } else return root.color

                case "ghost":

                    if (mouseArea.containsMouse) {
                        if (mouseArea.pressed) return Qt.alpha(root.color, 0.2)
                        else return Qt.alpha(root.color, 0.1)
                    } else return "transparent"
            }
        }
        radius: root.radius

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }
    
        RowLayout {
        
            anchors.fill: parent
            anchors.margins: Settings.gap * (size == "lg" ? 2 : 1)
            spacing: Settings.gap * (size == "lg" ? 2 : 1)

            Icon {
                icon: root.icon
                size: 24
                color: textColor
            }

            Text {
                visible: !iconOnly
                text: root.text
                color: textColor
                font.pixelSize: Settings.fontSize
                font.family: Settings.fontFamily
                font.bold: root.bold
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }

            Icon {
                visible: root.rightSide
                icon: "arrow-right"
                size: 24
                color: textColor
            }
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
        
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.rightSideClicked()
        }
    }
    
}