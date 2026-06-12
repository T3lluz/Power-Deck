import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

Item {
    id: root

    property string profileName: ""
    property string profileDesc: ""
    property url iconSource
    property color accentColor: Kirigami.Theme.highlightColor
    property bool isActive: false

    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 2.2)

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.smallSpacing * 1.25
        color: root.isActive
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
            : (mouse.containsMouse
                ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.03))
        border.width: 1
        border.color: root.isActive
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)
            : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

        Behavior on color {
            ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing * 1.25
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        ProfileIconBadge {
            iconSource: root.iconSource
            accentColor: root.accentColor
            badgeSize: Math.round(Kirigami.Units.gridUnit * 1.4)
            active: root.isActive
        }

        PC3.Label {
            Layout.fillWidth: true
            text: root.profileName
            color: Kirigami.Theme.textColor
            font.weight: root.isActive ? Font.DemiBold : Font.Medium
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize + 1
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    PC3.ToolTip {
        text: root.profileDesc
        visible: mouse.containsMouse && root.profileDesc.length > 0
        delay: 600
    }
}
