import QtQuick

import qs.config

// For Behaviors on color. Fast, so hover and press feedback keeps up with the pointer
ColorAnimation {
    duration: Settings.motionFastDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Settings.springCurve
}
