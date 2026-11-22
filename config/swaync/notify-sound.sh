#!/usr/bin/env bash
# 알림이 오면 소리를 낸다 (swaync config.json의 scripts가 알림마다 실행. 알림 정보는 SWAYNC_* 환경 변수로 온다).
# 조용히 넘어가는 경우: 방해 금지 중, 이미 떠 있는 알림을 고치는 것(진행률 등), 중요도 낮음, 자기 소리를 따로 내는 앱
# 소리를 바꾸려면 SOUND를 다른 파일로 (예: /usr/share/sounds/freedesktop/stereo/ 아래 bell.oga, complete.oga)
SOUND=/usr/share/sounds/freedesktop/stereo/message-new-instant.oga
VOLUME=0.7

[ "${SWAYNC_REPLACES_ID:-0}" = 0 ] || exit 0
[ "${SWAYNC_HINT_SUPPRESS_SOUND:-}" = true ] && exit 0
# 알림이 자기 소리를 지정했으면 그걸 쓴다 (알림 규격의 sound-file / sound-name 힌트)
if [ -f "${SWAYNC_SOUND_FILE:-}" ]; then
  SOUND=$SWAYNC_SOUND_FILE
elif [ -f "/usr/share/sounds/freedesktop/stereo/${SWAYNC_SOUND_NAME:-none}.oga" ]; then
  SOUND=/usr/share/sounds/freedesktop/stereo/$SWAYNC_SOUND_NAME.oga
fi
[ "${SWAYNC_URGENCY:-}" = Low ] && exit 0
case "${SWAYNC_APP_NAME,,} ${SWAYNC_DESKTOP_ENTRY,,}" in
  *discord*|*slack*|*telegram*|*vesktop*) exit 0 ;;
esac
[ "$(swaync-client -D 2>/dev/null)" = true ] && exit 0

# 한꺼번에 여러 개가 와도 0.8초에 한 번만
stamp="${XDG_RUNTIME_DIR:-/tmp}/notify-sound.last"
now=$(date +%s%3N)
last=$(cat "$stamp" 2>/dev/null || echo 0)
[ $((now - last)) -lt 800 ] && exit 0
echo "$now" > "$stamp"

# 알림 표시를 기다리게 하지 않도록 따로 띄우고 바로 끝낸다
setsid -f pw-play --volume "$VOLUME" "$SOUND" >/dev/null 2>&1 </dev/null
exit 0
