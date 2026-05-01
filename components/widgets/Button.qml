import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls

import qs.config
import "../../components"

Item {
    id: root

    property string icon: "no-wifi"
    property string text: "Placeholder"

    Layout.fillWidth: true
    Layout.minimumWidth: 128

    width: 172
    height: 64

    MouseArea {
        id: mouseArea

        hoverEnabled: true
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
    }

    Rectangle {
        id: buttonRect
        anchors.fill: parent
        color: {
            if (mouseArea.containsMouse) {
                if (mouseArea.pressed) return Qt.darker(Colors.foreground, 1.8)
                else return Qt.darker(Colors.foreground, 1.3)
            } else return Colors.foreground
        }
        radius: Settings.radiusMd

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }
    
        RowLayout {
        
            anchors.fill: parent
            anchors.margins: Settings.gap * 2
            spacing: Settings.gap * 2

            Icon {
                icon: root.icon
                size: 24
                color: Colors.background
            }

            Text {
                text: root.text
                font.pixelSize: Settings.fontSize
                font.family: Settings.fontFamily
                font.bold: true
                Layout.fillWidth: true
            }
        }   
    }
}