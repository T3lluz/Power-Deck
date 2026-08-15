import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

// Power profile card: animated vector glyph + name + short description.
// Compact row when short; a fixed-size centered tile on the landscape rail.
Item {
    id: root

    property string profileName: ""
    property string profileDesc: ""
    property string profileKind: "balanced"
    property color accentColor: Theme.accent
    property bool isActive: false
    property string burstEffect: "pulse"
    // Prefer the tall tile when the parent rail has room.
    property bool preferTile: true

    readonly property int tileHeight: Math.round(Kirigami.Units.gridUnit * 4.55)
    readonly property bool tileMode: preferTile
        && height >= Math.round(Kirigami.Units.gridUnit * 3.8)
    readonly property int glyphPx: tileMode
        ? Math.round(Kirigami.Units.gridUnit * 1.95)
        : Math.round(Kirigami.Units.gridUnit * 1.7)

    signal clicked()

    onIsActiveChanged: {
        if (isActive) {
            burst.play()
            tileBadge.play()
            rowBadge.play()
        }
    }

    Layout.fillWidth: true
    Layout.fillHeight: false
    Layout.preferredHeight: preferTile ? tileHeight : Math.round(Kirigami.Units.gridUnit * 2.6)
    Layout.minimumHeight: preferTile ? tileHeight : Math.round(Kirigami.Units.gridUnit * 2.6)
    Layout.maximumHeight: preferTile ? tileHeight : Math.round(Kirigami.Units.gridUnit * 2.6)

    scale: mouse.pressed ? 0.97 : 1.0
    Behavior on scale {
        NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Kirigami.Units.smallSpacing * 1.25
        color: root.isActive
            ? Theme.alpha(root.accentColor, 0.14)
            : (mouse.containsMouse
                ? Theme.alpha(Kirigami.Theme.textColor, 0.07)
                : Theme.alpha(Kirigami.Theme.textColor, 0.035))
        border.width: 1
        border.color: root.isActive
            ? Theme.alpha(root.accentColor, 0.55)
            : Theme.alpha(Kirigami.Theme.textColor, 0.09)
        clip: true

        Behavior on color {
            ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
        }

        // Active-tile sheen — a soft top-down wash so the selected profile
        // reads as the hero of the rail, not just a tinted border.
        Rectangle {
            visible: root.isActive
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.alpha(root.accentColor, 0.16) }
                GradientStop { position: 0.55; color: "transparent" }
            }
        }

        ProfileBurst {
            id: burst
            accent: root.accentColor
            effect: root.burstEffect
        }
    }

    // ---- tall tile (4:3 dashboard rail) ----
    ColumnLayout {
        visible: root.tileMode
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        anchors.topMargin: Kirigami.Units.smallSpacing * 1.25
        anchors.bottomMargin: Kirigami.Units.smallSpacing * 1.25
        spacing: Kirigami.Units.smallSpacing * 0.5

        Item { Layout.fillHeight: true }

        ProfileGlyph {
            id: tileBadge
            kind: root.profileKind
            glyphColor: root.accentColor
            glyphSize: root.glyphPx
            active: root.isActive
            Layout.preferredWidth: glyphSize
            Layout.preferredHeight: glyphSize
            Layout.alignment: Qt.AlignHCenter
        }

        PC3.Label {
            Layout.fillWidth: true
            text: root.profileName
            color: Kirigami.Theme.textColor
            font.weight: root.isActive ? Font.Bold : Font.DemiBold
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize + 1
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        PC3.Label {
            Layout.fillWidth: true
            text: root.profileDesc
            color: root.isActive
                ? Theme.alpha(root.accentColor, 0.95)
                : Kirigami.Theme.disabledTextColor
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            Behavior on color { ColorAnimation { duration: Theme.durMed } }
        }

        Item { Layout.fillHeight: true }
    }

    // ---- compact row (short / fallback) ----
    RowLayout {
        visible: !root.tileMode
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing * 1.25

        ProfileGlyph {
            id: rowBadge
            kind: root.profileKind
            glyphColor: root.accentColor
            glyphSize: root.glyphPx
            active: root.isActive
            Layout.preferredWidth: glyphSize
            Layout.preferredHeight: glyphSize
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PC3.Label {
                Layout.fillWidth: true
                text: root.profileName
                color: Kirigami.Theme.textColor
                font.weight: root.isActive ? Font.Bold : Font.Medium
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize + 1
                elide: Text.ElideRight
            }

            PC3.Label {
                Layout.fillWidth: true
                text: root.profileDesc
                color: root.isActive
                    ? Theme.alpha(root.accentColor, 0.95)
                    : Kirigami.Theme.disabledTextColor
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: Theme.durMed } }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
