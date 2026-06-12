import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Animated ROG-style toggle: sliding knob with overshoot, track lights up
// in the accent color and gets a soft glow when on.
Item {
    id: root

    property bool checked: false
    property color accent: Theme.red

    signal toggled(bool checked)

    implicitWidth: Math.round(Kirigami.Units.gridUnit * 2.05)
    implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.1)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignVCenter

    // soft outer glow when on
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: height / 2
        color: Theme.alpha(root.accent, 0.16)
        opacity: root.checked ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
        }
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked
            ? Theme.alpha(root.accent, 0.9)
            : Theme.alpha(Kirigami.Theme.textColor, 0.12)
        border.width: 1
        border.color: root.checked
            ? Theme.alpha(Theme.redBright, 0.9)
            : Theme.alpha(Kirigami.Theme.textColor, 0.22)
        Behavior on color {
            ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
        }
    }

    Rectangle {
        id: knob
        width: parent.height - 6
        height: width
        radius: width / 2
        y: 3
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? "#ffffff" : Theme.alpha(Kirigami.Theme.textColor, 0.6)
        Behavior on x {
            NumberAnimation {
                duration: Theme.durMed
                easing.type: Theme.easeBack
                easing.overshoot: 1.1
            }
        }
        Behavior on color {
            ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -Kirigami.Units.smallSpacing
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
