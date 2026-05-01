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
        top: true
        left: true
        right: true
    }

    margins {
        left: Settings.barMargin
        right: Settings.barMargin
        top: Settings.barMargin
    }

    implicitHeight: 22 + Settings.gap * 2
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Colors.background
        radius: Settings.radiusSm

        Item {

            anchors.fill: parent
            anchors.margins: Settings.gap
            anchors.leftMargin: Settings.gap * 2
            anchors.rightMargin: Settings.gap * 2

            // LEFT
            RowLayout {

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: Settings.gap
                
                CpuTemp {}
                CpuUsage {}
                MemoryUsage {}
            }

            // CENTER
            RowLayout {
                anchors.centerIn: parent
                
                Repeater {
                    model: 9 // Number of workspaces

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
                spacing: Settings.gap

                WifiIcon {}
                BatteryIcon {}
                VolumeIcon {}
                DateText {}
                TimeText {}
            }
        }
    }
}