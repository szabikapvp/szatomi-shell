import Quickshell
import QtQuick
import Quickshell.Wayland
import QtQuick.Layouts
import "../../components/widgets"
import "../../components"

import qs.config
import qs.utils

PanelWindow {
    id: root

    property int popupHeight: Settings.px(50)
    property int popupWidth: Settings.px(300)
    property int bottom: Settings.osdYPosition

    property int prop: 0
    // Set while something else already shows the value
    property bool suppressed: false
    property Component icon: VolumeIcon {}
    property bool shown: false

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
        if (!suppressed) ping()
    }

    // Rises out of the screen edge and sinks back the same way, picking up from wherever it is when pinged again.
    // Reduce motion keeps it in place and only fades it
    Spring {
        id: slide
        to: root.shown || Settings.reduceMotion ? 1 : 0
        epsilon: 0.001
    }

    Rectangle {
        id: osdRect

        width: parent.width
        height: popupHeight
        y: (1 - slide.value) * root.height
        opacity: root.shown ? 1 : 0
        color: Colors.background
        radius: Settings.radiusMd

        Behavior on opacity { Fade {} }

        RowLayout {

            spacing: Settings.spacing * 2
            anchors.fill: parent

            Item {}

            Loader {
                Layout.preferredWidth: Settings.px(18)
                Layout.preferredHeight: Settings.px(18)
                
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
                Layout.preferredWidth: Settings.px(36)
                Layout.maximumWidth: Settings.px(36)
            }

            Item {}
        }
    }

    Timer {
        id: osdTimer
        interval: 1500
        repeat: false
        onTriggered: root.shown = false
    }

    function ping() {
        shown = true
        osdTimer.restart()
    }
}