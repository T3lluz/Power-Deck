import QtQuick

// One-shot, per-profile activation effect overlaid on a profile card.
// Effects:
//   pulse  — calm expanding eco rings        (Extreme Saver)
//   charge — battery-style fill sweep        (Power Saver)
//   sweep  — slim scanner bar gliding across (Balanced)
//   dash   — speed lines shooting through    (Performance)
Item {
    id: root

    property color accent: Theme.accent
    property string effect: "pulse"

    anchors.fill: parent

    function play() {
        if (effect === "charge") chargeAnim.restart()
        else if (effect === "sweep") sweepAnim.restart()
        else if (effect === "dash") dashAnim.restart()
        else pulseAnim.restart()
    }

    // ---- pulse (Extreme Saver) ----
    Rectangle {
        id: ring1
        anchors.centerIn: parent
        width: 18; height: 18; radius: 9
        color: "transparent"
        border.width: 2
        border.color: root.accent
        opacity: 0
    }
    Rectangle {
        id: ring2
        anchors.centerIn: parent
        width: 18; height: 18; radius: 9
        color: "transparent"
        border.width: 2
        border.color: root.accent
        opacity: 0
    }
    SequentialAnimation {
        id: pulseAnim
        ParallelAnimation {
            NumberAnimation { target: ring1; property: "scale"; from: 0.4; to: 7; duration: 620; easing.type: Easing.OutCubic }
            NumberAnimation { target: ring1; property: "opacity"; from: 0.75; to: 0; duration: 620 }
            SequentialAnimation {
                PauseAnimation { duration: 180 }
                ParallelAnimation {
                    NumberAnimation { target: ring2; property: "scale"; from: 0.4; to: 7; duration: 620; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ring2; property: "opacity"; from: 0.55; to: 0; duration: 620 }
                }
            }
        }
    }

    // ---- charge (Power Saver) ----
    Rectangle {
        id: chargeBar
        x: 0; y: 0
        height: parent.height
        width: 0
        radius: parent.height * 0.12
        color: root.accent
        opacity: 0
    }
    SequentialAnimation {
        id: chargeAnim
        PropertyAction { target: chargeBar; property: "opacity"; value: 0.22 }
        NumberAnimation { target: chargeBar; property: "width"; from: 0; to: root.width; duration: 460; easing.type: Easing.OutQuad }
        NumberAnimation { target: chargeBar; property: "opacity"; to: 0; duration: 280 }
        PropertyAction { target: chargeBar; property: "width"; value: 0 }
    }

    // ---- sweep (Balanced) ----
    Rectangle {
        id: scanBar
        y: -parent.height * 0.1
        width: 8
        height: parent.height * 1.2
        radius: 4
        rotation: 14
        color: root.accent
        opacity: 0
    }
    SequentialAnimation {
        id: sweepAnim
        PropertyAction { target: scanBar; property: "opacity"; value: 0.45 }
        NumberAnimation { target: scanBar; property: "x"; from: -12; to: root.width + 4; duration: 520; easing.type: Easing.InOutQuad }
        PropertyAction { target: scanBar; property: "opacity"; value: 0 }
    }

    // ---- dash (Performance) ----
    component DashLine: Rectangle {
        height: 2.5
        radius: 1.25
        color: root.accent
        opacity: 0
        width: root.width * 0.3
    }
    DashLine { id: dash1; y: root.height * 0.25 }
    DashLine { id: dash2; y: root.height * 0.5; width: root.width * 0.42 }
    DashLine { id: dash3; y: root.height * 0.72 }
    SequentialAnimation {
        id: dashAnim
        ParallelAnimation {
            SequentialAnimation {
                PropertyAction { target: dash1; property: "opacity"; value: 0.85 }
                NumberAnimation { target: dash1; property: "x"; from: -root.width * 0.3; to: root.width * 1.05; duration: 380; easing.type: Easing.InOutQuad }
                PropertyAction { target: dash1; property: "opacity"; value: 0 }
            }
            SequentialAnimation {
                PauseAnimation { duration: 80 }
                PropertyAction { target: dash2; property: "opacity"; value: 0.65 }
                NumberAnimation { target: dash2; property: "x"; from: -root.width * 0.42; to: root.width * 1.05; duration: 330; easing.type: Easing.InOutQuad }
                PropertyAction { target: dash2; property: "opacity"; value: 0 }
            }
            SequentialAnimation {
                PauseAnimation { duration: 150 }
                PropertyAction { target: dash3; property: "opacity"; value: 0.75 }
                NumberAnimation { target: dash3; property: "x"; from: -root.width * 0.3; to: root.width * 1.05; duration: 360; easing.type: Easing.InOutQuad }
                PropertyAction { target: dash3; property: "opacity"; value: 0 }
            }
        }
    }
}
