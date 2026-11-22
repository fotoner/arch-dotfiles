//! 상단바(waybar) 상태 표시: 재생 중인 미디어와 입력기 배지. Waybar custom 모듈이 실행하고, 한 줄(JSON)씩 출력한다.
//!
//! 예전 셸 스크립트(media-status.sh, ime-status.sh)는 0.25~0.4초마다 playerctl·pgrep·fcitx5-remote를 새로 실행해서
//! 상단바 두 개(모니터마다 하나)가 초당 25개쯤 프로세스를 만들었다. 이 프로그램은 D-Bus에 한 번만 붙는다.
//! - 미디어: 재생기(MPRIS)가 보내는 변경 알림을 받을 때만 다시 읽는다. 재생 중일 때만 1초마다 재생 위치를 묻고,
//!   긴 제목이 흐를 때만 0.25초마다 다시 그린다. 일시정지 10초 뒤 숨김도 타이머로 처리한다.
//! - 입력기: fcitx5는 입력기가 바뀌어도 알림을 보내지 않아서 1초마다 D-Bus로 묻는다(프로세스를 띄우지 않음).
//!   Ctrl+Space(ime-cycle.sh)로 바꾸면 SIGUSR1을 보내 바로 갱신한다.
//! 상단바가 꺼지면(부모 프로세스가 죽으면) 같이 끝난다.
//!
//!   bar-status media           󰝚 제목 · 아티스트  0:42 / 3:15   (긴 제목은 전광판처럼 흐름)
//!   bar-status ime             A / 한 / あ
//!   bar-status marquee <글자>   긴 제목이 흐르는 모양을 6프레임 출력 (시험용)

use std::collections::HashMap;
use std::io::Write;
use std::sync::mpsc::{self, RecvTimeoutError, Sender};
use std::thread;
use std::time::{Duration, Instant};

use zbus::blocking::fdo::DBusProxy;
use zbus::blocking::{Connection, MessageIterator, Proxy};
use zbus::zvariant::{OwnedValue, Value};
use zbus::{MatchRule, message};

const HIDE_AFTER: Duration = Duration::from_secs(10); // 일시정지 뒤 숨기기까지
const WIDTH: usize = 36; // 제목·아티스트 부분에 보이는 글자 수
const HOLD: u32 = 8; // 처음과 한 바퀴 돈 뒤 멈춰 있는 프레임 수 (8 × 0.25초 = 2초)
const FRAME: Duration = Duration::from_millis(250); // 긴 제목이 한 칸 흐르는 간격
const POSITION_EVERY: Duration = Duration::from_secs(1); // 재생 중 재생 위치를 다시 묻는 간격
const IME_EVERY: Duration = Duration::from_secs(1);

const MPRIS_PREFIX: &str = "org.mpris.MediaPlayer2.";
const MPRIS_PATH: &str = "/org/mpris/MediaPlayer2";
const MPRIS_PLAYER: &str = "org.mpris.MediaPlayer2.Player";
const HIDDEN: &str = r#"{"text":"","class":"hidden"}"#;
const TIP_HELP: &str = "클릭: 재생 중인 앱으로 이동 · 오른쪽 클릭: 재생/일시정지 · 가운데 클릭: 다음 곡";

type Res<T> = Result<T, Box<dyn std::error::Error>>;

fn main() {
    // 상단바(부모)가 죽으면 같이 끝난다. 상단바를 다시 읽을 때 옛 프로세스가 남지 않게
    unsafe {
        libc::prctl(libc::PR_SET_PDEATHSIG, libc::SIGTERM);
    }
    let args: Vec<String> = std::env::args().collect();
    let result = match args.get(1).map(String::as_str) {
        Some("media") => media(),
        Some("ime") => ime(),
        Some("marquee") => {
            demo_marquee(args.get(2).map(String::as_str).unwrap_or(""));
            Ok(())
        }
        _ => {
            eprintln!("사용법: bar-status media | ime | marquee <글자>");
            std::process::exit(2);
        }
    };
    if let Err(e) = result {
        eprintln!("bar-status: {e}");
        std::process::exit(1);
    }
}

// ---------- 공통 ----------

/// 바뀐 줄만 출력한다. 상단바가 파이프를 닫으면 끝낸다
struct Out {
    last: String,
}

impl Out {
    fn emit(&mut self, line: &str) {
        if line == self.last {
            return;
        }
        let mut stdout = std::io::stdout().lock();
        if writeln!(stdout, "{line}").and_then(|_| stdout.flush()).is_err() {
            std::process::exit(0);
        }
        self.last = line.to_string();
    }
}

fn json_escape(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '\\' => out.push_str("\\\\"),
            '"' => out.push_str("\\\""),
            '\n' => out.push_str("\\n"),
            '\t' => out.push(' '),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out
}

/// 이 D-Bus 신호가 오면 tx로 알린다 (받는 쪽에서 다시 읽는다)
fn watch(conn: &Connection, rule: MatchRule<'static>, tx: Sender<()>) -> Res<()> {
    let messages = MessageIterator::for_match_rule(rule, conn, Some(64))?;
    thread::spawn(move || {
        for msg in messages {
            if msg.is_ok() && tx.send(()).is_err() {
                break;
            }
        }
    });
    Ok(())
}

/// SIGUSR1이 오면 tx로 알린다 (입력기를 바꾼 쪽에서 바로 갱신해 달라고 보낸다)
fn watch_usr1(tx: Sender<()>) -> Res<()> {
    let mut signals = signal_hook::iterator::Signals::new([signal_hook::consts::SIGUSR1])?;
    thread::spawn(move || {
        for _ in signals.forever() {
            if tx.send(()).is_err() {
                break;
            }
        }
    });
    Ok(())
}

fn signal_rule(interface: &'static str, member: &'static str) -> Res<zbus::match_rule::Builder<'static>> {
    Ok(MatchRule::builder().msg_type(message::Type::Signal).interface(interface)?.member(member)?)
}

// ---------- 미디어 ----------

#[derive(Default, Clone, PartialEq)]
struct Track {
    title: String,
    artist: String,
    length_us: i64,
}

struct Media {
    conn: Connection,
    player: String, // 버스 이름에서 org.mpris.MediaPlayer2.을 뺀 것 (playerctl과 같은 이름)
    status: String, // Playing | Paused | ""
    prev_player: String,
    prev_status: String,
    paused_since: Option<Instant>,
    track: Track,
    position_s: i64,
    key: String, // 곡이 바뀌었는지 (player|label)
    offset: usize,
    hold: u32,
    state_file: String,
    written_player: String,
}

impl Media {
    fn proxy(&self, player: &str) -> Res<Proxy<'static>> {
        Ok(zbus::blocking::proxy::Builder::new(&self.conn)
            .destination(format!("{MPRIS_PREFIX}{player}"))?
            .path(MPRIS_PATH)?
            .interface(MPRIS_PLAYER)?
            .cache_properties(zbus::proxy::CacheProperties::No)
            .build()?)
    }

    /// 플레이어들을 다시 훑는다: 재생 중인 첫 플레이어, 없으면 일시정지된 첫 플레이어
    fn scan(&mut self, now: Instant) {
        let mut player = String::new();
        let mut status = String::new();
        let names = DBusProxy::new(&self.conn).ok().and_then(|d| d.list_names().ok()).unwrap_or_default();
        for name in names.iter().filter_map(|n| n.as_str().strip_prefix(MPRIS_PREFIX)) {
            let s: String = match self.proxy(name).and_then(|p| Ok(p.get_property("PlaybackStatus")?)) {
                Ok(s) => s,
                Err(_) => continue,
            };
            if s == "Playing" {
                player = name.to_string();
                status = s;
                break;
            }
            if s == "Paused" && player.is_empty() {
                player = name.to_string();
                status = s;
            }
        }

        if status == "Paused" {
            if player == self.prev_player && self.prev_status == "Playing" {
                self.paused_since = Some(now); // 방금 일시정지됨: 10초 뒤 숨긴다
            } else if player != self.prev_player || self.paused_since.is_none() {
                self.paused_since = now.checked_sub(HIDE_AFTER); // 처음 볼 때부터 멈춰 있던 미디어: 숨김
            }
        } else {
            self.paused_since = None;
        }
        self.prev_player = player.clone();
        self.prev_status = status.clone();
        self.player = player;
        self.status = status;

        if self.visible(now) {
            self.read_track();
            self.read_position();
            if self.written_player != self.player {
                let _ = std::fs::write(&self.state_file, &self.player); // 클릭 동작(media-focus.sh 등)이 같은 플레이어를 쓴다
                self.written_player = self.player.clone();
            }
        }
    }

    fn visible(&self, now: Instant) -> bool {
        if self.player.is_empty() {
            return false;
        }
        match (self.status.as_str(), self.paused_since) {
            ("Paused", Some(t)) => now.duration_since(t) < HIDE_AFTER,
            ("Paused", None) => false,
            _ => true,
        }
    }

    fn read_track(&mut self) {
        let Ok(proxy) = self.proxy(&self.player) else { return };
        let Ok(meta) = proxy.get_property::<HashMap<String, OwnedValue>>("Metadata") else { return };
        let text = |key: &str| -> String {
            match meta.get(key).map(|v| &**v) {
                Some(Value::Str(s)) => s.to_string(),
                Some(Value::Array(a)) => a
                    .iter()
                    .filter_map(|v| if let Value::Str(s) = v { Some(s.to_string()) } else { None })
                    .collect::<Vec<_>>()
                    .join(", "),
                _ => String::new(),
            }
        };
        let length_us = match meta.get("mpris:length").map(|v| &**v) {
            Some(Value::I64(n)) => *n,
            Some(Value::U64(n)) => *n as i64,
            Some(Value::I32(n)) => *n as i64,
            Some(Value::U32(n)) => *n as i64,
            Some(Value::F64(n)) => *n as i64,
            _ => 0,
        };
        self.track = Track { title: text("xesam:title"), artist: text("xesam:artist"), length_us };
    }

    fn read_position(&mut self) {
        if let Ok(us) = self.proxy(&self.player).and_then(|p| Ok(p.get_property::<i64>("Position")?)) {
            self.position_s = us / 1_000_000;
        }
    }

    fn label(&self) -> String {
        let t = &self.track;
        if t.artist.is_empty() { t.title.clone() } else { format!("{} · {}", t.title, t.artist) }
    }

    fn long_label(&self) -> bool {
        self.label().chars().count() > WIDTH
    }

    /// 긴 제목을 한 칸 흘린다 (처음과 한 바퀴 돈 뒤에는 잠깐 멈춘다)
    fn advance(&mut self) {
        let len = self.label().chars().count() + 5;
        if self.hold > 0 {
            self.hold -= 1;
        } else {
            self.offset = (self.offset + 1) % len;
            if self.offset == 0 {
                self.hold = HOLD;
            }
        }
    }

    fn render(&mut self, now: Instant) -> String {
        if !self.visible(now) {
            return HIDDEN.to_string();
        }
        let label = self.label();
        let key = format!("{}|{label}", self.player);
        if key != self.key {
            self.key = key; // 곡이 바뀌면 처음부터
            self.offset = 0;
            self.hold = HOLD;
        }
        let shown = window(&label, self.offset);
        let (icon, class) = if self.status == "Playing" { ('\u{F075A}', "playing") } else { ('\u{F03E4}', "paused") };
        let mut text = format!("{icon} {shown}");
        if self.track.length_us > 0 {
            text += &format!("  {} / {}", fmt_time(self.position_s), fmt_time(self.track.length_us / 1_000_000));
        }
        format!(
            r#"{{"text":"{}","tooltip":"{}","class":"{class}"}}"#,
            json_escape(&text),
            json_escape(&format!("{label}\n{TIP_HELP}"))
        )
    }
}

/// 전광판: 글자 수가 넘치면 (글자 + 공백 5칸)을 이어 붙여 offset부터 WIDTH글자를 보여 준다
fn window(label: &str, offset: usize) -> String {
    if label.chars().count() <= WIDTH {
        return label.to_string();
    }
    let lap: Vec<char> = label.chars().chain("     ".chars()).collect();
    lap.iter().cycle().skip(offset % lap.len()).take(WIDTH).collect()
}

fn fmt_time(t: i64) -> String {
    let t = t.max(0);
    if t >= 3600 { format!("{}:{:02}:{:02}", t / 3600, t % 3600 / 60, t % 60) } else { format!("{}:{:02}", t / 60, t % 60) }
}

fn demo_marquee(label: &str) {
    let mut offset = 0;
    let len = label.chars().count() + 5;
    for _ in 0..6 {
        println!("[{}]", window(label, offset));
        offset = (offset + 1) % len;
    }
}

fn media() -> Res<()> {
    let conn = Connection::session()?;
    let (tx, rx) = mpsc::channel();
    // 재생 상태·곡 정보가 바뀜, 플레이어가 생기거나 사라짐, 재생 위치를 옮김
    watch(&conn, signal_rule("org.freedesktop.DBus.Properties", "PropertiesChanged")?.path(MPRIS_PATH)?.arg(0, MPRIS_PLAYER)?.build(), tx.clone())?;
    watch(&conn, signal_rule("org.freedesktop.DBus", "NameOwnerChanged")?.arg0ns(MPRIS_PREFIX.trim_end_matches('.'))?.build(), tx.clone())?;
    watch(&conn, signal_rule(MPRIS_PLAYER, "Seeked")?.path(MPRIS_PATH)?.build(), tx.clone())?;
    watch_usr1(tx)?;

    let runtime = std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".into());
    let mut m = Media {
        conn,
        player: String::new(),
        status: String::new(),
        prev_player: String::new(),
        prev_status: String::new(),
        paused_since: None,
        track: Track::default(),
        position_s: 0,
        key: String::new(),
        offset: 0,
        hold: HOLD,
        state_file: format!("{runtime}/waybar-media-player"),
        written_player: String::new(),
    };
    let mut out = Out { last: String::new() };
    let start = Instant::now();
    m.scan(start);
    out.emit(&m.render(start));
    let mut next_frame = start + FRAME;
    let mut next_position = start + POSITION_EVERY;

    loop {
        let now = Instant::now();
        // 다음에 깨어날 때: 흐르는 제목, 재생 시간, 일시정지 10초 숨김 중 가장 이른 것. 할 일이 없으면 알림이 올 때까지 잔다
        let mut wake: Option<Instant> = None;
        let mut at = |t: Instant| wake = Some(wake.map_or(t, |w| w.min(t)));
        if m.visible(now) {
            if m.long_label() {
                at(next_frame);
            }
            if m.status == "Playing" && m.track.length_us > 0 {
                at(next_position);
            }
            if let (true, Some(t)) = (m.status == "Paused", m.paused_since) {
                at(t + HIDE_AFTER);
            }
        }
        let got = match wake {
            Some(w) => rx.recv_timeout(w.saturating_duration_since(now)),
            None => rx.recv().map_err(|_| RecvTimeoutError::Disconnected),
        };
        let now = Instant::now();
        match got {
            Ok(()) => {
                while rx.try_recv().is_ok() {} // 한꺼번에 온 알림은 한 번만 처리
                m.scan(now);
            }
            Err(RecvTimeoutError::Timeout) => {}
            Err(RecvTimeoutError::Disconnected) => return Ok(()),
        }
        if now >= next_frame {
            if m.visible(now) && m.long_label() {
                m.advance();
            }
            next_frame = now + FRAME;
        }
        if now >= next_position {
            if m.visible(now) && m.status == "Playing" {
                m.read_position();
            }
            next_position = now + POSITION_EVERY;
        }
        out.emit(&m.render(now));
    }
}

// ---------- 입력기 ----------

fn ime_line(conn: &Connection) -> &'static str {
    const OFF: &str = r#"{"text":"","class":"off"}"#;
    // fcitx5가 아직 없을 때 물으면 D-Bus가 fcitx5를 옵션 없이 대신 켜 버리므로, 떠 있는지 먼저 본다
    let running = match (DBusProxy::new(conn), zbus::names::BusName::try_from("org.fcitx.Fcitx5")) {
        (Ok(d), Ok(name)) => d.name_has_owner(name).unwrap_or(false),
        _ => false,
    };
    if !running {
        return OFF;
    }
    let im: String = conn
        .call_method(Some("org.fcitx.Fcitx5"), "/controller", Some("org.fcitx.Fcitx.Controller1"), "CurrentInputMethod", &())
        .and_then(|reply| reply.body().deserialize())
        .unwrap_or_default();
    match im.as_str() {
        "hangul" => r#"{"text":"한","tooltip":"한글 (Ctrl+Space로 전환)","class":"hangul"}"#,
        "mozc" => r#"{"text":"あ","tooltip":"일본어 (로마자 입력, Ctrl+Space로 전환)","class":"japanese"}"#,
        "" => OFF,
        _ => r#"{"text":"A","tooltip":"영어 (Ctrl+Space로 전환)","class":"english"}"#,
    }
}

fn ime() -> Res<()> {
    let conn = Connection::session()?;
    let (tx, rx) = mpsc::channel();
    watch(&conn, signal_rule("org.freedesktop.DBus", "NameOwnerChanged")?.arg(0, "org.fcitx.Fcitx5")?.build(), tx.clone())?;
    watch_usr1(tx)?;
    let mut out = Out { last: String::new() };
    loop {
        out.emit(ime_line(&conn));
        match rx.recv_timeout(IME_EVERY) {
            Ok(()) => while rx.try_recv().is_ok() {},
            Err(RecvTimeoutError::Timeout) => {}
            Err(RecvTimeoutError::Disconnected) => return Ok(()),
        }
    }
}
