//@ pragma IconTheme Papirus-Dark
// Quickshell: 맥 제어 센터 같은 빠른 설정 패널.
// 열기: 상단바 제어 센터 아이콘, Super+A, qs ipc call cc toggle
// 알림 목록은 그대로 swaync가 맡는다 (상단바 시계, Super+N)
// 디스플레이 설정 창: 제어 센터 → 디스플레이, qs ipc call display open
// 단축키 시트: Super+H, qs ipc call keys toggle
// 앱 아이콘은 GTK 앱들과 같은 Papirus-Dark 테마에서 찾는다 (맨 윗줄 pragma. 없으면 hicolor만 봐서 아이콘이 비거나 기본 아이콘이 나옴)
// 전원 모드: qs ipc call power cycle|set <모드>|get
// 화면 녹화 도구 막대: Alt+Shift+5 (screenrecord.sh toggle), qs ipc call record open
// 앱 전환기 (맥 ⌘Tab): Alt+Tab, qs ipc call switcher next|prev
// 로그아웃 확인 창 (맥 ⌘⇧Q): Alt+Shift+Q, Super+M, qs ipc call session logout
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    ControlCenter {}
    DisplaySettings {}
    DisplayOverlay {}
    ShortcutSheet {}

    RecordBar {
        id: recordBar
    }

    AppSwitcher {
        id: appSwitcher
    }

    SessionDialog {
        id: sessionDialog
    }

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
        target: "session"

        // qs ipc call session logout|close : 로그아웃 확인 창
        function logout(): void {
            CC.open = false;
            sessionDialog.ask();
        }

        function close(): void {
            sessionDialog.open = false;
        }
    }

    IpcHandler {
        target: "switcher"

        // qs ipc call switcher next|prev|release|cancel : Hyprland의 Alt+Tab, Alt+Shift+Tab, 전환 중 Alt 떼기
        function next(): void {
            appSwitcher.next();
        }

        function prev(): void {
            appSwitcher.prev();
        }

        function release(): void {
            appSwitcher.release();
        }

        function cancel(): void {
            appSwitcher.reset();
        }
    }

    IpcHandler {
        target: "record"

        // qs ipc call record open|close
        function open(): void {
            CC.open = false;
            recordBar.show();
        }

        function close(): void {
            recordBar.open = false;
        }
    }

    IpcHandler {
        target: "power"

        // qs ipc call power cycle : 균형 → 빠른 균형 → 성능 → 저전력 (상단바 전원 아이콘 클릭)
        function cycle(): void {
            Power.cycle();
        }

        // qs ipc call power set power-saver|balanced|fast|performance
        function set(mode: string): void {
            Power.set(mode);
        }

        function get(): string {
            return Power.mode;
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

        // qs ipc call display lid close|open : 덮개 스위치 (hyprland.lua)
        function lid(state: string): void {
            if (state === "close")
                DS.lidClose();
            else
                DS.lidOpen();
        }
    }
}
