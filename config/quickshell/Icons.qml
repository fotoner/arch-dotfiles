pragma Singleton
// Nerd Font 아이콘 글자 모음 (waybar 설정과 같은 아이콘을 쓴다)
import QtQuick
import Quickshell

Singleton {
    readonly property string wifiOff: "\u{f092e}"
    readonly property string wifiNone: "\u{f092f}"
    readonly property string bluetooth: "\u{f00af}"
    readonly property string bluetoothConnected: "\u{f00b1}"
    readonly property string bluetoothOff: "\u{f00b2}"
    readonly property string moon: "\u{f0594}"
    readonly property string mic: "\u{f036c}"
    readonly property string micOff: "\u{f036d}"
    readonly property string coffee: "\u{f0176}"
    readonly property string coffeeOff: "\u{f0faa}"
    readonly property string power: "\u{f0425}"
    readonly property string bell: "\u{f009a}"
    readonly property string brightness: "\u{f00df}"
    readonly property string play: "\u{f040a}"
    readonly property string pause: "\u{f03e4}"
    readonly property string next: "\u{f04ad}"
    readonly property string prev: "\u{f04ae}"
    readonly property string music: "\u{f075a}"
    readonly property string check: "\u{f012c}"
    readonly property string lock: "\u{f033e}"
    readonly property string speaker: "\u{f04c3}"
    readonly property string headphones: "\u{f02cb}"
    // 전원 모드: 저전력 · 균형 · 성능
    readonly property string leaf: ""
    readonly property string balance: ""
    readonly property string bolt: ""

    function wifi(strength) {
        return strength > 0.75 ? "\u{f0928}" : strength > 0.5 ? "\u{f0925}" : strength > 0.25 ? "\u{f0922}" : "\u{f091f}";
    }

    function volume(level, muted) {
        return muted ? "\u{f075f}" : level > 0.66 ? "\u{f057e}" : level > 0.33 ? "\u{f0580}" : "\u{f057f}";
    }

    function battery(fraction, charging) {
        if (charging)
            return "\u{f0084}";
        const icons = ["\u{f008e}", "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}", "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"];
        return icons[Math.max(0, Math.min(10, Math.round(fraction * 10)))];
    }

    // 블루투스 기기 종류(BlueZ 아이콘 이름) → 아이콘
    function device(name) {
        if (/headset|headphone/.test(name)) return "\u{f02cb}";
        if (/mouse/.test(name)) return "\u{f037d}";
        if (/keyboard/.test(name)) return "\u{f030c}";
        if (/phone/.test(name)) return "\u{f011c}";
        if (/audio|speaker/.test(name)) return "\u{f04c3}";
        if (/gaming|joystick/.test(name)) return "\u{f0296}";
        if (/computer/.test(name)) return "\u{f0379}";
        return "\u{f00af}";
    }
}
