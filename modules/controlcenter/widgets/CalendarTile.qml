import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.config

// Today's date, plus the whole month when the tile is larger than 2x2
Tile {
    id: root

    readonly property bool tall: rows > columns
    readonly property bool showMonth: columns > 2 || rows > 2

    readonly property date today: clock.date
    readonly property int firstWeekday: Qt.locale().firstDayOfWeek
    // Empty cells before the 1st, so it lands under its weekday
    readonly property int offset: (new Date(today.getFullYear(), today.getMonth(), 1).getDay() - firstWeekday + 7) % 7
    readonly property int daysInMonth: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: Settings.spacing * 2

        columns: root.tall ? 1 : 2
        rowSpacing: Settings.spacing * 2
        columnSpacing: Settings.spacing * 2

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: !root.tall
            Layout.preferredWidth: 1
            spacing: 0

            Text {
                text: Qt.formatDateTime(root.today, "dddd")
                color: Colors.primary
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.today.getDate()
                color: Colors.text
                font.family: Settings.headerFont
                font.pixelSize: Settings.fontSize * 4
                Layout.fillWidth: true
                Layout.fillHeight: !root.tall
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                text: Qt.formatDateTime(root.today, "MMMM yyyy")
                color: Qt.alpha(Colors.text, 0.6)
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize - 2
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        GridLayout {
            visible: root.showMonth

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1

            columns: 7
            rowSpacing: 0
            columnSpacing: 0

            Repeater {
                model: 7

                Text {
                    required property int index

                    // Named through formatDateTime like every other date, so the language matches. Jan 7 2024 was a Sunday
                    text: Qt.formatDateTime(new Date(2024, 0, 7 + (root.firstWeekday + index) % 7), "ddd").slice(0, 2)
                    color: Qt.alpha(Colors.text, 0.6)
                    font.family: Settings.fontFamily
                    font.pixelSize: Settings.fontSize - 4
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1
                }
            }

            Repeater {
                model: Math.ceil((root.offset + root.daysInMonth) / 7) * 7

                Item {
                    required property int index
                    readonly property int day: index - root.offset + 1
                    readonly property bool isToday: day == root.today.getDate()

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 1

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        radius: width / 2
                        color: Colors.primary
                        visible: parent.isToday
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: parent.day >= 1 && parent.day <= root.daysInMonth
                        text: parent.day
                        color: Colors.text
                        font.family: Settings.fontFamily
                        font.pixelSize: Settings.fontSize - 4
                        font.bold: parent.isToday
                    }
                }
            }
        }
    }
}
