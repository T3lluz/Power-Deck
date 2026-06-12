pragma Singleton
import QtQuick

// Power Deck ROG theme: one place for the palette and the animation
// timings used by every component, so the whole panel moves and looks
// consistent.
QtObject {
    // ---- palette ----
    readonly property color red: "#ff3247"          // ROG signature accent
    readonly property color redBright: "#ff5c6c"
    readonly property color teal: "#2dd4bf"         // Extreme Saver
    readonly property color green: "#34d399"        // Power Saver
    readonly property color blue: "#38bdf8"         // Balanced
    readonly property color amber: "#fbbf24"        // Performance

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
