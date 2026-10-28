import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../components/widgets"

import qs.config
import qs.services

// Every setting from the schema, by category or by search
ColumnLayout {
    id: root

    signal back()
    signal pageRequested(url page, var properties)

    // Square, and wider than the grid, so the control center resizes to fit it
    readonly property int preferredWidth: Settings.settingsPageSize
    height: preferredWidth
    spacing: Settings.spacing * 2

    property string category: Settings.schema.categories[0]
    readonly property string query: search.text.trim().toLowerCase()
    readonly property var results: Settings.schema.entries.filter(entry => available(entry) && (query == "" ? entry.category == category : matches(entry)))

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

        // Scrolls once the categories outgrow a small page
        StyledScrollView {
            id: categoryView

            Layout.preferredWidth: root.width / 4
            Layout.fillWidth: false
            Layout.fillHeight: true

            // Room for the focus ring, which the scroll area would cut off
            readonly property int inset: Settings.focusRingWidth * 2
            contentHeight: categoryList.implicitHeight + inset * 2

            ColumnLayout {
                id: categoryList

                x: categoryView.inset
                y: categoryView.inset
                width: categoryView.availableWidth - categoryView.inset * 2
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
        }

        StyledScrollView {
            id: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            contentHeight: list.implicitHeight

            ColumnLayout {
                id: list

                width: scrollView.availableWidth
                spacing: Settings.spacing

                Repeater {
                    model: root.results

                    ColumnLayout {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        spacing: Settings.spacing

                        // Over the first setting of each group. Search results name their category instead
                        GroupLabel {
                            visible: root.query == "" && modelData.group !== undefined && modelData.group != root.results[index - 1]?.group
                            text: modelData.group ?? ""
                            Layout.topMargin: index == 0 ? 0 : Settings.spacing
                        }

                        SettingRow {
                            entry: modelData
                            showCategory: root.query != ""

                            onPageRequested: (page, properties) => root.pageRequested(page, properties)
                        }
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

    // Hidden ones are never listed, ones about several displays only once there are several
    function available(entry) {
        if (entry.hidden) return false
        switch (entry.type) {
            case "displayMode": return Displays.onCount > 1 || Displays.mirroring
            case "arrangement":
            case "display": return Displays.arrangedCount > 1
        }
        return true
    }

    function matches(entry) {
        return [entry.label, entry.description ?? "", entry.category, entry.key].some(text => text.toLowerCase().includes(query))
    }
}
