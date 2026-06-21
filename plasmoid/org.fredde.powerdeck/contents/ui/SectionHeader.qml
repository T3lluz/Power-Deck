import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

// ROG-style section header: icon badge, uppercase section title, and room
// for trailing controls (switch, value).
RowLayout {
    id: root

    property string title: ""
    property url iconSource
    property bool active: true
    // Per-section glyph tint — a fitting hue in the normal theme, neutral
    // gray in monochrome (callers pass a Theme.icon* color).
    property color glyphColor: Theme.iconHeader
    // When true, swap the static icon for the live AniMe Matrix glyph whose
    // dots blink on their own. `animeAnimate` pauses that idle motion.
    property bool animeGlyph: false
    property bool animeAnimate: true
    default property alias trailing: trailingRow.data

    readonly property int badgeSize: Math.round(Kirigami.Units.gridUnit * 1.55)

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing * 1.5

    ProfileIconBadge {
        visible: !root.animeGlyph && root.iconSource.toString().length > 0
        iconSource: root.iconSource
        accentColor: Theme.accent
        glyphColor: root.active ? root.glyphColor : Theme.iconHeader
        badgeSize: root.badgeSize
        active: root.active
        bare: true
    }

    AnimeGlyph {
        visible: root.animeGlyph
        glyphColor: root.active ? root.glyphColor : Theme.iconHeader
        glyphSize: Math.round(root.badgeSize * 0.92)
        active: root.active
        animate: root.animeAnimate
        Layout.preferredWidth: root.badgeSize
        Layout.preferredHeight: root.badgeSize
        Layout.alignment: Qt.AlignVCenter
    }

    PC3.Label {
        Layout.fillWidth: true
        text: root.title
        color: root.active ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        font.weight: Font.DemiBold
        font.letterSpacing: 1.6
        elide: Text.ElideRight
        Behavior on color { ColorAnimation { duration: Theme.durMed } }
    }

    RowLayout {
        id: trailingRow
        spacing: Kirigami.Units.smallSpacing
    }
}
