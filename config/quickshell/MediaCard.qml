// 재생 중인 미디어. 제목을 누르면 그 앱 창으로 이동 (상단바 미디어와 같은 media-focus.sh)
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris

Card {
    id: card

    readonly property var players: Array.from(Mpris.players.values)
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null

    visible: player !== null
    Layout.fillWidth: true
    implicitHeight: 78

    // 재생 위치는 알아서 갱신되지 않아서, 보일 때만 1초마다 다시 읽는다
    Timer {
        running: CC.open && card.visible && (card.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        onTriggered: card.player.positionChanged()
    }

    // 왼쪽은 카드 안쪽 선(12px), 오른쪽은 버튼 아이콘이 그 선에 오도록 (버튼 안쪽 7px을 뺀 5px)
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 5
        anchors.topMargin: 11
        anchors.bottomMargin: 11
        spacing: 12

        ClippingRectangle {
            Layout.preferredWidth: 56
            Layout.preferredHeight: 56
            radius: 10
            color: Theme.surface1

            Image {
                id: art
                anchors.fill: parent
                source: card.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 112
                sourceSize.height: 112
            }

            Glyph {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: Icons.music
                font.pixelSize: 22
                color: Theme.overlay1
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Txt {
                Layout.fillWidth: true
                text: card.player?.trackTitle || card.player?.identity || ""
                font.weight: Font.DemiBold
            }

            Txt {
                Layout.fillWidth: true
                text: card.player?.trackArtist || card.player?.identity || ""
                font.pixelSize: 11
                color: Theme.subtext0
            }

            Rectangle {
                visible: (card.player?.lengthSupported ?? false) && card.player.length > 0
                Layout.fillWidth: true
                Layout.topMargin: 5
                implicitHeight: 3
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.10)

                Rectangle {
                    height: parent.height
                    radius: 2
                    width: parent.width * Math.min(1, (card.player?.position ?? 0) / Math.max(1, card.player?.length ?? 1))
                    color: Theme.subtext1
                }
            }
        }

        Row {
            spacing: 0

            IconButton {
                icon: Icons.prev
                enabled: card.player?.canGoPrevious ?? false
                onClicked: card.player.previous()
            }

            IconButton {
                icon: card.player?.isPlaying ? Icons.pause : Icons.play
                iconSize: 18
                width: 34
                height: 34
                anchors.verticalCenter: parent.verticalCenter
                enabled: card.player?.canTogglePlaying ?? false
                onClicked: card.player.togglePlaying()
            }

            IconButton {
                icon: Icons.next
                enabled: card.player?.canGoNext ?? false
                onClicked: card.player.next()
            }
        }
    }

    // 표지와 제목 부분을 누르면 그 앱으로 이동
    MouseArea {
        x: 0
        y: 0
        width: parent.width - 120
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: CC.closeAndRun("~/.config/hypr/scripts/media-focus.sh")
    }
}
