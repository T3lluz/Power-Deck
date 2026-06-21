import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Rounded-square icon badge that lights up in its accent color when active.
Rectangle {
    id: root

    property url iconSource
    property color accentColor: Theme.accent
    property int badgeSize: Math.round(Kirigami.Units.gridUnit * 1.75)
    property bool active: false
    // When true, drop the rounded-square container and render the glyph
    // large so it stays legible (matches the panel icon style).
    property bool bare: false
    // The glyph is recolored to this tone (defaults to the accent), so the
    // SVG's baked-in hue never leaks through and the monochrome theme can
    // turn every icon grayscale via the Theme palette.
    property color glyphColor: accentColor

    implicitWidth: badgeSize
    implicitHeight: badgeSize
    Layout.preferredWidth: badgeSize
    Layout.preferredHeight: badgeSize
    Layout.alignment: Qt.AlignVCenter

    radius: Math.round(badgeSize * 0.3)
    color: bare ? "transparent" : Theme.alpha(accentColor, active ? 0.26 : 0.1)
    border.width: bare ? 0 : 1
    border.color: bare ? "transparent" : Theme.alpha(accentColor, active ? 0.55 : 0.18)

    Behavior on color {
        ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
    }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Math.round(root.badgeSize * (root.bare ? 0.92 : 0.62))
        height: width
        source: root.iconSource
        // Treat the SVG as a mask and paint it in glyphColor so the icon
        // follows the active theme instead of its hard-coded hue.
        isMask: true
        color: root.glyphColor
        smooth: true
        opacity: root.active ? 1 : 0.65
        Behavior on opacity {
            NumberAnimation { duration: Theme.durMed }
        }
        Behavior on color {
            ColorAnimation { duration: Theme.durMed }
        }
    }
}
