pragma Singleton
import QtQuick

// Power Deck ROG theme: one place for the palette and the animation
// timings used by every component, so the whole panel moves and looks
// consistent.
QtObject {
    // ---- theme mode ----
    // Toggled from the widget config. When true the colored ROG accents
    // are replaced by a neutral grayscale palette (still distinct shades
    // so the different modes/states stay readable).
    property bool monochrome: false

    // ---- ROG palette ----
    readonly property color rogRed: "#ff3247"        // ROG signature accent
    readonly property color rogRedBright: "#ff5c6c"
    readonly property color rogTeal: "#2dd4bf"       // Extreme Saver
    readonly property color rogGreen: "#34d399"      // Power Saver
    readonly property color rogBlue: "#38bdf8"       // Balanced
    readonly property color rogAmber: "#fbbf24"      // Performance

    // ---- monochrome palette ----
    // Distinct gray levels so the four profiles and accents remain
    // distinguishable without any hue.
    readonly property color monoRed: "#e5e7eb"
    readonly property color monoRedBright: "#ffffff"
    readonly property color monoTeal: "#6b7280"
    readonly property color monoGreen: "#9ca3af"
    readonly property color monoBlue: "#cbd0d8"
    readonly property color monoAmber: "#f3f4f6"

    // ---- active palette ----
    readonly property color red: monochrome ? monoRed : rogRed
    readonly property color redBright: monochrome ? monoRedBright : rogRedBright
    readonly property color teal: monochrome ? monoTeal : rogTeal
    readonly property color green: monochrome ? monoGreen : rogGreen
    readonly property color blue: monochrome ? monoBlue : rogBlue
    readonly property color amber: monochrome ? monoAmber : rogAmber

    // ---- animation ----
    readonly property int durFast: 140
    readonly property int durMed: 240
    readonly property int durSlow: 380
    readonly property int easeOut: Easing.OutCubic
    readonly property int easeBack: Easing.OutBack

    // Opacity for content whose feature is toggled off.
    readonly property real offOpacity: 0.32

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}
