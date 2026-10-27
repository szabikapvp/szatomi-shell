import QtQuick

import qs.config

// For Behaviors on opacity. Still plays with reduce motion, since fading is what replaces movement there
NumberAnimation {
    duration: Settings.motionDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Settings.springCurve
}
