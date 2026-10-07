pragma Singleton
// 제어 센터의 열림 상태와 펼친 목록. 다른 파일에서 CC.open, CC.section으로 쓴다
import QtQuick
import Quickshell

Singleton {
    id: cc

    property bool open: false
    // 펼친 목록: "wifi" | "bluetooth" | "sound" | ""
    property string section: ""

    function toggleSection(name) {
        section = section === name ? "" : name;
    }

    // 소리 출력 장치 이름: 짧은 별명(Speaker 등)을 한국어로, 없으면 긴 설명
    function sinkName(node) {
        if (!node)
            return "";
        const names = { "Speaker": "스피커", "Headphones": "헤드폰", "Headset": "헤드셋", "Line Out": "라인 출력" };
        return names[node.nickname] ?? (node.nickname || node.description || node.name);
    }

    // 셸 명령 실행 (~ 같은 셸 문법을 쓰려고 sh -c로)
    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // 패널을 닫고 나서 실행 (스크린샷처럼 패널이 찍히면 안 되는 것)
    function closeAndRun(cmd) {
        open = false;
        run("sleep 0.25; " + cmd);
    }
}
