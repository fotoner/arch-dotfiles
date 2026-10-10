#!/usr/bin/env bash
# 상단바 왼쪽 끝: 소리가 나면 오디오 파형, 조용하면 지역 날씨. Waybar에 한 줄(JSON)씩 출력한다.
# 파형: 지금 나오는 소리(기본 출력 장치)를 cava로 받아 ▁▂▃▄▅▆▇█ 막대로
#   소리가 나면 막대가 왼쪽부터 하나씩 펼쳐지며 나타난다
#   조용해지면 1초 뒤 흐려지고(class silent), 2.5초 뒤 오른쪽부터 하나씩 접히며 사라진다 (곡 사이 잠깐의 정적에는 안 접힌다)
#   다 접힌 뒤 cava는 쉬어서 CPU를 거의 안 쓴다
# 날씨: weather.sh를 15분마다(실패하면 1분 뒤 다시) 불러 $XDG_RUNTIME_DIR/waybar-weather.json 에 담아 두고, 파형이 없을 때 보여 준다
#   --frames N  cava N프레임만 처리하고 끝낸다 (시험용)
BARS=8
FPS=30
GLYPHS="▁▂▃▄▅▆▇█"
frames=0
[ "${1:-}" = "--frames" ] && frames=${2:-30}
here=$(dirname "$(readlink -f "$0")")
rt=${XDG_RUNTIME_DIR:-/tmp}
cache="$rt/waybar-weather.json"
hidden='{"text":"","class":"hidden"}'

trap 'kill $(jobs -p) 2>/dev/null' EXIT

# 날씨 받아 두기
if [ "$frames" -eq 0 ]; then
  while true; do
    if out=$("$here/weather.sh"); then
      printf '%s\n' "$out" >"$cache.tmp" && mv "$cache.tmp" "$cache"
      sleep 900
    else
      sleep 60
    fi
  done &
fi

# sleep_timer: 접히는 애니메이션(2.5초 + 막대 8개 × 2프레임)이 끝난 뒤에 쉬도록 4초
conf="$rt/waybar-cava.conf"
cat >"$conf" <<EOF
[general]
framerate = $FPS
bars = $BARS
autosens = 1
sleep_timer = 4

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = 59
frame_delimiter = 10
channels = mono
mono_option = average

[smoothing]
noise_reduction = 77
EOF

# JSON 안에 그대로 들어가므로 줄바꿈은 \n 두 글자로 (awk에는 ENVIRON으로 넘겨서 \n이 진짜 줄바꿈으로 안 바뀌게)
export WAVE_TIP='지금 나오는 소리의 파형\n클릭: 재생 중인 앱으로 이동 · 오른쪽 클릭: 재생/일시정지'

# 파형: 프레임마다 JSON 한 줄, 다 접혀서 안 보일 때는 HIDDEN
# cava가 없으면 설치될 때까지 5초마다 확인하고, cava가 끝나면(PipeWire 재시작 등) 1초 뒤 다시 붙는다
exec {wave}< <(
  until command -v cava >/dev/null; do sleep 5; done
  while true; do
    cava -p "$conf" 2>/dev/null
    [ "$frames" -gt 0 ] && break
    sleep 1
  done | LC_ALL=C.UTF-8 awk -F';' -v glyphs="$GLYPHS" -v fps="$FPS" -v frames="$frames" '
    BEGIN {
      split(glyphs, g, ""); tip = ENVIRON["WAVE_TIP"]
      dim_after = fps          # 조용한 지 1초 → 흐리게
      hide_after = fps * 2.5   # 조용한 지 2.5초 → 접기 시작
      shown = 0                # 지금 보이는 막대 수 (0이면 숨김)
      quiet = hide_after       # 조용했던 프레임 수 (처음엔 숨은 상태로 시작)
      last = "|hidden"         # 처음 숨김은 바깥에서 날씨로 보여 준다
    }
    {
      n = 0; loud = 0
      for (i = 1; i <= NF; i++) {
        if ($i == "") continue
        v = $i + 0; if (v > 7) v = 7
        val[++n] = v; loud += v
      }
      quiet = loud ? 0 : quiet + 1
      if (loud && shown < n) shown++                                    # 펼치기: 한 프레임에 하나씩
      else if (quiet >= hide_after && shown > 0 && quiet % 2 == 0) shown-- # 접기: 두 프레임에 하나씩

      text = ""
      for (i = 1; i <= shown; i++) text = text g[val[i] + 1]
      cls = shown == 0 ? "hidden" : quiet >= dim_after ? "silent" : "playing"

      line = text "|" cls
      if (line != last) {        # 같은 모양이면 Waybar를 다시 그리지 않는다
        last = line
        if (shown == 0) print "HIDDEN"
        else printf "{\"text\":\"%s\",\"class\":\"%s\",\"tooltip\":\"%s\"}\n", text, cls, tip
        fflush()
      }
      if (frames && ++count >= frames) exit
    }'
)

# 파형이 있으면 파형, 없으면 날씨(받아 둔 게 없으면 숨김). 조용할 때는 3초마다 날씨가 바뀌었는지 본다
mode=weather last=$hidden
[ -s "$cache" ] && last=$(<"$cache")
printf '%s\n' "$last"
while true; do
  if IFS= read -r -t 3 -u "$wave" line; then
    if [ "$line" = HIDDEN ]; then mode=weather; else mode=wave out=$line; fi
  elif [ $? -le 128 ]; then
    break # 파형 쪽이 끝남 (--frames 시험)
  fi
  if [ "$mode" = weather ]; then
    out=$hidden
    [ -s "$cache" ] && out=$(<"$cache")
  fi
  if [ "$out" != "$last" ]; then
    printf '%s\n' "$out"
    last=$out
  fi
done
