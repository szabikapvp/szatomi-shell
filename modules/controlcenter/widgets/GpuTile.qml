import QtQuick

import qs.services

StatTile {
    icon: "gpu"
    label: "GPU"
    detail: Gpu.frequency ? Gpu.frequency + " MHz" : ""
    value: Gpu.supported ? Gpu.usage + "%" : "--"

    history: Gpu.history
    historyLength: Gpu.historyLength
}
