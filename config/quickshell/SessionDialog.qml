pragma ComponentBehavior: Bound
// 로그아웃 확인 창 (맥 ⌘⇧Q처럼): Alt+Shift+Q 또는 Super+M. 지금 보고 있는 화면 가운데에 뜬다.
// 실수로 눌러도 바로 로그아웃되지 않게, "로그아웃"을 누르거나 Enter를 눌러야 앱을 닫고 로그아웃한다. Esc·바깥 누르기 = 취소
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win

    readonly property int shadowRoom: 28
    property bool open: false
    property string screenName: ""

    function ask() {
        screenName = Hyprland.focusedMonitor?.name ?? "";
        open = true;
        card.forceActiveFocus();
    }

    // hyprshutdown은 앱들을 정리하며 닫은 뒤 Hyprland를 끝낸다 (없으면 바로 끝냄)
    function logout() {
        open = false;
        Quickshell.execDetached(["sh", "-c", "sleep 0.2; command -v hyprshutdown >/dev/null 2>&1 && exec hyprshutdown || exec hyprctl dispatch \"hl.dsp.exit()\""]);
    }

    screen: Quickshell.screens.find(s => s.name === screenName) ?? Quickshell.screens[0] ?? null
    visible: open || card.opacity > 0
    implicitWidth: card.width + shadowRoom * 2
    implicitHeight: card.height + shadowRoom * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: card }

    HyprlandFocusGrab {
        windows: [win]
        active: win.open
        onCleared: win.open = false
    }

    Item {
        id: card

        x: win.shadowRoom
        y: win.shadowRoom
        width: 340
        height: col.implicitHeight + 44
        opacity: win.open ? 1 : 0
        focus: true
        Keys.onEscapePressed: win.open = false
        Keys.onReturnPressed: win.logout()
        Keys.onEnterPressed: win.logout()

        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        transform: Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: win.open ? 1 : 0.96
            yScale: win.open ? 1 : 0.96
            Behavior on xScale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }

        RectangularShadow {
            anchors.fill: bg
            radius: bg.radius
            blur: 24
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

        ColumnLayout {
            id: col

            x: 22
            y: 22
            width: parent.width - 44
            spacing: 6

            Glyph {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 6
                text: Icons.power
                font.pixelSize: 30
                color: Theme.red
            }

            Txt {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "로그아웃할까요?"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Txt {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "열려 있는 앱을 모두 닫고 로그아웃합니다."
                font.pixelSize: 12
                color: Theme.subtext0
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 14
                spacing: 8

                DialogButton {
                    Layout.fillWidth: true
                    text: "취소"
                    onClicked: win.open = false
                }

                DialogButton {
                    Layout.fillWidth: true
                    text: "로그아웃"
                    primary: true
                    accent: Theme.red
                    onClicked: win.logout()
                }
            }
        }
    }
}
