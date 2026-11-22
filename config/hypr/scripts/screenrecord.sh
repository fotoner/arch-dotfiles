#!/usr/bin/env bash
# 맥식 화면 녹화 (Alt+Shift+5). 파일은 ~/Videos/Screen Recordings에 mp4로 저장한다.
# 영상은 인텔 GPU(VA-API)로 h264 인코딩해서 CPU를 거의 쓰지 않는다.
#   toggle                              녹화 중이면 멈추고, 아니면 녹화 도구 막대(Quickshell)를 띄운다
#   start full|area none|system|mic     녹화 시작 (도구 막대가 부른다). full = 지금 보고 있는 모니터 전체
#   stop                                멈추고 저장 알림 (열기 / 폴더 열기)
#   waybar                              상단바 표시. 녹화 중이면 매초 "● 0:12", 아니면 신호가 올 때까지 기다린다
set -uo pipefail

# 상단바 표시(waybar)는 상단바가 꺼지거나 다시 읽히면 같이 끝나야 한다 (기다리는 동안에는 출력하지 않아 스스로 알 수 없다)
[ "${1:-}" = waybar ] && [ -z "${SR_PDEATHSIG:-}" ] && SR_PDEATHSIG=1 exec setpriv --pdeathsig TERM "$0" "$@"

run="${XDG_RUNTIME_DIR:-/tmp}/screenrecord"
mkdir -p "$run"
dir="$HOME/Videos/Screen Recordings"

recording() { [ -f "$run/pid" ] && kill -0 "$(cat "$run/pid")" 2>/dev/null; }

# 상단바 표시 깨우기: 모니터마다 상단바가 따로 있어서 표시 프로세스가 여럿이다
wake_bars() {
  local f
  for f in "$run"/bar.*; do
    [ -e "$f" ] || continue
    kill -USR1 "$(cat "$f")" 2>/dev/null || rm -f "$f"
  done
}

start() {
  recording && return 0
  local target="${1:-full}" sound="${2:-none}" args=() geometry
  case "$target" in
    area) geometry=$(slurp) || return 0 # 영역을 고르다 Esc를 누르면 녹화하지 않는다
          args+=(-g "$geometry") ;;
    *)    args+=(-o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')") ;;
  esac
  case "$sound" in
    system) args+=(--audio="$(pactl get-default-sink).monitor") ;;
    mic)    args+=(--audio="$(pactl get-default-source)") ;;
  esac
  mkdir -p "$dir"
  local file="$dir/화면 녹화 $(date '+%Y-%m-%d %H.%M.%S').mp4"
  wf-recorder -y "${args[@]}" -c h264_vaapi -d /dev/dri/renderD128 -f "$file" >/dev/null 2>"$run/log" &
  echo $! > "$run/pid"
  date +%s > "$run/start"
  printf '%s' "$file" > "$run/file"
  sleep 0.5
  if ! recording; then
    notify-send -a "화면 녹화" -u critical "화면 녹화" "시작하지 못했어요: $(tail -n 1 "$run/log")"
    rm -f "$run/pid"
    return 1
  fi
  wake_bars
}

stop() {
  recording || return 0
  local pid file i
  pid=$(cat "$run/pid")
  file=$(cat "$run/file")
  kill -INT "$pid"
  for i in $(seq 50); do # 파일을 마무리할 때까지 최대 5초 기다린다
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1
  done
  rm -f "$run/pid" "$run/start"
  wake_bars
  (
    # 알림의 단추를 누를 때까지 기다리되, 안 누르면 5분 뒤에 그만 기다린다 (알림은 알림 센터에 남는다)
    action=$(timeout 300 notify-send -a "화면 녹화" -A open="열기" -A folder="폴더 열기" "화면 녹화" "저장했어요: ${file##*/}")
    case "$action" in
      open) xdg-open "$file" ;;
      folder) xdg-open "$dir" ;;
    esac
  ) >/dev/null 2>&1 &
}

waybar_loop() {
  local me="$run/bar.$$" s
  echo $$ > "$me"
  trap 'rm -f "$me"; exit 0' EXIT TERM INT
  trap ':' USR1
  while true; do
    if recording; then
      s=$(( $(date +%s) - $(cat "$run/start" 2>/dev/null || date +%s) ))
      printf '{"text":"● %d:%02d","class":"recording","tooltip":"화면 녹화 중 (누르거나 Alt+Shift+5로 멈추기)"}\n' $((s / 60)) $((s % 60))
      sleep 1 & wait $!
    else
      printf '{"text":"","class":"idle"}\n'
      sleep infinity & wait $! # 녹화가 시작되면 USR1로 깨운다
      kill $! 2>/dev/null
    fi
  done
}

case "${1:-}" in
  toggle) if recording; then stop; else qs ipc call record open; fi ;;
  start)  start "${2:-full}" "${3:-none}" ;;
  stop)   stop ;;
  waybar) waybar_loop ;;
  *) echo "사용법: $0 toggle | start full|area none|system|mic | stop | waybar" >&2; exit 2 ;;
esac
