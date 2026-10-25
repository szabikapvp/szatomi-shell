import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell.Widgets

import qs.config
import qs.services
import qs.utils

// Every image in the wallpaper folder in one row, scrolling sideways. Clicking one sets it
ColumnLayout {
    id: root

    signal back()

    readonly property int preferredWidth: Settings.wallpaperPageWidth
    // Opened from the Theme settings, so back returns there
    readonly property url parentPage: Qt.resolvedUrl("SettingsPage.qml")
    readonly property var parentProperties: ({ category: "Theme" })

    spacing: Settings.spacing * 2

    // Rounded like the thumbnails, so one cut off at the edge still gets round corners
    ClippingRectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Settings.wallpaperThumbHeight

        radius: Settings.radiusMd
        color: "transparent"

        ListView {
            id: list

            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: Settings.spacing
            boundsBehavior: Flickable.StopAtBounds

            model: FolderListModel {
                folder: "file://" + Wallpaper.folder
                nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]
                caseSensitive: false
                showDirs: false
            }

            delegate: Item {
                id: thumb

                required property string filePath
                readonly property bool current: filePath == Wallpaper.current

                width: height * 16 / 9
                height: ListView.view.height

                ClippingRectangle {
                    anchors.fill: parent
                    radius: Settings.radiusMd
                    color: Colors.backgroundSubtle

                    Image {
                        anchors.fill: parent
                        source: "file://" + thumb.filePath
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.alpha(Colors.background, area.pressed ? 0.4 : area.containsMouse ? 0.2 : 0)

                        Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    }
                }

                // Drawn over the image, so the outline isn't covered at the corners
                Rectangle {
                    anchors.fill: parent
                    radius: Settings.radiusMd
                    color: "transparent"
                    border.width: Settings.px(3)
                    border.color: Colors.primary
                    opacity: thumb.current ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Settings.popDuration } }
                }

                // pywal working on this one's palette
                Loading {
                    anchors.centerIn: parent
                    visible: thumb.current && Wallpaper.generating
                }

                MouseArea {
                    id: area

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: Wallpaper.set(thumb.filePath)
                }
            }
        }

        // Scrolls sideways with either axis, so a mouse wheel works too. A sideways swipe that can't scroll
        // any further passes through, so the back swipe still works at the start
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton

            onWheel: (wheel) => {
                const dx = wheel.pixelDelta.x != 0 ? wheel.pixelDelta.x : wheel.angleDelta.x
                const dy = wheel.pixelDelta.y != 0 ? wheel.pixelDelta.y : wheel.angleDelta.y
                const sideways = Math.abs(dx) > Math.abs(dy)

                const end = list.originX + Math.max(0, list.contentWidth - list.width)
                const target = Math.max(list.originX, Math.min(end, list.contentX - (sideways ? dx : dy) * Settings.wallpaperScrollSpeed))
                if (sideways && target == list.contentX) {
                    wheel.accepted = false
                    return
                }

                list.contentX = target
            }
        }

        Text {
            anchors.centerIn: parent
            visible: list.count == 0

            text: "No images in " + Settings.wallpaperFolder
            color: Qt.alpha(Colors.text, 0.6)
            font.pixelSize: Settings.fontSize
            font.family: Settings.fontFamily
            font.weight: 300
        }
    }
}
