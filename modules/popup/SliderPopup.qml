import Quickshell
import QtQuick
import Quickshell.Wayland
import QtQuick.Layouts
import "../../components/widgets"
import "../../components"

import qs.config

PanelWindow {
    id: root

    property int popupHeight: 50
    property int popupWidth: 300
    property int bottom: 36

    property int prop: 0
    property Component icon: VolumeIcon {}

    anchors.bottom: true
    margins.bottom: 0
    
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    implicitWidth: popupWidth
    implicitHeight: popupHeight + bottom
    visible: true
    color: "transparent"

    onPropChanged: {
        ping()
    }

    NumberAnimation {
        id: slideIn
        target: osdRect
        property: "y"
        to: 0
        duration: 400
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: slideOut
        target: osdRect
        property: "y"
        to: root.height
        duration: 250
        easing.type: Easing.InCubic 
    }

    Rectangle {
        id: osdRect

        width: parent.width
        height: popupHeight
        y: root.height
        color: Colors.background
        radius: 16

        RowLayout {

            spacing: Settings.gap * 2
            anchors.fill: parent

            Item {}

            Loader {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                
                sourceComponent: icon
            }

            Slider {
                prop: root.prop
            }
        
            Text {
                text: root.prop
                color: Colors.text
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 36
                Layout.maximumWidth: 36
            }

            Item {}
        }
    }

    Timer {
        id: osdTimer
        interval: 1500
        repeat: false
        onTriggered: {
            slideOut.restart()
        }
    }

    function ping() {
        slideIn.restart()
        osdTimer.restart()
    }
}