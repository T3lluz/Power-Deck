import QtQuick
import QtQuick.Shapes

// Vector profile glyph drawn from individually animatable parts so each
// profile can play a smooth, calm motion that only touches the relevant
// piece, in a consistent visual language across all four:
//   balanced     — the speedometer needle sweeps and settles
//   power        — the battery lights its cells empty→full, then settles
//   performance  — the bolt flares while a few sparks fan out
//   extreme      — the leaf flutters once on the breeze
// Everything is painted in `glyphColor`, so the monochrome theme turns the
// whole glyph grayscale just by feeding it a neutral color.
//
// `layer.enabled` flattens all the parts into one surface *before* the
// glyph's own opacity is applied, so overlapping shapes never composite
// into a denser patch — the whole icon dims uniformly.
Item {
    id: glyph

    // extreme | power | balanced | performance
    property string kind: "balanced"
    property color glyphColor: Theme.blue
    property real glyphSize: 22
    // Match MetricIcon's inset when drawn in the panel (1.0 = fill the box).
    property real contentScale: 1.0
    // Extra uniform scale for the panel so the original art matches the CPU chip.
    property real opticalScale: 1.0
    // dims the glyph a touch when its profile is not the active one
    property bool active: true

    implicitWidth: glyphSize
    implicitHeight: glyphSize

    opacity: active ? 1.0 : 0.55
    layer.enabled: true
    layer.smooth: true

    Behavior on opacity { NumberAnimation { duration: Theme.durMed } }
    Behavior on glyphColor { ColorAnimation { duration: Theme.durMed } }

    function softColor(a) {
        return Qt.rgba(glyphColor.r, glyphColor.g, glyphColor.b, a)
    }

    // Plays the part-level activation motion for the current profile.
    function play() {
        switch (kind) {
            case "balanced":    needleAnim.restart(); break
            case "power":       chargeAnim.restart(); break
            case "performance": sparkAnim.restart(); break
            case "extreme":     leafAnim.restart(); break
        }
    }

    // animated state shared with the parts
    property real needleAngle: 0          // balanced
    // power: per-cell brightness, resting at a staggered "battery gauge" look
    property real cellA: 1.0
    property real cellB: 0.6
    property real cellC: 0.3
    property real boltGlow: 0             // performance
    property real leafAngle: 0            // extreme

    // ---- 24x24 design space, scaled to fit ----
    Item {
        id: design
        width: 24
        height: 24
        anchors.centerIn: parent
        scale: glyph.glyphSize * glyph.contentScale * glyph.opticalScale / 24
        transformOrigin: Item.Center

        // ===================== BALANCED =====================
        Item {
            anchors.fill: parent
            visible: glyph.kind === "balanced"

            // dial arc (static)
            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: glyph.softColor(0.5)
                    strokeWidth: 1.7
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: "M4 16.5 A8 8 0 0 1 20 16.5" }
                }
            }

            // needle (the only moving part)
            Shape {
                anchors.fill: parent
                antialiasing: true
                transform: Rotation {
                    origin.x: 12; origin.y: 16.5
                    angle: glyph.needleAngle
                }
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 1.9
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: "M12 16.5 L15.5 11.5" }
                }
            }

            // hub (static)
            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: glyph.glyphColor
                    PathSvg { path: "M10 16.5 A2 2 0 1 0 14 16.5 A2 2 0 1 0 10 16.5 Z" }
                }
            }

            SequentialAnimation {
                id: needleAnim
                PropertyAction { target: glyph; property: "needleAngle"; value: 40 }
                NumberAnimation {
                    target: glyph; property: "needleAngle"
                    to: -14; duration: Theme.durMed; easing.type: Easing.InOutCubic
                }
                NumberAnimation {
                    target: glyph; property: "needleAngle"
                    to: 0; duration: Theme.durSlow; easing.type: Easing.OutBack; easing.overshoot: 1.8
                }
            }
        }

        // ===================== POWER =====================
        Item {
            anchors.fill: parent
            visible: glyph.kind === "power"

            // battery body + terminal (static)
            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 1.7
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M5 7 L16.5 7 A2.5 2.5 0 0 1 19 9.5 L19 14.5 A2.5 2.5 0 0 1 16.5 17 L5 17 A2.5 2.5 0 0 1 2.5 14.5 L2.5 9.5 A2.5 2.5 0 0 1 5 7 Z" }
                }
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 2
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: "M21 10.5 L21 13.5" }
                }
            }

            // three charge cells that light up one by one, then settle back
            // to the staggered resting gauge
            Rectangle {
                x: 4.9; y: 9.8; width: 3; height: 4.4; radius: 0.9
                color: glyph.softColor(glyph.cellA)
            }
            Rectangle {
                x: 9.3; y: 9.8; width: 3; height: 4.4; radius: 0.9
                color: glyph.softColor(glyph.cellB)
            }
            Rectangle {
                x: 13.7; y: 9.8; width: 3; height: 4.4; radius: 0.9
                color: glyph.softColor(glyph.cellC)
            }

            SequentialAnimation {
                id: chargeAnim
                // start empty
                PropertyAction { target: glyph; property: "cellA"; value: 0.12 }
                PropertyAction { target: glyph; property: "cellB"; value: 0.12 }
                PropertyAction { target: glyph; property: "cellC"; value: 0.12 }
                // fill each cell in turn
                NumberAnimation { target: glyph; property: "cellA"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { target: glyph; property: "cellB"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { target: glyph; property: "cellC"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                PauseAnimation { duration: 240 }
                // settle smoothly back to the original staggered look
                ParallelAnimation {
                    NumberAnimation { target: glyph; property: "cellA"; to: 1.0; duration: Theme.durSlow; easing.type: Easing.InOutSine }
                    NumberAnimation { target: glyph; property: "cellB"; to: 0.6; duration: Theme.durSlow; easing.type: Easing.InOutSine }
                    NumberAnimation { target: glyph; property: "cellC"; to: 0.3; duration: Theme.durSlow; easing.type: Easing.InOutSine }
                }
            }
        }

        // ===================== PERFORMANCE =====================
        Item {
            anchors.fill: parent
            visible: glyph.kind === "performance"

            // soft glow flare behind the bolt (only visible mid-animation)
            Shape {
                anchors.fill: parent
                antialiasing: true
                opacity: glyph.boltGlow
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 4
                    fillColor: glyph.softColor(0.35)
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: "M13 2.5 L4.5 13.5 L10.5 13.5 L9.5 21.5 L18 10.5 L12 10.5 L13 2.5 Z" }
                }
            }

            // lightning bolt (static)
            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 1.7
                    fillColor: glyph.softColor(0.22)
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M13 2.5 L4.5 13.5 L10.5 13.5 L9.5 21.5 L18 10.5 L12 10.5 L13 2.5 Z" }
                }
            }

            // sparks fanning off the bolt
            component Spark: Rectangle {
                width: 2.2; height: 2.2
                radius: 0.55
                color: glyph.glyphColor
                rotation: 45
                antialiasing: true
                transformOrigin: Item.Center
                opacity: 0
                scale: 0.3
            }

            Spark { id: spark1; x: 17.4; y: 4.6 }
            Spark { id: spark2; x: 18.8; y: 11 }
            Spark { id: spark3; x: 4;    y: 17.6 }

            ParallelAnimation {
                id: sparkAnim

                SequentialAnimation {
                    NumberAnimation { target: glyph; property: "boltGlow"; to: 0.85; duration: Theme.durMed; easing.type: Easing.InOutSine }
                    NumberAnimation { target: glyph; property: "boltGlow"; to: 0; duration: Theme.durSlow; easing.type: Easing.InOutSine }
                }

                SequentialAnimation {
                    PropertyAction { target: spark1; property: "scale"; value: 0.3 }
                    PropertyAction { target: spark1; property: "opacity"; value: 0.9 }
                    ParallelAnimation {
                        NumberAnimation { target: spark1; property: "scale"; to: 1.15; duration: 300; easing.type: Easing.OutCubic }
                        NumberAnimation { target: spark1; property: "opacity"; to: 0; duration: 340; easing.type: Easing.InOutSine }
                    }
                }
                SequentialAnimation {
                    PauseAnimation { duration: 80 }
                    PropertyAction { target: spark2; property: "scale"; value: 0.3 }
                    PropertyAction { target: spark2; property: "opacity"; value: 0.85 }
                    ParallelAnimation {
                        NumberAnimation { target: spark2; property: "scale"; to: 1.1; duration: 300; easing.type: Easing.OutCubic }
                        NumberAnimation { target: spark2; property: "opacity"; to: 0; duration: 340; easing.type: Easing.InOutSine }
                    }
                }
                SequentialAnimation {
                    PauseAnimation { duration: 150 }
                    PropertyAction { target: spark3; property: "scale"; value: 0.3 }
                    PropertyAction { target: spark3; property: "opacity"; value: 0.8 }
                    ParallelAnimation {
                        NumberAnimation { target: spark3; property: "scale"; to: 1.05; duration: 300; easing.type: Easing.OutCubic }
                        NumberAnimation { target: spark3; property: "opacity"; to: 0; duration: 340; easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        // ===================== EXTREME =====================
        Item {
            anchors.fill: parent
            visible: glyph.kind === "extreme"
            transform: Rotation {
                origin.x: 12; origin.y: 19
                angle: glyph.leafAngle
            }

            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 1.7
                    fillColor: glyph.softColor(0.18)
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M19.5 4.5 C12 4.5 5.9 7.4 5.4 14.5 C5.2 17.3 7.1 19.5 10 19.5 C17.5 19.5 19.5 12.2 19.5 4.5 Z" }
                }
                ShapePath {
                    strokeColor: glyph.softColor(0.7)
                    strokeWidth: 1.7
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: "M7 18.5 C9.5 13.5 12.8 9.8 17 7.5" }
                }
            }

            SequentialAnimation {
                id: leafAnim
                NumberAnimation { target: glyph; property: "leafAngle"; from: 0; to: -13; duration: Theme.durMed; easing.type: Easing.InOutSine }
                NumberAnimation { target: glyph; property: "leafAngle"; to: 10; duration: Theme.durSlow; easing.type: Easing.InOutSine }
                NumberAnimation { target: glyph; property: "leafAngle"; to: -5; duration: Theme.durMed; easing.type: Easing.InOutSine }
                NumberAnimation { target: glyph; property: "leafAngle"; to: 0; duration: Theme.durMed; easing.type: Easing.InOutSine }
            }
        }
    }
}
