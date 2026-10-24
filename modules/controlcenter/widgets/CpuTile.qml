import QtQuick

import qs.services

StatTile {
    icon: "cpu"
    label: "CPU"
    detail: Processor.usage + "% load"
    value: Processor.temp ? Processor.temp + "°" : "--"
    alert: Processor.hot

    history: Processor.tempHistory
    historyLength: Processor.historyLength
    graphMin: 20
    graphMax: 100
}
