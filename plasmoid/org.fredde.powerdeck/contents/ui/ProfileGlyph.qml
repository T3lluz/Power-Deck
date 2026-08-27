import QtQuick
import QtQuick.Shapes
import QtQuick.Window

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
// Art is 48×48 (2× the 24 grid) so Shapes tessellate before they are
// scaled down. The layer texture follows the screen DPR so HiDPI stays
// sharp. `layer.enabled` flattens parts before opacity so overlaps dim
// uniformly.
Item {
    id: glyph

    property string kind: "balanced"
    property color glyphColor: Theme.blue
    property real glyphSize: 22
    property real contentScale: 1.0
    property real opticalScale: 1.0
    property bool active: true

    readonly property real artSize: 48
    readonly property real paintDpr: Math.max(1, Screen.devicePixelRatio) * 2

    implicitWidth: glyphSize
    implicitHeight: glyphSize

    opacity: active ? 1.0 : 0.55
    layer.enabled: true
    layer.smooth: true
    layer.textureSize: Qt.size(
        Math.max(1, Math.round(width * paintDpr)),
        Math.max(1, Math.round(height * paintDpr)))

    Behavior on opacity { NumberAnimation { duration: Theme.durMed } }
    Behavior on glyphColor { ColorAnimation { duration: Theme.durMed } }

    function softColor(a) {
        return Qt.rgba(glyphColor.r, glyphColor.g, glyphColor.b, a)
    }

    function play() {
        switch (kind) {
            case "balanced":    needleAnim.restart(); break
            case "power":       chargeAnim.restart(); break
            case "performance": sparkAnim.restart(); break
            case "extreme":     leafAnim.restart(); break
        }
    }

    property real needleAngle: 0
    property real cellA: 1.0
    property real cellB: 0.6
    property real cellC: 0.3
    property real boltGlow: 0
    property real leafAngle: 0

    Item {
        id: design
        width: glyph.artSize
        height: glyph.artSize
        anchors.centerIn: parent
        scale: glyph.glyphSize * glyph.contentScale * glyph.opticalScale / glyph.artSize
        transformOrigin: Item.Center

        // ===================== BALANCED =====================
        Item {
            anchors.fill: parent
            visible: glyph.kind === "balanced"

            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: glyph.softColor(0.5)
                    strokeWidth: 3.4
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: "M8 33 A16 16 0 0 1 40 33" }
                }
            }

            Shape {
                anchors.fill: parent
                antialiasing: true
                transform: Rotation {
                    origin.x: 24; origin.y: 33
                    angle: glyph.needleAngle
                }
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 3.8
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: "M24 33 L31 23" }
                }
            }

            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: glyph.glyphColor
                    PathSvg { path: "M20 33 A4 4 0 1 0 28 33 A4 4 0 1 0 20 33 Z" }
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

            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 3.4
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M10 14 L33 14 A5 5 0 0 1 38 19 L38 29 A5 5 0 0 1 33 34 L10 34 A5 5 0 0 1 5 29 L5 19 A5 5 0 0 1 10 14 Z" }
                }
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 4
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: "M42 21 L42 27" }
                }
            }

            Rectangle {
                x: 9.8; y: 19.6; width: 6; height: 8.8; radius: 1.8
                antialiasing: true
                color: glyph.softColor(glyph.cellA)
            }
            Rectangle {
                x: 18.6; y: 19.6; width: 6; height: 8.8; radius: 1.8
                antialiasing: true
                color: glyph.softColor(glyph.cellB)
            }
            Rectangle {
                x: 27.4; y: 19.6; width: 6; height: 8.8; radius: 1.8
                antialiasing: true
                color: glyph.softColor(glyph.cellC)
            }

            SequentialAnimation {
                id: chargeAnim
                PropertyAction { target: glyph; property: "cellA"; value: 0.12 }
                PropertyAction { target: glyph; property: "cellB"; value: 0.12 }
                PropertyAction { target: glyph; property: "cellC"; value: 0.12 }
                NumberAnimation { target: glyph; property: "cellA"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { target: glyph; property: "cellB"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { target: glyph; property: "cellC"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                PauseAnimation { duration: 240 }
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

            Shape {
                anchors.fill: parent
                antialiasing: true
                opacity: glyph.boltGlow
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 8
                    fillColor: glyph.softColor(0.35)
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: "M26 5 L9 27 L21 27 L19 43 L36 21 L24 21 L26 5 Z" }
                }
            }

            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 3.4
                    fillColor: glyph.softColor(0.22)
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M26 5 L9 27 L21 27 L19 43 L36 21 L24 21 L26 5 Z" }
                }
            }

            component Spark: Rectangle {
                width: 4.4; height: 4.4
                radius: 1.1
                color: glyph.glyphColor
                rotation: 45
                antialiasing: true
                transformOrigin: Item.Center
                opacity: 0
                scale: 0.3
            }

            Spark { id: spark1; x: 34.8; y: 9.2 }
            Spark { id: spark2; x: 37.6; y: 22 }
            Spark { id: spark3; x: 8;    y: 35.2 }

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
                origin.x: 24; origin.y: 38
                angle: glyph.leafAngle
            }

            Shape {
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: glyph.glyphColor
                    strokeWidth: 3.4
                    fillColor: glyph.softColor(0.18)
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M39 9 C24 9 11.8 14.8 10.8 29 C10.4 34.6 14.2 39 20 39 C35 39 39 24.4 39 9 Z" }
                }
                ShapePath {
                    strokeColor: glyph.softColor(0.7)
                    strokeWidth: 3.4
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: "M14 37 C19 27 25.6 19.6 34 15" }
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
