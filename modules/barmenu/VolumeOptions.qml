import QtQuick
import QtQuick.Layouts
import "../../components/widgets"

import qs.config

// Right click menu of the volume button
ColumnLayout {
    signal controlCenterRequested(url page, var properties)

    readonly property int panelPadding: Settings.spacing / 2
    readonly property real innerRadius: Settings.buttonHeight.sm / 2

    width: Settings.barMenuItemWidth
    spacing: 0

    Button {
        type: "ghost"
        size: "sm"
        icon: "settings"
        text: "Sound settings"
        textColor: Colors.text

        onClicked: controlCenterRequested(Qt.resolvedUrl("../controlcenter/SettingsPage.qml"), { category: "Audio" })
    }
}
