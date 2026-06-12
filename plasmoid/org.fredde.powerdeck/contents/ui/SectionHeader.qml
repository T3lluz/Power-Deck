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
    default property alias trailing: trailingRow.data

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing * 1.5

    ProfileIconBadge {
        visible: root.iconSource.toString().length > 0
        iconSource: root.iconSource
        accentColor: Theme.red
        badgeSize: Math.round(Kirigami.Units.gridUnit * 1.35)
        active: root.active
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
