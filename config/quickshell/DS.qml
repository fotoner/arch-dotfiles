pragma Singleton
// 디스플레이(모니터) 상태와 바꾸기. 설정 창(DisplaySettings), 제어 센터, 확인 팝업(DisplayOverlay)이 함께 쓴다.
// 읽기: hyprctl monitors all -j
// 바꾸기: hyprctl eval 'hl.monitor({...})'. 바로 적용되고, Hyprland를 다시 시작하면 사라진다
// 저장: ~/.config/hypr/monitors.json(이 창이 읽는 원본)과 monitors.lua(hyprland.lua가 require로 읽음).
//       모니터를 연결 이름(HDMI-A-2)이 아니라 desc(제조사·모델·일련번호)로 기억해서, 어느 포트에 꽂아도 같은 설정이 된다
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: ds

    property bool open: false // 설정 창
    property string selected: "" // 설정 창에서 고른 모니터 (연결 이름)
    // [{ name, desc, label, internal, enabled, mirror, w, h, refresh, mode, x, y, scale, transform, modes: [{ w, h, r, str }] }]
    property var monitors: []
    property var saved: ({}) // desc → { mode, x, y, scale, transform, mirror }
    property var pending: null // 확인을 기다리는 변경 { prev, next, persist }
    property int countdown: 0

    readonly property int confirmSeconds: 15
    readonly property string dir: Quickshell.env("HOME") + "/.config/hypr"
    readonly property var internal: monitors.find(m => m.internal) ?? null
    readonly property var externals: monitors.filter(m => !m.internal)
    readonly property var current: monitors.find(m => m.name === selected) ?? null

    // 지금 화면 구성: "extend" 확장 | "mirror" 미러링 | "external" 외부 모니터만 | "internal" 노트북만 | "" 화면 하나
    readonly property string topology: {
        if (monitors.length < 2)
            return "";
        if (monitors.some(m => m.enabled && m.mirror))
            return "mirror";
        if (internal && !internal.enabled)
            return "external";
        if (internal && externals.every(m => !m.enabled))
            return "internal";
        return "extend";
    }
    readonly property var topologyNames: ({ extend: "확장", mirror: "미러링", external: "외부 모니터만", internal: "노트북만" })

    // ---- 읽기 ----

    function refresh() {
        if (!reader.running)
            reader.running = true;
        else
            refreshTimer.restart();
    }

    function parse(text) {
        let list;
        try {
            list = JSON.parse(text);
        } catch (e) {
            return;
        }
        const byId = {};
        for (const m of list)
            byId[m.id] = m.name;
        const result = list.map(m => {
            const internal = /^(eDP|LVDS|DSI)-/.test(m.name);
            const modes = parseModes(m.availableModes ?? []);
            // 꺼진 모니터는 크기가 0으로 올 수 있어서 첫 번째(기본) 모드로 채운다
            const w = m.width || modes[0]?.w || 1920;
            const h = m.height || modes[0]?.h || 1080;
            const refresh = m.refreshRate || modes[0]?.r || 60;
            const found = modes.find(x => x.w === w && x.h === h && Math.abs(x.r - refresh) < 0.01);
            let mirror = m.mirrorOf && m.mirrorOf !== "none" ? String(m.mirrorOf) : "";
            if (/^\d+$/.test(mirror))
                mirror = byId[mirror] ?? mirror;
            return {
                name: m.name,
                desc: m.description || m.name,
                label: internal ? "내장 디스플레이" : (m.model || m.description || m.name),
                internal: internal,
                enabled: !m.disabled,
                mirror: mirror,
                w: w,
                h: h,
                refresh: refresh,
                mode: found ? found.str : w + "x" + h + "@" + refresh.toFixed(2),
                x: m.x,
                y: m.y,
                scale: m.scale || 1,
                transform: m.transform || 0,
                modes: modes
            };
        });
        // 내장 화면 먼저, 나머지는 왼쪽부터
        result.sort((a, b) => (b.internal - a.internal) || (a.x - b.x) || a.name.localeCompare(b.name));
        monitors = result;
        if (!result.some(m => m.name === selected))
            selected = (result.find(m => !m.internal && m.enabled) ?? result[0])?.name ?? "";
        guard();
    }

    // "1920x1080@60.00Hz" → { w, h, r, str: "1920x1080@60.00" }
    function parseModes(list) {
        const seen = {};
        const out = [];
        for (const s of list) {
            const g = /^(\d+)x(\d+)@([\d.]+)/.exec(s);
            if (!g || seen[g[0]])
                continue;
            seen[g[0]] = true;
            out.push({ w: Number(g[1]), h: Number(g[2]), r: Number(g[3]), str: g[0] });
        }
        return out;
    }

    // 안전장치: 켜진 화면이 하나도 없으면(외부 모니터만 쓰다가 케이블을 뽑았을 때 등) 내장 화면을 다시 켠다
    function guard() {
        if (monitors.length === 0 || monitors.some(m => m.enabled && !m.mirror))
            return;
        const m = internal ?? monitors[0];
        run(rule(spec(Object.assign({}, m, { enabled: true, mirror: "", x: 0, y: 0 }))));
    }

    // ---- 계산 ----

    // 화면 배치에 쓰는 크기 (배율·회전 반영)
    function logical(m) {
        const turned = m.transform % 2 === 1;
        return {
            w: Math.round((turned ? m.h : m.w) / m.scale),
            h: Math.round((turned ? m.w : m.h) / m.scale)
        };
    }

    // 해상도를 나눴을 때 정수가 되는 배율만 (Hyprland가 안 맞는 배율은 멋대로 고친다)
    function scalesFor(m) {
        return [1, 1.25, 1.5, 2].filter(s => {
            const a = m.w / s, b = m.h / s;
            return Math.abs(a - Math.round(a)) < 0.01 && Math.abs(b - Math.round(b)) < 0.01;
        });
    }

    function resolutions(m) {
        const out = [];
        for (const x of m.modes)
            if (!out.some(o => o.w === x.w && o.h === x.h))
                out.push({ w: x.w, h: x.h });
        return out;
    }

    function overlaps(a, b) {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    }

    // ---- Hyprland 규칙 ----

    function spec(m) {
        return { output: m.name, enabled: m.enabled, mode: m.mode, x: m.x, y: m.y, scale: m.scale, transform: m.transform, mirror: m.mirror };
    }

    function rule(s) {
        const out = "output = " + JSON.stringify(s.output);
        if (!s.enabled)
            return "hl.monitor({ " + out + ", disabled = true })";
        const parts = [out, "mode = " + JSON.stringify(s.mode), "position = \"" + Math.round(s.x) + "x" + Math.round(s.y) + "\"", "scale = " + s.scale, "transform = " + s.transform];
        if (s.mirror)
            parts.push("mirror = " + JSON.stringify(s.mirror));
        return "hl.monitor({ " + parts.join(", ") + " })";
    }

    // ---- 바꾸기 ----

    // next: 모든 모니터의 새 상태. confirm: 15초 안에 '유지'를 안 누르면 되돌림. persist: 저장
    function apply(next, confirm, persist) {
        if (pending)
            return;
        const prev = monitors;
        run(next.map(m => rule(spec(m))).join("\n"));
        monitors = next; // 화면이 바로 바뀌어 보이게. 실제 상태는 곧 다시 읽는다
        if (confirm) {
            pending = { prev: prev, next: next, persist: persist };
            countdown = confirmSeconds;
            confirmTimer.restart();
        } else if (persist) {
            save(next);
        }
    }

    function keep() {
        if (!pending)
            return;
        const p = pending;
        pending = null;
        confirmTimer.stop();
        if (p.persist)
            save(p.next);
    }

    function revert() {
        if (!pending)
            return;
        const p = pending;
        pending = null;
        confirmTimer.stop();
        run(p.prev.map(m => rule(spec(m))).join("\n"));
        monitors = p.prev;
    }

    // 화면 배치 끌어 놓기: positions = [{ name, x, y }]
    function arrange(positions) {
        apply(monitors.map(m => {
            const p = positions.find(q => q.name === m.name);
            return p ? Object.assign({}, m, { x: p.x, y: p.y }) : m;
        }), false, true);
    }

    // 해상도·주사율·배율·회전. 크기가 바뀌면 오른쪽·아래에 붙어 있던 화면을 그만큼 밀거나 당긴다
    function change(name, patch) {
        const cur = monitors.find(m => m.name === name);
        if (!cur)
            return;
        const upd = Object.assign({}, cur, patch);
        if (!scalesFor(upd).includes(upd.scale))
            upd.scale = 1;
        const before = logical(cur), after = logical(upd);
        const dw = after.w - before.w, dh = after.h - before.h;
        apply(monitors.map(m => {
            if (m.name === name)
                return upd;
            if (!m.enabled || m.mirror)
                return m;
            const o = Object.assign({}, m);
            if (m.x >= cur.x + before.w)
                o.x += dw;
            if (m.y >= cur.y + before.h)
                o.y += dh;
            return o;
        }), true, true);
    }

    function setResolution(name, w, h) {
        const m = monitors.find(x => x.name === name);
        const options = m.modes.filter(x => x.w === w && x.h === h);
        const same = options.find(x => Math.abs(x.r - m.refresh) < 0.01);
        const best = same ?? options.reduce((a, b) => b.r > a.r ? b : a);
        change(name, { w: w, h: h, refresh: best.r, mode: best.str });
    }

    function setRefresh(name, mode) {
        change(name, { refresh: mode.r, mode: mode.str });
    }

    // 확장 · 미러링 · 외부 모니터만 · 노트북만
    function setTopology(kind) {
        if (monitors.length < 2 || kind === topology)
            return;
        const on = m => Object.assign({}, m, { enabled: true, mirror: "" });
        const source = internal ?? monitors[0];
        let next;
        if (kind === "extend") {
            next = extendLayout();
        } else if (kind === "mirror") {
            next = monitors.map(m => m.name === source.name ? on(m) : Object.assign(on(m), { mirror: source.name }));
        } else if (kind === "external") {
            let x = 0;
            next = monitors.map(m => {
                if (m.internal)
                    return Object.assign({}, m, { enabled: false, mirror: "" });
                const o = Object.assign(on(m), { x: x, y: 0 });
                x += logical(o).w;
                return o;
            });
        } else {
            next = monitors.map(m => m.internal ? Object.assign(on(m), { x: 0, y: 0 }) : Object.assign({}, m, { enabled: false, mirror: "" }));
        }
        // 끄는 구성은 지금만 쓰고 저장하지 않는다 (다음에 꽂거나 재시작하면 확장/미러링으로 돌아옴).
        // 외부 모니터만은 그 모니터가 안 나오면 화면이 다 꺼지므로 확인을 받는다
        apply(next, kind === "external", kind === "extend" || kind === "mirror");
    }

    // 확장: 저장된 위치가 있으면 그대로, 없거나 겹치면 내장 화면 오른쪽으로 나란히
    function extendLayout() {
        const next = monitors.map(m => {
            const o = Object.assign({}, m, { enabled: true, mirror: "" });
            const s = saved[m.desc];
            if (s) {
                const mode = m.modes.find(x => x.str === s.mode);
                if (mode)
                    Object.assign(o, { w: mode.w, h: mode.h, refresh: mode.r, mode: mode.str });
                Object.assign(o, { x: s.x, y: s.y, scale: s.scale, transform: s.transform });
            }
            return o;
        });
        const rects = next.map(m => Object.assign({ x: m.x, y: m.y }, logical(m)));
        const clash = rects.some((a, i) => rects.some((b, j) => i < j && overlaps(a, b)));
        if (clash || next.some(m => !saved[m.desc])) {
            let x = 0;
            for (const m of next) {
                m.x = x;
                m.y = 0;
                x += logical(m).w;
            }
        }
        return next;
    }

    // ---- 덮개 (맥 클램쉘 모드) ----
    // 외부 모니터가 켜져 있을 때 덮개를 닫으면 노트북 화면만 끄고, 열면 닫기 전 구성으로 되돌린다 (저장하지 않음).
    // Hyprland가 덮개 스위치에서 qs ipc call display lid close|open을 부른다
    property var lidSnapshot: null

    function lidClose() {
        const int = internal;
        if (!int || !int.enabled || pending || !externals.some(m => m.enabled))
            return; // 외부 모니터가 없으면 logind가 잠그고 절전한다
        lidSnapshot = monitors;
        const wasMirror = topology === "mirror";
        let x = 0;
        apply(monitors.map(m => {
            if (m.internal)
                return Object.assign({}, m, { enabled: false, mirror: "" });
            if (!m.enabled)
                return m;
            const o = Object.assign({}, m, { mirror: "" });
            if (wasMirror) { // 미러링의 원본(노트북 화면)이 꺼지므로 외부 모니터를 나란히 세운다
                o.x = x;
                o.y = 0;
                x += logical(o).w;
            }
            return o;
        }), false, false);
    }

    function lidOpen() {
        const snap = lidSnapshot;
        lidSnapshot = null;
        if (!snap || !internal || internal.enabled || pending)
            return; // 덮개 때문에 끈 게 아니면(직접 '외부만'을 고른 경우 등) 그대로 둔다
        // 닫은 사이에 모니터가 빠졌으면 남은 것만 되돌린다 (빠진 모니터 규칙은 Hyprland가 무시)
        apply(monitors.map(m => snap.find(s => s.name === m.name) ?? m), false, false);
    }

    // ---- 저장 ----

    function save(states) {
        const map = Object.assign({}, saved);
        // 꺼진 화면이나 미러링이 있는 구성의 위치는 확장 배치가 아니므로 위치만 예전 값을 둔다
        const keepPosition = states.some(m => !m.enabled || m.mirror);
        for (const m of states) {
            if (!m.enabled)
                continue;
            const old = map[m.desc];
            map[m.desc] = {
                mode: m.mode,
                x: keepPosition && old ? old.x : Math.round(m.x),
                y: keepPosition && old ? old.y : Math.round(m.y),
                scale: m.scale,
                transform: m.transform,
                mirror: m.mirror
            };
        }
        saved = map;
        const lua = ["-- 디스플레이 설정(제어 센터 → 디스플레이)이 저장하는 파일. 저장할 때마다 덮어쓰니 고치려면 설정 창을 쓴다", "-- 모니터마다(제조사·모델·일련번호) 해상도, 위치, 배율, 회전, 미러링을 기억한다. 원본은 monitors.json", ""];
        for (const desc of Object.keys(map).sort())
            lua.push(rule(Object.assign({ output: "desc:" + desc, enabled: true }, map[desc])));
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" > \"$3.tmp\" && mv \"$3.tmp\" \"$3\" && printf '%s\\n' \"$2\" > \"$4.tmp\" && mv \"$4.tmp\" \"$4\"", "sh", JSON.stringify(map, null, 2), lua.join("\n"), dir + "/monitors.json", dir + "/monitors.lua"]);
    }

    // ---- 실행 ----

    property var queue: []

    function run(lua) {
        queue = queue.concat([lua]);
        pump();
    }

    function pump() {
        if (applier.running || queue.length === 0)
            return;
        applier.command = ["hyprctl", "eval", queue[0]];
        queue = queue.slice(1);
        applier.running = true;
    }

    Process {
        id: applier
        onExited: {
            ds.pump();
            refreshTimer.restart();
        }
    }

    Process {
        id: reader
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: ds.parse(text)
        }
    }

    // 모드를 바꾸면 Hyprland가 적용을 마칠 때까지 조금 걸린다
    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: ds.refresh()
    }

    Timer {
        id: confirmTimer
        interval: 1000
        repeat: true
        onTriggered: {
            ds.countdown -= 1;
            if (ds.countdown <= 0)
                ds.revert();
        }
    }

    FileView {
        path: ds.dir + "/monitors.json"
        printErrors: false // 아직 저장한 적이 없으면 파일이 없다
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                ds.saved = JSON.parse(text()) ?? {};
            } catch (e) {}
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (/^(monitoradded|monitorremoved|configreloaded)/.test(event.name))
                refreshTimer.restart();
        }
    }

    onOpenChanged: if (open) refresh()
    Component.onCompleted: refresh()
}
