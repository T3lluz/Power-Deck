import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

// Pill-shaped selectable chip (used for AniMe shapes and refresh rates).
Item {
    id: root

    property string label: ""
    property bool isActive: false
    property bool chipEnabled: true
    property color accentColor: Theme.accent
    // soft breathing glow, used for "pending until reboot" states
    property bool pulsing: false

    signal clicked()

    // sibling chips read these to agree on a common width
    readonly property bool isAnimeChip: true
    readonly property real labelWidth: labelText.implicitWidth

    // widest label among all chips sharing this row/column, so every
    // pill in a group gets the same minimum and the layout splits the
    // space evenly instead of giving longer labels wider pills
    readonly property real groupLabelWidth: {
        var w = labelWidth
        if (!parent) return w
        for (var i = 0; i < parent.children.length; i++) {
            var c = parent.children[i]
            if (c && c.isAnimeChip && c.labelWidth > w) w = c.labelWidth
        }
        return w
    }

    Layout.fillWidth: true
    // never squeeze the longest sibling label against the pill border
    Layout.minimumWidth: groupLabelWidth + Kirigami.Units.largeSpacing * 2
    Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.6)
    opacity: chipEnabled ? 1.0 : Theme.offOpacity
    Behavior on opacity {
        NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
    }

    scale: mouse.pressed && root.chipEnabled ? 0.94 : 1.0
    Behavior on scale {
        NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.isActive
            ? Theme.alpha(root.accentColor, 0.2)
            : (mouse.containsMouse && root.chipEnabled
                ? Theme.alpha(Kirigami.Theme.textColor, 0.07)
                : Theme.alpha(Kirigami.Theme.textColor, 0.035))
        border.width: 1
        border.color: root.isActive
            ? Theme.alpha(root.accentColor, 0.6)
            : Theme.alpha(Kirigami.Theme.textColor, 0.12)

        Behavior on color {
            ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
        }
    }

    Rectangle {
        id: glowRing
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border.width: 2
        border.color: root.accentColor
        opacity: 0
        visible: root.pulsing

        SequentialAnimation on opacity {
            running: root.pulsing
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { from: 0.15; to: 0.85; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.85; to: 0.15; duration: 900; easing.type: Easing.InOutSine }
        }
    }

    PC3.Label {
        id: labelText
        anchors.centerIn: parent
        width: Math.max(0, parent.width - Kirigami.Units.smallSpacing)
        text: root.label
        color: root.isActive ? root.accentColor : Kirigami.Theme.textColor
        font.weight: root.isActive ? Font.DemiBold : Font.Medium
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.chipEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.chipEnabled) root.clicked()
    }
}
