pragma Singleton
// Catppuccin Mocha 색과 글꼴 (waybar/mocha.css와 같은 값)
import QtQuick
import Quickshell

Singleton {
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color overlay0: "#6c7086"
    readonly property color overlay1: "#7f849c"
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"
    readonly property color text: "#cdd6f4"
    readonly property color mauve: "#cba6f7"
    readonly property color blue: "#89b4fa"
    readonly property color teal: "#94e2d5"
    readonly property color green: "#a6e3a1"
    readonly property color yellow: "#f9e2af"
    readonly property color peach: "#fab387"
    readonly property color red: "#f38ba8"

    // 카드·버튼 바탕: 패널 위에 흰색을 살짝 덮는다
    readonly property color fill: Qt.rgba(1, 1, 1, 0.06)
    readonly property color fillHover: Qt.rgba(1, 1, 1, 0.10)
    readonly property color line: Qt.rgba(1, 1, 1, 0.05)

    readonly property string font: "Inter"
    // Propo: 아이콘 폭이 그림 폭과 같다. 그냥 "Nerd Font"는 폭을 한 글자 칸으로 잡아서 가운데 정렬해도 그림이 오른쪽으로 밀린다
    readonly property string iconFont: "JetBrainsMono Nerd Font Propo"
}
