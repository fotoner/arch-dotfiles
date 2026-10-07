#!/usr/bin/env bash
# 상단바의 재생 중인 미디어를 누르면 그 미디어를 재생하는 앱 창으로 이동한다.
# MPRIS 플레이어의 D-Bus 주인 프로세스(없으면 그 부모)와 같은 pid인 창을 찾고,
# 같은 앱 창이 여럿이면 제목에 곡 이름이 들어간 창(브라우저의 그 탭)을 고른다.
#   --dry-run  창으로 이동하지 않고 찾은 창만 출력
#   --any      재생·일시정지가 아니어도 첫 플레이어를 쓴다 (시험용)
set -euo pipefail

dry_run=false
any=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --any) any=true ;;
  esac
done

# 상단바에 보이는 플레이어(media-status.sh가 적어 둔 것)를 먼저, 없으면 재생 중 → 일시정지 순으로 고른다
player=""
state="${XDG_RUNTIME_DIR:-/tmp}/waybar-media-player"
if ! $any && [ -s "$state" ]; then
  p=$(cat "$state")
  case "$(playerctl -p "$p" status 2>/dev/null)" in Playing | Paused) player=$p ;; esac
fi
if [ -z "$player" ]; then
  for p in $(playerctl -l 2>/dev/null); do
    s=$(playerctl -p "$p" status 2>/dev/null)
    if $any || [ "$s" = Playing ]; then player=$p; break; fi
    if [ "$s" = Paused ] && [ -z "$player" ]; then player=$p; fi
  done
fi
[ -n "$player" ] || exit 0

title=$(playerctl -p "$player" metadata xesam:title 2>/dev/null || true)
pid=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus \
  GetConnectionUnixProcessID s "org.mpris.MediaPlayer2.$player" 2>/dev/null | awk '{print $2}')
clients=$(hyprctl clients -j)

while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
  addr=$(jq -r --argjson pid "$pid" --arg t "$title" '
    [ .[] | select(.pid == $pid) ] as $w
    | (([ $w[] | select($t != "" and (.title | contains($t))) ] + $w)[0].address) // empty' <<<"$clients")
  if [ -n "$addr" ]; then
    if $dry_run; then
      jq -r --arg a "$addr" '.[] | select(.address == $a) | "\(.class) | \(.title) | 워크스페이스 \(.workspace.name)"' <<<"$clients"
    else
      hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null
    fi
    exit 0
  fi
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
done
