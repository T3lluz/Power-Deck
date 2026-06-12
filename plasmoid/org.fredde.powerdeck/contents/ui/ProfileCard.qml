import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

// Power profile card: icon + name + short description, with a slanted ROG
// accent bar and glow when active, and a press "squeeze" animation.
Item {
    id: root

    property string profileName: ""
    property string profileDesc: ""
    property url iconSource
    property color accentColor: Theme.red
    property bool isActive: false
    property string burstEffect: "pulse"

    signal clicked()

    onIsActiveChanged: {
        if (isActive) {
            burst.play()
            iconPop.restart()
        }
    }

    Layout.fillWidth: true
    Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 2.6)

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

        // per-profile one-shot activation effect
        ProfileBurst {
            id: burst
            accent: root.accentColor
            effect: root.burstEffect
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing * 1.25

        ProfileIconBadge {
            id: badge
            iconSource: root.iconSource
            accentColor: root.accentColor
            badgeSize: Math.round(Kirigami.Units.gridUnit * 1.5)
            active: root.isActive

            // little "pop" when this profile becomes active
            SequentialAnimation {
                id: iconPop
                NumberAnimation {
                    target: badge; property: "scale"
                    from: 1.0; to: 1.28; duration: Theme.durFast
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: badge; property: "scale"
                    to: 1.0; duration: Theme.durMed
                    easing.type: Theme.easeBack; easing.overshoot: 2.5
                }
            }
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
