pragma Singleton
import QtQuick

// Power Deck theme: one place for the palette and the animation
// timings used by every component, so the whole panel moves and looks
// consistent.
QtObject {
    // ---- theme mode ----
    // Toggled from the widget config. When true the colorful palette is
    // replaced by a clean grayscale UI lit by a single user-chosen accent
    // (or pure white for a fully neutral monochrome look).
    property bool monochrome: false

    // Index into monoAccents below, bound from the widget config. Only
    // meaningful while monochrome is on.
    property int accentChoice: 0

    // ---- base palette ----
    // A calm, modern primary accent (soft indigo) used for interactive
    // "on/active" states instead of a loud gaming red. Red is reserved
    // for genuine danger/critical states only.
    readonly property color hueAccent: "#7d93f0"     // primary interactive
    readonly property color hueAccentBright: "#9aacf5"
    readonly property color hueRed: "#f25563"        // danger / critical only
    readonly property color hueRedBright: "#ff6b78"
    readonly property color hueTeal: "#2dd4bf"       // Extreme Saver
    readonly property color hueGreen: "#34d399"      // Power Saver
    readonly property color hueBlue: "#56b6f0"       // Balanced
    readonly property color hueAmber: "#f4b73d"      // Performance

    // ---- monochrome accent options ----
    // The single hue that lights up the otherwise grayscale UI. The first
    // entry is a near-white so "White" gives a fully neutral monochrome.
    readonly property var monoAccents: [
        { name: "White",  base: "#e6e9ef", bright: "#ffffff" },
        { name: "Green",  base: "#34d399", bright: "#5fe6b5" },
        { name: "Teal",   base: "#2dd4bf", bright: "#5fe6d6" },
        { name: "Orange", base: "#fb923c", bright: "#fdb877" },
        { name: "Red",    base: "#f2596a", bright: "#ff7180" },
        { name: "Blue",   base: "#56b6f0", bright: "#85ccf6" },
        { name: "Purple", base: "#a78bfa", bright: "#c1acfc" }
    ]
    readonly property int monoIndex: Math.max(0, Math.min(accentChoice, monoAccents.length - 1))
    readonly property color monoSel: monoAccents[monoIndex].base
    readonly property color monoSelBright: monoAccents[monoIndex].bright

    // ---- neutral grayscale chrome (monochrome theme) ----
    // Crisp, higher-contrast tones so the panel never looks washed out.
    readonly property color monoText: "#e9ecf2"
    readonly property color monoNeutral: "#aeb4be"

    // ---- active palette ----
    // In monochrome, every formerly-colored role collapses onto the single
    // selected accent, so the panel reads as grayscale + one hue. Genuine
    // neutrals (muted text, inactive icons) stay gray below.
    readonly property color accent: monochrome ? monoSel : hueAccent
    readonly property color accentBright: monochrome ? monoSelBright : hueAccentBright
    readonly property color red: monochrome ? monoSel : hueRed
    readonly property color redBright: monochrome ? monoSelBright : hueRedBright
    readonly property color teal: monochrome ? monoSel : hueTeal
    readonly property color green: monochrome ? monoSel : hueGreen
    readonly property color blue: monochrome ? monoSel : hueBlue
    readonly property color amber: monochrome ? monoSel : hueAmber

    // Neutral wordmark / faint label tone — quiet, never a loud accent.
    readonly property color muted: monochrome ? monoNeutral : "#9aa7bd"

    // Section-header glyphs: a calm, cool tone for inactive headers; the
    // active per-section glyphs take a fitting hue normally and the chosen
    // accent in monochrome.
    readonly property color iconHeader: monochrome ? monoNeutral : "#8da4c0"
    readonly property color iconProfiles: monochrome ? monoSel : hueAccent   // indigo
    readonly property color iconGraphics: monochrome ? monoSel : "#a78bfa"  // violet
    readonly property color iconAnime: monochrome ? monoSel : "#f472b6"     // pink
    readonly property color iconKbd: monochrome ? monoSel : "#60a5fa"       // blue
    readonly property color iconRefresh: monochrome ? monoSel : "#22d3ee"   // cyan
    readonly property color iconCharge: monochrome ? monoSel : "#34d399"    // green
    readonly property color iconFn: monochrome ? monoSel : "#f4b73d"        // amber
    readonly property color iconFan: monochrome ? monoSel : "#fb923c"       // orange

    // ---- animation ----
    readonly property int durFast: 140
    readonly property int durMed: 240
    readonly property int durSlow: 380
    readonly property int durPage: 360
    readonly property int easeOut: Easing.OutCubic
    readonly property int easeBack: Easing.OutBack

    // Opacity for content whose feature is toggled off.
    readonly property real offOpacity: 0.32

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    // Temperature tint used by the popup pills and the panel metrics.
    function heatColor(temp) {
        if (temp < 0) return muted
        if (temp >= 85) return red
        if (temp >= 70) return amber
        return teal
    }

    // Charge/discharge rate: green while filling, then green → amber → red
    // as battery drain climbs (same thresholds as the header DRAW pill).
    function batteryFlowColor(state, watts) {
        if (state === "charging") return green
        if (state === "discharging") {
            if (watts >= 35) return red
            if (watts >= 20) return amber
            return green
        }
        return muted
    }
}
