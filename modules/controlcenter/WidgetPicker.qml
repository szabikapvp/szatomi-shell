import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../components/widgets"

import qs.config

// Every widget not on the grid yet, each shown as its real tile, shrunk, at the size it would be added at
ColumnLayout {
    id: root

    required property var grid

    signal back()

    readonly property var available: grid.catalog.entries.filter(entry => !grid.widgets.some(w => w.type === entry.type))

    readonly property real cardWidth: (width - Settings.spacing) / 2
    // A widget as wide as the grid fills its card
    readonly property real previewScale: (cardWidth - Settings.spacing * 2) / grid.implicitWidth

    height: Settings.controlCenterPageHeight
    spacing: Settings.spacing * 2

    PageHeader {
        title: "Add widget"
        onBack: root.back()
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.backgroundSubtle
    }

    ScrollView {
        id: scrollView

        visible: root.available.length > 0
        Layout.fillWidth: true
        Layout.fillHeight: true

        clip: true
        contentWidth: availableWidth
        contentHeight: cards.implicitHeight

        ScrollBar.vertical: StyledScrollBar {}

        GridLayout {
            id: cards

            width: scrollView.availableWidth
            columns: 2
            columnSpacing: Settings.spacing
            rowSpacing: Settings.spacing

            Repeater {
                model: root.available

                Rectangle {
                    id: card

                    required property var modelData
                    readonly property var spot: root.grid.spotFor(modelData.type)
                    // Without room, shown at its first size instead
                    readonly property var size: spot ? [spot.w, spot.h] : root.grid.sizesOf(modelData)[0]

                    Layout.preferredWidth: root.cardWidth
                    Layout.fillHeight: true
                    implicitHeight: content.implicitHeight + Settings.spacing * 2

                    radius: Settings.radiusLg
                    color: Qt.alpha(Colors.foreground, area.pressed ? 0.1 : area.containsMouse ? 0.05 : 0)
                    opacity: spot ? 1 : 0.4

                    Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        id: content

                        x: Settings.spacing
                        y: Settings.spacing
                        width: parent.width - Settings.spacing * 2
                        spacing: Settings.spacing

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: preview.height * root.previewScale

                            Loader {
                                id: preview

                                x: (parent.width - width * root.previewScale) / 2
                                width: card.size[0] * root.grid.pitch - root.grid.gap
                                height: card.size[1] * root.grid.pitch - root.grid.gap
                                scale: root.previewScale
                                transformOrigin: Item.TopLeft

                                // Only a picture, the card takes the clicks
                                enabled: false
                                source: card.modelData.tile

                                onLoaded: {
                                    item.columns = Qt.binding(() => card.size[0])
                                    item.rows = Qt.binding(() => card.size[1])
                                }
                            }
                        }

                        Text {
                            text: card.spot ? card.modelData.name : card.modelData.name + " (no room)"
                            color: Colors.text
                            font.pixelSize: Settings.fontSize
                            font.family: Settings.fontFamily
                            font.bold: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                    }

                    // On top of the preview, whose own mouse areas would show their cursors otherwise
                    MouseArea {
                        id: area

                        anchors.fill: parent
                        enabled: card.spot !== null
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : undefined

                        // Adding drops this card from the list mid handler, so take what's needed first
                        onClicked: {
                            const page = root
                            page.grid.add(card.modelData.type)
                            page.back()
                        }
                    }
                }
            }
        }
    }

    Text {
        visible: root.available.length === 0

        text: "Every widget is already placed"
        color: Colors.text
        font.pixelSize: Settings.fontSize
        font.family: Settings.fontFamily
        font.weight: 300
        Layout.fillWidth: true
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
}
