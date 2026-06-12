import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

// Animated ROG-style checkbox: the box fills with the accent color and the
// check mark pops in with a small overshoot.
Item {
    id: root

    property bool checked: false
    property string text: ""
    property color accent: Theme.red

    signal toggled(bool checked)

    implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.1)
    implicitWidth: row.implicitWidth
    Layout.preferredHeight: implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            id: box
            Layout.preferredWidth: Math.round(Kirigami.Units.gridUnit * 0.85)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            radius: 4
            color: root.checked
                ? Theme.alpha(root.accent, 0.9)
                : Theme.alpha(Kirigami.Theme.textColor, 0.06)
            border.width: 1
            border.color: root.checked
                ? Theme.alpha(Theme.redBright, 0.9)
                : Theme.alpha(Kirigami.Theme.textColor, 0.25)
            Behavior on color {
                ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
            }
            Behavior on border.color {
                ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
            }

            PC3.Label {
                anchors.centerIn: parent
                text: "✓"
                color: "#ffffff"
                font.pixelSize: Math.round(box.height * 0.72)
                font.weight: Font.Bold
                scale: root.checked ? 1 : 0
                opacity: root.checked ? 1 : 0
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.durMed
                        easing.type: Theme.easeBack
                        easing.overshoot: 2.2
                    }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.durFast }
                }
            }
        }

        PC3.Label {
            Layout.fillWidth: true
            text: root.text
            color: root.checked ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            elide: Text.ElideRight
            Behavior on color {
                ColorAnimation { duration: Theme.durMed }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
