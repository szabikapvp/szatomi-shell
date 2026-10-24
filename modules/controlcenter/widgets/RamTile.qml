import QtQuick

import qs.services

StatTile {
    icon: "ram"
    label: "RAM"
    detail: Memory.usedGb.toFixed(1) + " / " + Memory.totalGb.toFixed(1) + " GB"
    value: Memory.usage + "%"

    history: Memory.history
    historyLength: Memory.historyLength
}
