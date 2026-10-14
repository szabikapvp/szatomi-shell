import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../components/widgets"
import "../controlcenter"

import qs.config

PanelWindow {
    id: bar

    property var modelData
    screen: modelData

    anchors {
        top: Settings.barPosition == "top"
        bottom: Settings.barPosition == "bottom"
        left: true
        right: true
    }

    margins {
        left: Settings.barFloating ? Settings.windowSpacing : 0
        right: Settings.barFloating ? Settings.windowSpacing : 0
        bottom: Settings.barPosition == "bottom" ?
            (Settings.barFloating ? Settings.windowSpacing : 0)
            : 0
        top: Settings.barPosition == "top" ?
            (Settings.barFloating ? Settings.windowSpacing : 0)
            : 0
    }

    implicitHeight: Settings.barHeight
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Colors.background
        radius: Settings.barFloating ? Settings.radiusSm : 0

        Item {

            anchors.fill: parent
            anchors.margins: Settings.spacing
            anchors.leftMargin: Settings.spacing * 2
            anchors.rightMargin: Settings.spacing * 2

            // LEFT
            RowLayout {

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: Settings.spacing
                
                CpuTemp {}
                //CpuUsage {}
                //MemoryUsage {}
            }

            // CENTER
            RowLayout {
                anchors.centerIn: parent
                
                Repeater {
                    model: Settings.workspaceCount // Number of workspaces

                    Rectangle {

                        property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                        property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

                        Layout.preferredWidth: isActive ? 30 :10
                        Layout.preferredHeight: 10
                        radius: 5
                        color: isActive ? Colors.text : (ws ? Qt.alpha(Colors.text, 0.5) : Qt.alpha(Colors.text, 0.2))

                        Behavior on Layout.preferredWidth {
                            NumberAnimation { duration: 100 }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }    //onClicked: Hyprland.dispatch("workspace", (index + 1).toString())
                }
            }

            // RIGHT
            RowLayout {

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: Settings.spacing

                WifiIcon {}
                BatteryIcon {}
                VolumeIcon {}
                DateText {}
                TimeText {}
            }
        }
    }
}