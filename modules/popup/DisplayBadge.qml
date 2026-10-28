import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

import qs.config
import qs.services
import qs.utils

// Names the display it's on while the display settings are open, so each tile can be matched to a screen.
// The one selected there stands out
PanelWindow {
    id: root

    property var modelData
    screen: modelData

    readonly property var config: Displays.current.find(config => config.name == modelData?.name) ?? null
    readonly property bool shown: Displays.identifying && config !== null

    anchors {
        top: true
        left: true
    }
    margins {
        top: Settings.windowSpacing * 2
        left: Settings.windowSpacing * 2
    }

    // Clicks go through to whatever is below
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    visible: shown || badge.opacity > 0
    implicitWidth: badge.width
    implicitHeight: badge.height

    Rectangle {
        id: badge

        width: column.implicitWidth + Settings.spacing * 4
        height: column.implicitHeight + Settings.spacing * 2
        radius: Settings.radiusMd
        color: Displays.highlighted == root.modelData?.name ? Colors.primary : Colors.background
        border.width: 1
        border.color: Colors.backgroundSubtle

        opacity: root.shown ? 1 : 0
        Behavior on opacity { Fade {} }
        Behavior on color { ColorAnim {} }

        ColumnLayout {
            id: column

            anchors.centerIn: parent
            spacing: 0

            Text {
                text: root.config?.label ?? ""
                color: Colors.text
                font.pixelSize: Settings.fontSize * 1.5
                font.family: Settings.fontFamily
                font.bold: true
            }

            Text {
                // Mirrors show this picture too, so they're named here
                text: [root.config?.name ?? ""]
                    .concat(Displays.mainScreen?.name == root.modelData?.name ? ["Main"] : [])
                    .concat(Displays.current.filter(other => root.config && other.mirror == root.config.key).map(other => "also on " + other.label))
                    .join(" · ")
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - Settings.px(2)
                font.family: Settings.fontFamily
            }
        }
    }
}
