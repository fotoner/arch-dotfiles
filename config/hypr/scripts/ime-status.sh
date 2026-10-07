#!/usr/bin/env bash
# 상단바 입력기 표시 (fcitx5). 맥 메뉴바의 입력 소스처럼 "A" / "한" / "あ"를 보여 준다. 바뀔 때만 한 줄씩 출력한다
last=""
while true; do
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
