pragma Singleton
// 단축키 시트(Super+H)에 보이는 목록: OS 기본 조작과 터미널만 (다른 앱의 단축키는 넣지 않는다). hyprland.lua의 단축키를 바꾸면 여기도 같이 고친다.
// keys: "Alt+C / V / X"처럼 쓴다. '+'로 나눈 것은 키캡 하나씩, ' / '는 다른 키(앞의 조합키를 그대로 씀)
import QtQuick
import Quickshell

Singleton {
    property bool open: false

    readonly property var groups: [
        {
            title: "맥처럼 (Alt = ⌘ Cmd)",
            icon: "\u{f0633}",
            items: [
                { keys: "Alt+키", desc: "앱에는 Ctrl+키로 (⌘ 단축키 전부)" },
                { keys: "Alt+C / V / X", desc: "복사 / 붙여넣기 / 잘라내기" },
                { keys: "Alt+Z / Shift+Z", desc: "실행 취소 / 다시 실행" },
                { keys: "Alt+S / F / A", desc: "저장 / 찾기 / 전체 선택" },
                { keys: "Alt+T / W / N", desc: "새 탭 / 탭 닫기 / 새 창" },
                { keys: "Alt+← / →", desc: "줄 처음 / 끝 (Shift: 선택)" },
                { keys: "Alt+↑ / ↓", desc: "문서 처음 / 끝 (Shift: 선택)" },
                { keys: "Alt+⌫", desc: "줄 처음까지 지우기" },
                { keys: "Ctrl+Alt+키", desc: "맥의 ⌘⌥+키" },
                { keys: "Alt+Q", desc: "창 닫기" },
                { keys: "Alt+Tab", desc: "다음 창 (Shift: 이전 창)" },
                { keys: "Alt+Space", desc: "Vicinae: 앱·계산기·이모지" },
                { keys: "Alt+Shift+V", desc: "클립보드 기록" }
            ]
        },
        {
            title: "스크린샷·녹화",
            icon: "\u{f0104}",
            items: [
                { keys: "Alt+Shift+3", desc: "전체 화면 저장" },
                { keys: "Alt+Shift+4", desc: "영역을 골라 편집 (Enter = 저장·복사)" },
                { keys: "Alt+Shift+5", desc: "화면 녹화 (다시 누르면 멈춤)" },
                { keys: "Print", desc: "영역을 클립보드로" },
                { keys: "Shift+Print", desc: "전체 화면을 ~/Pictures에" }
            ]
        },
        {
            title: "창",
            icon: "\u{f05b2}",
            items: [
                { keys: "Super+C", desc: "창 닫기" },
                { keys: "Super+V", desc: "띄우기 / 타일로 되돌리기" },
                { keys: "Super+←→↑↓", desc: "옆 창으로 이동" },
                { keys: "Super+Shift+←→↑↓", desc: "옆 창과 자리 바꾸기" },
                { keys: "Super+Ctrl+Shift+←→↑↓", desc: "창을 옆 모니터로" },
                { keys: "Super+J", desc: "나누는 방향 바꾸기" },
                { keys: "Super+왼쪽 끌기", desc: "창 옮기기" },
                { keys: "Super+오른쪽 끌기", desc: "창 크기 조절" }
            ]
        },
        {
            title: "워크스페이스",
            icon: "\u{f056e}",
            items: [
                { keys: "Super+1~0", desc: "그 워크스페이스로" },
                { keys: "Super+Shift+1~0", desc: "창을 그 워크스페이스로" },
                { keys: "Super+Alt+Shift+←→↑↓", desc: "통째로 옆 모니터로" },
                { keys: "Super+휠", desc: "옆 워크스페이스로" },
                { keys: "세 손가락 ←→", desc: "워크스페이스 넘기기" },
                { keys: "Super+S", desc: "숨김 공간 열기·닫기" },
                { keys: "Super+Shift+S", desc: "창을 숨김 공간으로" }
            ]
        },
        {
            title: "앱과 패널",
            icon: "\u{f003b}",
            items: [
                { keys: "Super+Q", desc: "터미널" },
                { keys: "Super+E", desc: "파일 관리자" },
                { keys: "Super+R", desc: "앱 검색" },
                { keys: "Super+A", desc: "제어 센터 (화면·소리·Wi-Fi)" },
                { keys: "Super+N", desc: "알림 목록" },
                { keys: "Super+H", desc: "이 단축키 시트" }
            ]
        },
        {
            title: "시스템",
            icon: "\u{f0493}",
            items: [
                { keys: "Ctrl+Space", desc: "입력기 A → 한 → あ" },
                { keys: "Super+L", desc: "화면 잠금" },
                { keys: "Super+Esc", desc: "전원 메뉴" },
                { keys: "Super+M", desc: "로그아웃" }
            ]
        },
        {
            title: "터미널 (kitty)",
            icon: "\u{f018d}",
            items: [
                { keys: "Alt+T", desc: "새 탭" },
                { keys: "Alt+W", desc: "탭 닫기" },
                { keys: "Alt+1~9", desc: "그 탭으로" },
                { keys: "Alt+Shift+[ / ]", desc: "이전 / 다음 탭" },
                { keys: "Ctrl+Tab", desc: "다음 탭 (Shift: 이전 탭)" },
                { keys: "Ctrl+Shift+, / .", desc: "탭을 왼쪽 / 오른쪽으로" },
                { keys: "Ctrl+Shift+Alt+T", desc: "탭 이름 바꾸기" },
                { keys: "Alt+C / V", desc: "복사 / 붙여넣기" },
                { keys: "Ctrl+C", desc: "실행 중단" },
                { keys: "Alt+= / - / 0", desc: "글자 크게 / 작게 / 원래대로" },
                { keys: "Ctrl+Shift+A → L / M", desc: "투명도 ↑ / ↓" }
            ]
        }
    ]
}
