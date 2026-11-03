import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../components"
import "../../components/widgets"

import qs.config
import qs.services

// Charge level with what it's doing, and the power profile
ColumnLayout {
    // Fits the profile buttons' pills
    readonly property real innerRadius: Settings.buttonHeight.sm / 2

    width: Settings.barMenuWidth
    spacing: Settings.spacing * 2

    // The level as large as the status and bar beside it, top to bottom
    RowLayout {
        Layout.fillWidth: true
        spacing: Settings.spacing * 2

        StyledText {
            text: Battery.level + "%"
            font.pixelSize: Settings.fontSize * 3
            font.bold: true
            trimmed: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Settings.spacing

            StyledText {
                text: Battery.status
                color: Qt.alpha(Colors.text, 0.6)
                font.pixelSize: Settings.fontSize - Settings.px(2)
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Pushes the bar down to the bottom of the level
            Item { Layout.fillHeight: true }

            Slider {
                prop: Battery.level
                Layout.preferredHeight: Settings.px(6)
            }
        }
    }

    // Set through power-profiles-daemon
    Choices {
        options: [
            { text: "Power saver", value: PowerProfile.PowerSaver },
            { text: "Balanced", value: PowerProfile.Balanced }
        ].concat(PowerProfiles.hasPerformanceProfile ? [{ text: "Performance", value: PowerProfile.Performance }] : [])
        current: PowerProfiles.profile

        onPicked: (value) => PowerProfiles.profile = value
    }
}
