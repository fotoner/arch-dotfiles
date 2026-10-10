// 맥 제어 센터 같은 굵은 막대 슬라이더. 왼쪽 아이콘을 누르면 iconClicked (음소거)
import QtQuick
import QtQuick.Layouts

Item {
    id: slider

    property real value: 0 // 0..1
    property string icon
    property bool dimmed: false
    signal moved(real value)
    signal iconClicked

    Layout.fillWidth: true
    implicitHeight: 28

    readonly property real shown: Math.max(0, Math.min(1, value))

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.08)

        Rectangle {
            id: fill
            height: parent.height
            radius: parent.radius
            width: height + (parent.width - height) * slider.shown
            color: slider.dimmed ? Theme.overlay0 : Theme.text
            Behavior on width {
                enabled: !dragArea.pressed
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }
    }

    // 아이콘은 왼쪽 둥근 끝의 정중앙에. 밝기·소리 아이콘 폭이 달라도 같은 세로줄에 선다
    Glyph {
        x: (parent.height - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        text: slider.icon
        font.pixelSize: 14
        color: Theme.base
    }

    Txt {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(slider.value * 100) + "%"
        font.pixelSize: 11
        font.features: { "tnum": 1 }
        color: fill.width > slider.width - 40 ? Theme.base : Theme.subtext0
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.leftMargin: 30
        cursorShape: Qt.PointingHandCursor
        function set(mx) {
            const x = mx + anchors.leftMargin - track.height / 2;
            slider.moved(Math.max(0, Math.min(1, x / (track.width - track.height))));
        }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x); }
        onWheel: wheel => slider.moved(Math.max(0, Math.min(1, slider.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }

    MouseArea {
        width: 30
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: slider.iconClicked()
    }
}
