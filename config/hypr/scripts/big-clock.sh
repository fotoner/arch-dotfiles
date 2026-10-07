#!/usr/bin/env bash
# 터미널 큰 시계: 블록 숫자로 HH:MM (가운데 쌍점은 1초마다 깜박임), 아래에 한국어 날짜. Catppuccin 색.
# 창 크기에 맞춰 숫자 크기를 바꾼다. q를 누르면 끝. 로그인 첫 화면(startup-layout.sh) 왼쪽 아래에 뜬다
# 시험: big-clock.sh --once (한 번만 그리고 끝)

# 숫자 글꼴: 가로 3칸 × 세로 5줄 (1 = 칠함)
FONT=(
  "111101101101111" # 0
  "010110010010111" # 1
  "111001111100111" # 2
  "111001111001111" # 3
  "101101111001001" # 4
  "111100111001111" # 5
  "111100111101111" # 6
  "111001001001001" # 7
  "111101111101111" # 8
  "111101111001111" # 9
)
COLON="01010" # 가로 1칸

MAUVE=$'\e[38;2;203;166;247m'
SUB=$'\e[38;2;166;173;200m'
RESET=$'\e[0m'

draw() {
  local blink=$1 cols rows
  cols=$(tput cols) rows=$(tput lines)
  local hm date
  hm=$(date +%H%M)
  date=$(LC_TIME=ko_KR.UTF-8 date +"%-m월 %-d일 %A")

  # 한 칸 = 가로 2s, 세로 s. 전체 폭 = 숫자 4개(3칸) + 쌍점(1칸) + 사이 4군데(1칸) = 17칸
  local s=$(((cols - 4) / 34)) h=$(((rows - 3) / 5))
  ((h < s)) && s=$h
  ((s < 1)) && s=1
  local width=$((17 * 2 * s)) height=$((5 * s + 2))
  local left=$(((cols - width) / 2)) top=$(((rows - height) / 2))
  ((left < 0)) && left=0
  ((top < 0)) && top=0

  local pad block space
  printf -v pad '%*s' "$left" ''
  printf -v block '%*s' $((2 * s)) ''
  block=${block// /█}
  printf -v space '%*s' $((2 * s)) ''

  local out=$'\e[H\e[2J' r i d x bits line k
  for ((k = 0; k < top; k++)); do out+=$'\n'; done
  for ((r = 0; r < 5; r++)); do
    line=""
    for ((i = 0; i < 4; i++)); do
      d=${hm:i:1}
      bits=${FONT[d]:r*3:3}
      for ((x = 0; x < 3; x++)); do
        [[ ${bits:x:1} == 1 ]] && line+=$block || line+=$space
      done
      line+=$space
      if ((i == 1)); then
        [[ $blink == 1 && ${COLON:r:1} == 1 ]] && line+=$block || line+=$space
        line+=$space
      fi
    done
    for ((k = 0; k < s; k++)); do out+="$pad$MAUVE$line$RESET"$'\n'; done
  done

  # 날짜는 시계 아래 한 줄 띄우고 가운데
  local dlen=$((${#date} * 2 - $(printf '%s' "$date" | tr -cd '0-9 ' | wc -c)))
  local dpad=$(((cols - dlen) / 2))
  ((dpad < 0)) && dpad=0
  printf -v pad '%*s' "$dpad" ''
  out+=$'\n'"$pad$SUB$date$RESET"
  printf '%s' "$out"
}

if [[ ${1:-} == --once ]]; then
  draw 1
  echo
  exit 0
fi

printf '\e[?1049h\e[?25l'
trap 'printf "\e[?25h\e[?1049l"' EXIT
trap 'draw $blink' WINCH

blink=1
while true; do
  draw $blink
  blink=$((1 - blink))
  # 1초 기다리면서 q를 누르면 끝
  if read -rsn1 -t 1 key && [[ $key == q ]]; then
    break
  fi
done
