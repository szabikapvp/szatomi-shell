import QtQuick

import qs.config

// For Behaviors on position, size and scale. Traces the default spring's curve, and snaps with reduce motion
NumberAnimation {
    // Press and hover feedback, which has to keep up with the pointer
    property bool fast: false

    duration: Settings.reduceMotion ? 0 : fast ? Settings.motionFastDuration : Settings.motionDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Settings.springCurve
}
