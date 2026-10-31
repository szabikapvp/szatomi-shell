import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../components/widgets"
import "../controlcenter"

import qs.config
import qs.utils
import qs.services

PanelWindow {
    id: bar

    property var modelData
    screen: modelData

    // Icons open its pages
    property var controlCenter

    readonly property url wifiPage: Qt.resolvedUrl("../controlcenter/WifiPage.qml")
    readonly property url powerPage: Qt.resolvedUrl("../controlcenter/PowerPage.qml")
    readonly property url settingsPage: Qt.resolvedUrl("../controlcenter/SettingsPage.qml")

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
            anchors.leftMargin: Settings.spacing
            anchors.rightMargin: Settings.spacing

            // LEFT
            RowLayout {

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: Settings.spacing
                
                BarButton {
                    tooltip: "CPU load " + Processor.usage + "%"
                    CpuTemp {}
                }
                //CpuUsage {}
                //MemoryUsage {}
            }

            // CENTER
            RowLayout {
                id: workspaceRow
                anchors.centerIn: parent

                Repeater {
                    model: Settings.workspaceCount // Number of workspaces

                    Rectangle {

                        property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                        property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

                        Layout.preferredWidth: isActive ? Settings.px(30) : Settings.px(10)
                        Layout.preferredHeight: Settings.px(10)
                        radius: Settings.px(5)
                        color: isActive ? Colors.primary : (ws ? Colors.text : Qt.alpha(Colors.text, 0.2))

                        Behavior on Layout.preferredWidth { Anim {} }

                        Behavior on color {
                            ColorAnim {}
                        }

                        MouseArea {
                            // Cover the gaps between dots and the full bar height
                            anchors.centerIn: parent
                            width: parent.width + workspaceRow.spacing
                            height: Settings.barHeight
                            cursorShape: Qt.PointingHandCursor
                            // Lua config only accepts Lua dispatchers, not the legacy "workspace N"
                            onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${index + 1} })`)
                        }
                    }
                }
            }

            // RIGHT
            RowLayout {

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: Settings.spacing

                // Left click opens the Wi-Fi page, right click turns Wi-Fi on or off
                BarButton {
                    active: bar.controlCenter?.currentPage === bar.wifiPage.toString()
                    tooltip: {
                        if (Network.ethernet) return "Ethernet"
                        if (!Network.wifiEnabled) return "Wi-Fi off"
                        if (Network.wifiStatus == "connected") return Network.networkName + " · " + Network.networkStrength + "%"
                        if (Network.wifiStatus == "connecting") return "Connecting..."
                        return "Not connected"
                    }

                    onClicked: (mouse) => {
                        if (mouse.button == Qt.RightButton) Network.toggleWifi()
                        else bar.controlCenter?.togglePage(bar.wifiPage)
                    }

                    WifiIcon {}
                }

                // Left out until UPower has read the battery, and on machines without one
                BarButton {
                    id: batteryButton
                    visible: Battery.available
                    active: bar.controlCenter?.currentPage === bar.powerPage.toString()
                    tooltip: Battery.level + "%" + (Battery.status ? " · " + Battery.status : "")

                    onClicked: bar.controlCenter?.togglePage(bar.powerPage)

                    // The low warning is the accent color too, so it would vanish on the accent fill
                    BatteryIcon { warn: Battery.low && !batteryButton.active }
                }

                // Click opens the audio settings, right click mutes, scrolling changes the volume
                BarButton {
                    active: bar.controlCenter?.currentPage === bar.settingsPage.toString() && bar.controlCenter.visiblePage.category === "Audio"
                    tooltip: Audio.isMuted ? "Muted" : "Volume " + Audio.level + "%"

                    onClicked: (mouse) => {
                        if (mouse.button == Qt.LeftButton) bar.controlCenter?.togglePage(bar.settingsPage, { category: "Audio" })
                        else Audio.toggleMute()
                    }
                    onScrolled: (notches) => Audio.adjust(notches * Settings.sliderScrollStep)

                    VolumeIcon {}
                }

                DateText {}
                TimeText {}
            }
        }
    }
}