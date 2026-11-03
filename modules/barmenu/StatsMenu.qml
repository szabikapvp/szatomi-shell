import QtQuick
import QtQuick.Layouts
import "../../components"

import qs.config
import qs.services

// Load of the processor, memory and graphics card
ColumnLayout {
    width: Settings.barMenuWidth
    spacing: Settings.spacing * 2

    component Stat: ColumnLayout {
        id: stat

        property string icon
        property string name
        property string detail
        property int usage

        Layout.fillWidth: true
        spacing: Settings.spacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Settings.spacing

            Icon { icon: stat.icon }

            StyledText {
                text: stat.name
                color: Colors.text
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize
                font.bold: true
            }

            StyledText {
                text: stat.detail
                color: Qt.alpha(Colors.text, 0.6)
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize - Settings.px(2)
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            StyledText {
                text: stat.usage + "%"
                color: Colors.text
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontSize
                font.bold: true
            }
        }

        Slider {
            prop: stat.usage
            Layout.preferredHeight: Settings.px(6)
        }
    }

    Stat {
        icon: "cpu"
        name: "CPU"
        detail: Processor.temp + "°C"
        usage: Processor.usage
    }

    Stat {
        icon: "ram"
        name: "Memory"
        detail: Memory.usedGb.toFixed(1) + " / " + Memory.totalGb.toFixed(1) + " GB"
        usage: Memory.usage
    }

    Stat {
        visible: Gpu.supported
        icon: "gpu"
        name: "GPU"
        detail: Gpu.frequency > 0 ? Gpu.frequency + " MHz" : ""
        usage: Gpu.usage
    }
}
