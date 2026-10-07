pragma ComponentBehavior: Bound
// 소리 출력 장치 고르기 (사운드 카드 안에서 펼친다)
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
    id: list

    readonly property var sinks: Array.from(Pipewire.nodes.values).filter(n => n.isSink && !n.isStream && n.audio)

    Layout.fillWidth: true
    spacing: 2

    Repeater {
        model: list.sinks

        delegate: Item {
            id: entry

            required property var modelData
            readonly property bool current: Pipewire.defaultAudioSink === modelData
            readonly property string label: CC.sinkName(modelData)

            Layout.fillWidth: true
            Layout.leftMargin: -6
            Layout.rightMargin: -6
            implicitHeight: 34

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: area.containsMouse ? Theme.fill : "transparent"
            }

            RowLayout {
                x: 6
                width: parent.width - 12
                height: parent.height
                spacing: 10

                Glyph {
                    text: /head|bluez/i.test(entry.modelData.name + entry.label) ? Icons.headphones : Icons.speaker
                    font.pixelSize: 14
                    color: entry.current ? Theme.mauve : Theme.text
                }

                Txt {
                    Layout.fillWidth: true
                    text: entry.label
                    font.pixelSize: 12
                    font.weight: entry.current ? Font.DemiBold : Font.Normal
                }

                Glyph {
                    visible: entry.current
                    text: Icons.check
                    font.pixelSize: 14
                    color: Theme.mauve
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Pipewire.preferredDefaultAudioSink = entry.modelData
            }
        }
    }

    LinkRow {
        Layout.leftMargin: -6
        Layout.rightMargin: -6
        text: "소리 설정…"
        onClicked: CC.closeAndRun("pwvucontrol || pavucontrol")
    }
}
