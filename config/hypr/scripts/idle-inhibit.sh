#!/usr/bin/env bash
# 잠자기 방지: 켜 두면 가만히 둬도 hypridle이 화면을 어둡게·잠그게·끄게·절전하지 않는다.
# systemd-inhibit(--what=idle)를 백그라운드로 띄워 두는 방식이라 상단바와 제어 센터가 같은 상태를 본다
# (hypridle은 기본으로 systemd의 idle 억제를 따른다).
#   toggle | on | off   켜고 끈 뒤 상단바 아이콘을 새로 그린다
#   state               on 또는 off 출력 (제어 센터용)
#   waybar              상단바 모듈 JSON 출력
pidfile="${XDG_RUNTIME_DIR:-/tmp}/idle-inhibit.pid"
SIGNAL=9 # waybar custom/idle 의 "signal"과 같게

running() {
  local pid
  pid=$(cat "$pidfile" 2>/dev/null) || return 1
  [ -n "$pid" ] && [ "$(ps -o comm= -p "$pid" 2>/dev/null)" = systemd-inhibit ]
}

on() {
  running && return
  setsid -f systemd-inhibit --what=idle --who="잠자기 방지" --why="상단바·제어 센터에서 켬" --mode=block \
    sleep infinity >/dev/null 2>&1
  # setsid -f는 pid를 알려 주지 않아서 방금 뜬 것을 찾는다
  for _ in $(seq 20); do
    pid=$(pgrep -n -u "$UID" -f '^systemd-inhibit --what=idle --who=잠자기 방지') && break
    sleep 0.05
  done
  [ -n "$pid" ] && printf '%s\n' "$pid" >"$pidfile"
}

off() {
  running && kill "$(cat "$pidfile")"
  rm -f "$pidfile"
}

refresh() { pkill -RTMIN+$SIGNAL -x waybar; }

case "${1:-}" in
  on) on; refresh ;;
  off) off; refresh ;;
  toggle) if running; then off; else on; fi; refresh ;;
  state) running && echo on || echo off ;;
  waybar)
    if running; then
      printf '{"text":"\U000F0176","class":"activated","tooltip":"잠자기 방지 켜짐 (클릭해서 끄기)"}\n'
    else
      printf '{"text":"\U000F0FAA","class":"deactivated","tooltip":"잠자기 방지 꺼짐 (클릭해서 켜기)"}\n'
    fi
    ;;
  *) echo "사용법: $0 toggle|on|off|state|waybar" >&2; exit 2 ;;
esac
