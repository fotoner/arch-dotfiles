// Quickshell: 맥 제어 센터 같은 빠른 설정 패널.
// 열기: 상단바 제어 센터 아이콘, Super+A, qs ipc call cc toggle
// 알림 목록은 그대로 swaync가 맡는다 (상단바 시계, Super+N)
// 디스플레이 설정 창: 제어 센터 → 디스플레이, qs ipc call display open
// 단축키 시트: Super+H, qs ipc call keys toggle
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    ControlCenter {}
    DisplaySettings {}
    DisplayOverlay {}
    ShortcutSheet {}

    IpcHandler {
        target: "cc"

        // qs ipc call cc toggle
        function toggle(): void {
            if (CC.open) {
                CC.open = false;
            } else {
                CC.section = "";
                CC.open = true;
            }
        }

        // qs ipc call cc open wifi|bluetooth|sound : 그 목록을 펼친 채로 연다 (이미 그렇게 열려 있으면 닫는다)
        function open(section: string): void {
            if (CC.open && CC.section === section) {
                CC.open = false;
            } else {
                CC.section = section;
                CC.open = true;
            }
        }

        function hide(): void {
            CC.open = false;
        }
    }

    IpcHandler {
        target: "keys"

        // qs ipc call keys toggle|open|close
        function toggle(): void {
            if (Shortcuts.open) {
                Shortcuts.open = false;
            } else {
                CC.open = false;
                DS.open = false;
                Shortcuts.open = true;
            }
        }

        function open(): void {
            CC.open = false;
            DS.open = false;
            Shortcuts.open = true;
        }

        function close(): void {
            Shortcuts.open = false;
        }
    }

    IpcHandler {
        target: "display"

        // qs ipc call display open|toggle|close
        function open(): void {
            CC.open = false;
            DS.open = true;
        }

        function toggle(): void {
            if (DS.open) {
                DS.open = false;
            } else {
                CC.open = false;
                DS.open = true;
            }
        }

        function close(): void {
            DS.open = false;
        }

        // qs ipc call display topology extend|mirror|external|internal
        function topology(kind: string): void {
            DS.setTopology(kind);
        }
    }
}
