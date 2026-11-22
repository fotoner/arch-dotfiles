pragma ComponentBehavior: Bound
// 작은 선택 단추 줄 (주사율, 배율, 회전). 고른 것은 보라색으로 채운다
import QtQuick

Row {
    id: seg

    property var options: [] // [{ label, value }]
    property var current
    signal picked(var value)

    spacing: 6

    Repeater {
        model: seg.options

        delegate: Rectangle {
            id: chip

            required property var modelData
            readonly property bool on: chip.modelData.value === seg.current

            width: Math.max(52, label.implicitWidth + 22)
            height: 28
            radius: 9
            color: on ? Theme.mauve : area.containsMouse && seg.enabled ? Theme.fillHover : Theme.fill
            border.width: 1
            border.color: on ? "transparent" : Theme.line
            scale: area.pressed ? 0.95 : 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 90 } }

            Txt {
                id: label
                anchors.centerIn: parent
                text: chip.modelData.label
                font.pixelSize: 12
                font.weight: chip.on ? Font.DemiBold : Font.Normal
                color: chip.on ? Theme.base : Theme.text
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: seg.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (seg.enabled && !chip.on) seg.picked(chip.modelData.value)
            }
        }
    }
}
