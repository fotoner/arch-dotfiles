pragma ComponentBehavior: Bound
// 화면 배치: 모니터를 줄여 그린 네모를 끌어서 옮긴다 (맥 디스플레이 배치처럼).
// 놓으면 가장 가까운 다른 화면 가장자리에 붙이고, 가까우면 위·아래·가운데 줄을 맞춘다. 누르면 그 모니터를 고른다
import QtQuick

Item {
    id: arr

    readonly property var mons: DS.monitors.filter(m => m.enabled && !m.mirror)
    property var frozen: null // 끄는 동안에는 축척과 위치를 고정한다
    readonly property var layout: frozen ?? compute(mons, width, height)
    readonly property real minOverlap: 80 // 붙은 두 화면이 최소한 이만큼은 맞닿게 (논리 픽셀)

    function compute(list, W, H) {
        const rects = list.map(m => Object.assign({ name: m.name, x: m.x, y: m.y }, DS.logical(m)));
        if (rects.length === 0 || W <= 0 || H <= 0)
            return { s: 1, ox: 0, oy: 0, minX: 0, minY: 0, rects: [] };
        const minX = Math.min(...rects.map(r => r.x)), minY = Math.min(...rects.map(r => r.y));
        const bw = Math.max(...rects.map(r => r.x + r.w)) - minX, bh = Math.max(...rects.map(r => r.y + r.h)) - minY;
        const pad = 28;
        const s = Math.min((W - pad * 2) / bw, (H - pad * 2) / bh, 0.12);
        return { s: s, ox: (W - bw * s) / 2, oy: (H - bh * s) / 2, minX: minX, minY: minY, rects: rects };
    }

    // 붙는 방향과 수직인 축: 맞닿은 채로 두고, 가까우면 시작·끝·가운데를 맞춘다
    function align(pos, size, bpos, bsize, tol) {
        const ov = Math.min(minOverlap, size, bsize);
        let p = Math.max(bpos - size + ov, Math.min(bpos + bsize - ov, pos));
        for (const t of [bpos, bpos + bsize - size, bpos + (bsize - size) / 2])
            if (Math.abs(p - t) < tol)
                return t;
        return p;
    }

    function snap(d, others, tol) {
        let best = null;
        for (const b of others) {
            const ay = align(d.y, d.h, b.y, b.h, tol), ax = align(d.x, d.w, b.x, b.w, tol);
            for (const c of [{ x: b.x + b.w, y: ay }, { x: b.x - d.w, y: ay }, { x: ax, y: b.y + b.h }, { x: ax, y: b.y - d.h }]) {
                const r = { x: c.x, y: c.y, w: d.w, h: d.h };
                if (others.some(o => DS.overlaps(r, o)))
                    continue;
                const dist = Math.hypot(c.x - d.x, c.y - d.y);
                if (!best || dist < best.dist)
                    best = { x: c.x, y: c.y, dist: dist };
            }
        }
        return best ?? d;
    }

    // 끌어 놓은 네모의 캔버스 위치 → 논리 좌표로 바꿔 붙이고, 전체를 (0, 0)부터 시작하게 맞춘다
    function drop(name, px, py) {
        const L = frozen;
        const me = L.rects.find(r => r.name === name);
        const others = L.rects.filter(r => r.name !== name);
        const want = { x: (px - L.ox) / L.s + L.minX, y: (py - L.oy) / L.s + L.minY, w: me.w, h: me.h };
        const at = snap(want, others, 14 / L.s);
        const all = others.concat([Object.assign({}, me, { x: at.x, y: at.y })]);
        const nx = Math.min(...all.map(r => r.x)), ny = Math.min(...all.map(r => r.y));
        DS.arrange(all.map(r => ({ name: r.name, x: Math.round(r.x - nx), y: Math.round(r.y - ny) })));
    }

    Repeater {
        model: arr.mons

        delegate: Rectangle {
            id: box

            required property var modelData
            readonly property var r: arr.layout.rects.find(q => q.name === modelData.name) ?? { x: 0, y: 0, w: 0, h: 0 }
            readonly property bool chosen: DS.selected === modelData.name
            property real dx: 0
            property real dy: 0
            property bool dragging: false

            x: arr.layout.ox + (r.x - arr.layout.minX) * arr.layout.s + dx
            y: arr.layout.oy + (r.y - arr.layout.minY) * arr.layout.s + dy
            width: r.w * arr.layout.s
            height: r.h * arr.layout.s
            z: dragging ? 2 : chosen ? 1 : 0
            radius: 8
            color: chosen ? Qt.alpha(Theme.mauve, 0.22) : Theme.surface0
            border.width: chosen ? 2 : 1
            border.color: chosen ? Theme.mauve : Theme.surface2
            opacity: dragging ? 0.85 : 1

            Behavior on x { enabled: !box.dragging; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: !box.dragging; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150 } }

            // 위쪽 얇은 막대: 상단바 자리
            Rectangle {
                x: 6
                y: 6
                width: parent.width - 12
                height: 3
                radius: 1.5
                color: box.chosen ? Theme.mauve : Theme.surface2
                opacity: 0.8
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - 16
                spacing: 2

                Txt {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: box.modelData.label
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: box.chosen ? Theme.text : Theme.subtext1
                }

                Txt {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: box.r.w + " × " + box.r.h
                    font.pixelSize: 10
                    color: Theme.overlay1
                }
            }

            MouseArea {
                id: area

                property point start
                property bool moved: false

                anchors.fill: parent
                enabled: !DS.pending
                hoverEnabled: true
                cursorShape: box.dragging ? Qt.ClosedHandCursor : arr.mons.length > 1 ? Qt.OpenHandCursor : Qt.PointingHandCursor

                onPressed: mouse => {
                    start = mapToItem(arr, mouse.x, mouse.y);
                    moved = false;
                    DS.selected = box.modelData.name;
                }
                onPositionChanged: mouse => {
                    if (!pressed || arr.mons.length < 2)
                        return;
                    const p = mapToItem(arr, mouse.x, mouse.y);
                    if (!moved && Math.hypot(p.x - start.x, p.y - start.y) < 4)
                        return;
                    if (!moved) {
                        moved = true;
                        arr.frozen = arr.layout;
                        box.dragging = true;
                    }
                    const baseX = arr.layout.ox + (box.r.x - arr.layout.minX) * arr.layout.s;
                    const baseY = arr.layout.oy + (box.r.y - arr.layout.minY) * arr.layout.s;
                    box.dx = Math.max(-baseX, Math.min(arr.width - box.width - baseX, p.x - start.x));
                    box.dy = Math.max(-baseY, Math.min(arr.height - box.height - baseY, p.y - start.y));
                }
                onReleased: {
                    if (!moved)
                        return;
                    arr.drop(box.modelData.name, box.x, box.y);
                    box.dragging = false;
                    box.dx = 0;
                    box.dy = 0;
                    arr.frozen = null;
                }
            }
        }
    }
}
