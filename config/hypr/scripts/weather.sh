#!/usr/bin/env bash
# 지역 날씨를 Waybar JSON 한 줄로 출력한다: 아이콘 + 기온 (예: 󰖙 23°), 툴팁에 도시·날씨·체감·습도·바람·오늘 최저/최고.
# 위치는 IP로 추정한다(ipinfo.io). VPN 등으로 틀리면 아래 LAT·LON·CITY를 직접 적는다 (예: 37.5665 126.9780 서울).
# 날씨는 Open-Meteo (키 없이 쓰는 무료 API). 실패하면 아무것도 출력하지 않고 1로 끝난다.
LAT=""
LON=""
CITY=""
set -o pipefail

if [ -z "$LAT" ] || [ -z "$LON" ]; then
  loc=$(curl -fsS -m 10 https://ipinfo.io/json) || exit 1
  IFS=$'\t' read -r LAT LON city < <(jq -r '[(.loc | split(",")[]), (.city // "")] | @tsv' <<<"$loc") || exit 1
  CITY=${CITY:-$city}
fi

w=$(curl -fsS -m 10 "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1&wind_speed_unit=ms") || exit 1
IFS=$'\t' read -r temp feels hum code day wind tmax tmin < <(jq -r '
  [.current.temperature_2m, .current.apparent_temperature, .current.relative_humidity_2m,
   .current.weather_code, .current.is_day, .current.wind_speed_10m,
   .daily.temperature_2m_max[0], .daily.temperature_2m_min[0]] | @tsv' <<<"$w") || exit 1
[ -n "$code" ] || exit 1

deg() { # 반올림한 정수 기온 (-0은 0으로)
  local v
  printf -v v '%.0f' "$1"
  [ "$v" = "-0" ] && v=0
  printf '%s' "$v"
}

# WMO 날씨 코드 → 설명, 아이콘 (낮/밤)
sun=$'\U000F0599' moon=$'\U000F0594' partly=$'\U000F0595' partly_night=$'\U000F0F31' cloud=$'\U000F0590'
fog=$'\U000F0591' rain=$'\U000F0597' pour=$'\U000F0596' sleet=$'\U000F067F' snow=$'\U000F0598'
snow_heavy=$'\U000F0F36' thunder=$'\U000F0593' thunder_rain=$'\U000F067E'
if [ "$day" = 1 ]; then clear=$sun few=$partly; else clear=$moon few=$partly_night; fi
case "$code" in
  0) desc="맑음" icon=$clear ;;
  1) desc="대체로 맑음" icon=$few ;;
  2) desc="구름 조금" icon=$few ;;
  3) desc="흐림" icon=$cloud ;;
  45 | 48) desc="안개" icon=$fog ;;
  51 | 53 | 55) desc="이슬비" icon=$rain ;;
  56 | 57) desc="어는 이슬비" icon=$sleet ;;
  61 | 63) desc="비" icon=$rain ;;
  65) desc="강한 비" icon=$pour ;;
  66 | 67) desc="어는 비" icon=$sleet ;;
  71 | 73) desc="눈" icon=$snow ;;
  75) desc="강한 눈" icon=$snow_heavy ;;
  77) desc="싸락눈" icon=$snow ;;
  80 | 81) desc="소나기" icon=$rain ;;
  82) desc="강한 소나기" icon=$pour ;;
  85 | 86) desc="소낙눈" icon=$snow ;;
  95) desc="뇌우" icon=$thunder ;;
  96 | 99) desc="우박을 동반한 뇌우" icon=$thunder_rain ;;
  *) desc="날씨" icon=$cloud ;;
esac

text="$icon $(deg "$temp")°"
tip="${CITY:+$CITY · }$desc $(deg "$temp")°
체감 $(deg "$feels")° · 습도 ${hum}% · 바람 $(printf '%.1f' "$wind")m/s
오늘 최저 $(deg "$tmin")° / 최고 $(deg "$tmax")°"
jq -nc --arg text "$text" --arg tip "$tip" '{text: $text, tooltip: $tip, class: "weather"}'
