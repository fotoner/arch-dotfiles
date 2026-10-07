// Wi-Fi·블루투스 칸: 동그라미를 누르면 켜고 끄고, 나머지를 누르면 기기 목록을 펼친다.
// 오른쪽 빠른 버튼(66px)과 같은 높이라 두 줄이 한 격자에 맞는다
import QtQuick
import QtQuick.Layouts

Item {
    id: row

    property string icon
    property string title
    property string subtitle
    property bool active: false
    property bool expanded: false
    signal toggled
    signal expandRequested

    Layout.fillWidth: true
    implicitHeight: 66

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: row.expanded || expandArea.containsMouse ? Theme.fillHover : Theme.fill
        border.width: 1
        border.color: Theme.line
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: expandArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.expandRequested()
    }

    Rectangle {
        id: circle
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 32
        radius: 16
        color: row.active ? Theme.mauve : Theme.surface1
        scale: toggleArea.pressed ? 0.9 : 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 90 } }

        Glyph {
            anchors.centerIn: parent
            text: row.icon
            color: row.active ? Theme.base : Theme.subtext1
        }

        MouseArea {
            id: toggleArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.toggled()
        }
    }

    Column {
        anchors.left: circle.right
        anchors.leftMargin: 10
        anchors.right: chevron.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Txt {
            width: parent.width
            text: row.title
            font.weight: Font.DemiBold
        }

        Txt {
            width: parent.width
            text: row.subtitle
            font.pixelSize: 11
            color: Theme.subtext0
        }
    }

    Glyph {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: "\u{f0142}"
        font.pixelSize: 14
        color: Theme.overlay1
        rotation: row.expanded ? 90 : 0
        Behavior on rotation { NumberAnimation { duration: 150 } }
    }
}
