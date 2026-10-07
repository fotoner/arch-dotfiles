#!/usr/bin/env bash
# 상단바 입력기 표시 (fcitx5). 맥 메뉴바의 입력 소스처럼 "A" / "한" / "あ"를 보여 준다. 바뀔 때만 한 줄씩 출력한다
last=""
while true; do
  # fcitx5가 아직 안 떠 있을 때 fcitx5-remote를 부르면 시스템(D-Bus)이 fcitx5를 옵션 없이 대신 켜 버린다. 뜰 때까지 기다린다
  if ! pgrep -x fcitx5 >/dev/null; then
    [ "$last" = off ] || { echo '{"text":"","class":"off"}'; last=off; }
    sleep 0.4
    continue
  fi
  case "$(fcitx5-remote -n 2>/dev/null)" in
    hangul) out='{"text":"한","tooltip":"한글 (Ctrl+Space로 전환)","class":"hangul"}' ;;
    mozc) out='{"text":"あ","tooltip":"일본어 (로마자 입력, Ctrl+Space로 전환)","class":"japanese"}' ;;
    "") out='{"text":"","class":"off"}' ;;
    *) out='{"text":"A","tooltip":"영어 (Ctrl+Space로 전환)","class":"english"}' ;;
  esac
  if [ "$out" != "$last" ]; then
    echo "$out"
    last="$out"
  fi
  sleep 0.4
done
