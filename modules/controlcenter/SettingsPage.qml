import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../components/widgets"

import qs.config

// Every setting from the schema, by category or by search
ColumnLayout {
    id: root

    signal back()
    signal pageRequested(url page)

    // Square, and wider than the grid, so the control center resizes to fit it
    readonly property int preferredWidth: Settings.settingsPageSize
    height: preferredWidth
    spacing: Settings.spacing * 2

    property string category: Settings.schema.categories[0]
    readonly property string query: search.text.trim().toLowerCase()
    readonly property var results: Settings.schema.entries.filter(entry => query == "" ? entry.category == category : matches(entry))

    onResultsChanged: scrollView.contentItem.contentY = 0

    PageHeader {
        title: "Settings"
        onBack: root.back()
    }

    InputField {
        id: search

        size: "md"
        icon: "search"
        placeholderText: "Search settings"
        rightIcon: text != "" ? "close" : ""

        onRightIconClicked: text = ""
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Settings.spacing * 2

        ColumnLayout {
            Layout.preferredWidth: root.width / 4
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignTop
            spacing: Settings.spacing / 2

            Repeater {
                model: Settings.schema.categories

                Button {
                    required property string modelData
                    readonly property bool selected: root.query == "" && root.category == modelData

                    size: "md"
                    icon: ""
                    text: modelData
                    type: selected ? "primary" : "ghost"
                    color: selected ? Colors.backgroundSubtle : Colors.foreground
                    textColor: Colors.text

                    onClicked: {
                        search.text = ""
                        root.category = modelData
                    }
                }
            }
        }

        ScrollView {
            id: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            contentWidth: availableWidth
            contentHeight: list.implicitHeight

            ScrollBar.vertical: StyledScrollBar {}

            ColumnLayout {
                id: list

                width: scrollView.availableWidth
                spacing: Settings.spacing

                Repeater {
                    model: root.results

                    SettingRow {
                        required property var modelData
                        entry: modelData
                        showCategory: root.query != ""

                        onPageRequested: (page) => root.pageRequested(page)
                    }
                }

                Text {
                    visible: root.results.length === 0

                    text: "No settings match"
                    color: Colors.text
                    font.pixelSize: Settings.fontSize
                    font.family: Settings.fontFamily
                    font.weight: 300
                    Layout.fillWidth: true
                    Layout.preferredHeight: Settings.px(64)
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    function matches(entry) {
        return [entry.label, entry.description ?? "", entry.category, entry.key].some(text => text.toLowerCase().includes(query))
    }
}
