#!/usr/bin/env bash
# 상단바 왼쪽 미디어 표시. Waybar에 한 줄(JSON)씩 출력한다.
#   재생 중: 󰝚 제목 · 아티스트  0:42 / 3:15   (긴 제목은 전광판처럼 옆으로 흘러간다)
#   일시정지: 󰏤 아이콘으로 바꿔 10초 동안 보여 준 뒤 숨긴다 (처음부터 멈춰 있던 미디어는 보이지 않는다)
# 지금 보여 주는 플레이어 이름은 $XDG_RUNTIME_DIR/waybar-media-player 에 적어서 클릭 동작이 같은 플레이어를 쓴다
#   --frames "글자"  흐르는 모양만 몇 프레임 출력하고 끝낸다 (시험용)
export LC_CTYPE=C.UTF-8 # 한글·일본어를 글자 단위로 자르기 위해

HIDE_AFTER=10   # 일시정지 뒤 숨기기까지 초
WIDTH=36        # 제목·아티스트 부분에 보이는 글자 수
HOLD=8          # 처음과 한 바퀴 돈 뒤 멈춰 있는 프레임 수 (8 × 0.25초 = 2초)
TICK=0.25       # 화면 갱신 간격(초). 플레이어 상태는 4프레임(1초)마다 읽는다
STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-media-player"

json_escape() { # $1 = 결과 변수 이름, $2 = 문자열
  local s=$2
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\t'/ }
  s=${s//$'\n'/\\n}
  printf -v "$1" '%s' "$s"
}

fmt_time() { # $1 = 결과 변수 이름, $2 = 초
  local t=${2%.*}
  [ -n "$t" ] || t=0
  if [ "$t" -ge 3600 ]; then
    printf -v "$1" '%d:%02d:%02d' $((t / 3600)) $((t % 3600 / 60)) $((t % 60))
  else
    printf -v "$1" '%d:%02d' $((t / 60)) $((t % 60))
  fi
}

offset=0 hold=$HOLD
marquee() { # $1 = 결과 변수 이름, $2 = 전체 글자. 부를 때마다 한 칸씩 흐른다
  local label=$2
  if [ "${#label}" -le "$WIDTH" ]; then
    printf -v "$1" '%s' "$label"
    return
  fi
  local loop="$label     " doubled
  doubled="$loop$loop"
  printf -v "$1" '%s' "${doubled:offset:WIDTH}"
  if [ "$hold" -gt 0 ]; then
    hold=$((hold - 1))
  else
    offset=$(((offset + 1) % ${#loop}))
    [ "$offset" -eq 0 ] && hold=$HOLD
  fi
}

if [ "${1:-}" = "--frames" ]; then
  HOLD=0 hold=0
  for _ in 1 2 3 4 5 6; do marquee frame "$2"; printf '[%s]\n' "$frame"; done
  exit 0
fi

tick=0 last_key="" last_line=""
player="" status="" title="" artist="" length="" position="" visible=false
prev_player="" prev_status="" paused_since=0
while true; do
  if [ $((tick % 4)) -eq 0 ]; then
    player="" status=""
    for p in $(playerctl -l 2>/dev/null); do
      s=$(playerctl -p "$p" status 2>/dev/null)
      if [ "$s" = Playing ]; then player=$p status=$s; break; fi
      if [ "$s" = Paused ] && [ -z "$player" ]; then player=$p status=$s; fi
    done

    now=$(printf '%(%s)T' -1)
    if [ "$status" = Paused ]; then
      if [ "$player" = "$prev_player" ] && [ "$prev_status" = Playing ]; then
        paused_since=$now                   # 방금 일시정지됨: 10초 타이머 시작
      elif [ "$player" != "$prev_player" ] || [ "$paused_since" = 0 ]; then
        paused_since=$((now - HIDE_AFTER))  # 처음 볼 때부터 멈춰 있던 미디어: 숨김
      fi
    else
      paused_since=0
    fi
    prev_player=$player prev_status=$status

    if [ -z "$player" ] || { [ "$status" = Paused ] && [ $((now - paused_since)) -ge "$HIDE_AFTER" ]; }; then
      visible=false
    else
      visible=true
      printf '%s' "$player" > "$STATE"
      IFS=$'\t' read -r title artist length <<<"$(playerctl -p "$player" metadata --format '{{title}}	{{artist}}	{{mpris:length}}' 2>/dev/null)"
      position=$(playerctl -p "$player" position 2>/dev/null)
    fi
  fi

  if ! $visible; then
    line='{"text":"","class":"hidden"}'
  else
    label="$title${artist:+ · $artist}"
    if [ "$player|$label" != "$last_key" ]; then # 곡이 바뀌면 처음부터
      offset=0 hold=$HOLD last_key="$player|$label"
    fi
    marquee shown "$label"
    if [ "$status" = Playing ]; then icon=$'\U000F075A' class=playing; else icon=$'\U000F03E4' class=paused; fi
    text="$icon $shown"
    if [ -n "$length" ] && [ "$length" -gt 0 ] 2>/dev/null; then
      fmt_time pos "$position"
      fmt_time len $((length / 1000000))
      text+="  $pos / $len"
    fi
    json_escape text_e "$text"
    json_escape tip_e "$label"$'\n'"클릭: 재생 중인 앱으로 이동 · 오른쪽 클릭: 재생/일시정지 · 가운데 클릭: 다음 곡"
    line="{\"text\":\"$text_e\",\"tooltip\":\"$tip_e\",\"class\":\"$class\"}"
  fi

  if [ "$line" != "$last_line" ]; then
    printf '%s\n' "$line"
    last_line=$line
  fi
  tick=$((tick + 1))
  sleep "$TICK"
done
