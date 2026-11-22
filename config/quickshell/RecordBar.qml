pragma ComponentBehavior: Bound
// 화면 녹화 도구 막대: 맥 ⌘⇧5처럼 지금 보고 있는 화면 아래 가운데에 뜬다.
// 무엇을(전체 화면 / 영역) 어떤 소리와(없음 / 시스템 소리 / 마이크) 녹화할지 고르고 '녹화'. Enter = 녹화, Esc = 닫기.
// 녹화와 멈추기는 ~/.config/hypr/scripts/screenrecord.sh가 한다 (Alt+Shift+5를 다시 누르거나 상단바 ● 표시를 누르면 멈춤)
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win

    readonly property int shadowRoom: 28
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/screenrecord.sh"
    property bool open: false
    property string target: "full" // full | area
    property string sound: "none" // none | system | mic (마지막 고른 값을 기억)
    property string screenName: ""

    function show() {
        screenName = Hyprland.focusedMonitor?.name ?? "";
        open = true;
        card.forceActiveFocus();
    }

    // 막대가 사라진 뒤에 시작해야 녹화에 찍히지 않는다
    function record() {
        open = false;
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; exec \"$0\" start \"$1\" \"$2\"", script, target, sound]);
    }

    screen: Quickshell.screens.find(s => s.name === screenName) ?? Quickshell.screens[0] ?? null
    visible: open || card.opacity > 0
    anchors.bottom: true
    margins.bottom: 40
    implicitWidth: card.width + shadowRoom * 2
    implicitHeight: card.height + shadowRoom * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-record"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: card }

    HyprlandFocusGrab {
        windows: [win]
        active: win.open
        onCleared: win.open = false
    }

    component Choice: Rectangle {
        id: choice

        property string icon
        property string label
        property bool on: false
        signal picked

        implicitWidth: Math.max(76, text.implicitWidth + 20)
        implicitHeight: 58
        radius: 14
        color: on ? Theme.mauve : area.containsMouse ? Theme.fillHover : "transparent"
        scale: area.pressed ? 0.95 : 1

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 90 } }

        Column {
            anchors.centerIn: parent
            spacing: 4

            Glyph {
                anchors.horizontalCenter: parent.horizontalCenter
                text: choice.icon
                font.pixelSize: 20
                color: choice.on ? Theme.base : Theme.text
            }

            Txt {
                id: text
                anchors.horizontalCenter: parent.horizontalCenter
                text: choice.label
                font.pixelSize: 11
                font.weight: choice.on ? Font.DemiBold : Font.Normal
                color: choice.on ? Theme.base : Theme.subtext1
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: choice.picked()
        }
    }

    component Divider: Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 40
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        color: Qt.rgba(1, 1, 1, 0.1)
    }

    Item {
        id: card

        x: win.shadowRoom
        y: win.shadowRoom
        width: row.implicitWidth + 24
        height: row.implicitHeight + 20
        opacity: win.open ? 1 : 0
        focus: true
        Keys.onEscapePressed: win.open = false
        Keys.onReturnPressed: win.record()
        Keys.onEnterPressed: win.record()

        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        transform: Translate {
            y: win.open ? 0 : 12
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        RectangularShadow {
            anchors.fill: bg
            radius: bg.radius
            blur: 22
            offset.y: 6
            color: Qt.rgba(0, 0, 0, 0.45)
        }

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 22
            color: Qt.alpha(Theme.base, 0.92)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
        }

        RowLayout {
            id: row

            x: 12
            y: 10
            spacing: 4

            Choice {
                icon: Icons.monitor
                label: "전체 화면"
                on: win.target === "full"
                onPicked: win.target = "full"
            }

            Choice {
                icon: "\u{f0489}"
                label: "영역 선택"
                on: win.target === "area"
                onPicked: win.target = "area"
            }

            Divider {}

            Choice {
                icon: Icons.volume(0, true)
                label: "소리 없음"
                on: win.sound === "none"
                onPicked: win.sound = "none"
            }

            Choice {
                icon: Icons.speaker
                label: "시스템 소리"
                on: win.sound === "system"
                onPicked: win.sound = "system"
            }

            Choice {
                icon: Icons.mic
                label: "마이크"
                on: win.sound === "mic"
                onPicked: win.sound = "mic"
            }

            Divider {}

            // 녹화 시작
            Rectangle {
                implicitWidth: 92
                implicitHeight: 58
                radius: 14
                color: recArea.containsMouse ? Qt.lighter(Theme.red, 1.06) : Theme.red
                scale: recArea.pressed ? 0.95 : 1

                Behavior on scale { NumberAnimation { duration: 90 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Glyph {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "\u{f044a}"
                        font.pixelSize: 18
                        color: Theme.base
                    }

                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "녹화"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.base
                    }
                }

                MouseArea {
                    id: recArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.record()
                }
            }

            IconButton {
                Layout.leftMargin: 4
                icon: Icons.close
                iconSize: 15
                iconColor: Theme.subtext0
                onClicked: win.open = false
            }
        }
    }
}
