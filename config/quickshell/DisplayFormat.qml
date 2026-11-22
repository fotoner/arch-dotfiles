pragma Singleton
// 디스플레이 값 글자로 쓰기
import QtQuick
import Quickshell

Singleton {
    // 60.049 → "60Hz", 59.94 → "59.94Hz"
    function hz(r) {
        return (Math.abs(r - Math.round(r)) < 0.06 ? Math.round(r) : r.toFixed(2)) + "Hz";
    }

    // 모니터가 가장 먼저 알려 주는 해상도가 그 모니터의 기본(권장) 해상도
    function res(w, h, mon) {
        const first = mon?.modes?.[0];
        return w + " × " + h + (first && first.w === w && first.h === h ? "  (기본)" : "");
    }
}
