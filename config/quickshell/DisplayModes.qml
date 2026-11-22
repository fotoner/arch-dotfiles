pragma ComponentBehavior: Bound
// 화면 구성 고르기: 확장 · 미러링 · 외부 모니터만 · 노트북만 (제어 센터와 설정 창에서 같이 쓴다)
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: modes

    property int tileHeight: 64

    Layout.fillWidth: true
    spacing: 8

    Repeater {
        model: [
            { kind: "extend", icon: Icons.monitors, label: "확장" },
            { kind: "mirror", icon: Icons.mirror, label: "미러링" },
            { kind: "external", icon: Icons.monitor, label: "외부만" },
            { kind: "internal", icon: Icons.laptop, label: "노트북만" }
        ]

        delegate: Rectangle {
            id: tile

            required property var modelData
            readonly property bool on: DS.topology === modelData.kind
            readonly property bool usable: !DS.pending && (DS.internal !== null || modelData.kind === "extend" || modelData.kind === "mirror")

            Layout.fillWidth: true
            implicitHeight: modes.tileHeight
            radius: 14
            color: on ? Theme.mauve : area.containsMouse && usable ? Theme.fillHover : Theme.fill
            border.width: 1
            border.color: on ? "transparent" : Theme.line
            opacity: usable || on ? 1 : 0.4
            scale: area.pressed ? 0.96 : 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 90 } }

            Column {
                anchors.centerIn: parent
                spacing: 5

                Glyph {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tile.modelData.icon
                    font.pixelSize: 20
                    color: tile.on ? Theme.base : Theme.text
                }

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tile.modelData.label
                    font.pixelSize: 11
                    font.weight: tile.on ? Font.DemiBold : Font.Normal
                    color: tile.on ? Theme.base : Theme.subtext1
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: tile.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (tile.usable) DS.setTopology(tile.modelData.kind)
            }
        }
    }
}
