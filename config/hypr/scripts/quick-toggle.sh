#!/usr/bin/env bash
# 알림 센터 빠른 버튼: 누를 때마다 실제 상태를 확인해 반대로 바꾸고, 결과를 음량 팝업처럼 화면에 잠깐 보여 준다
# (swaync의 토글 버튼은 상태를 제때 못 맞춰서, 버튼이 기억하는 상태는 쓰지 않는다)
osd() {
  swayosd-client --custom-message "$1" --custom-icon "$2" >/dev/null 2>&1 \
    || notify-send -a "빠른 설정" "$1"
}

case "${1:-}" in
  wifi)
    if [ "$(nmcli radio wifi)" = enabled ]; then
      nmcli radio wifi off && osd "Wi-Fi 꺼짐" network-wireless-offline
    else
      nmcli radio wifi on && osd "Wi-Fi 켜짐" network-wireless
    fi
    ;;
  bluetooth)
    if bluetoothctl show | grep -q "Powered: yes"; then
      bluetoothctl power off >/dev/null && osd "블루투스 꺼짐" bluetooth-disabled
    else
      { bluetoothctl power on >/dev/null || { rfkill unblock bluetooth && bluetoothctl power on >/dev/null; }; } \
        && osd "블루투스 켜짐" bluetooth-active
    fi
    ;;
  mic)
    swayosd-client --input-volume mute-toggle >/dev/null 2>&1 || {
      wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then osd "마이크 꺼짐" microphone-sensitivity-muted
      else osd "마이크 켜짐" microphone-sensitivity-high; fi
    }
    ;;
  *)
    echo "사용법: $0 wifi|bluetooth|mic" >&2
    exit 1
    ;;
esac
