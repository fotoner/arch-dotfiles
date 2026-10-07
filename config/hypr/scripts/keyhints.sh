#!/usr/bin/env bash
# 단축키 도움말 (Super+H). hyprland.lua의 단축키를 바꾸면 이 목록도 같이 고친다
exec yad --title="단축키" --class=keyhints --list --center --width=620 --height=780 \
  --no-selection --button="닫기:0" \
  --column="단축키" --column="동작" \
  "── Alt = 맥의 Cmd ──" "" \
  "Alt + C / V / X" "복사 / 붙여넣기 / 잘라내기" \
  "Alt + A" "전체 선택" \
  "Alt + Z / Alt + Shift + Z" "실행 취소 / 다시 실행" \
  "Alt + S / Alt + F" "저장 / 찾기" \
  "Alt + T / W / N" "새 탭 / 탭 닫기 / 새 창" \
  "Alt + Q" "창 닫기" \
  "Alt + Space" "Vicinae: 앱 검색·계산기·클립보드 기록·이모지" \
  "Alt + Shift + V" "클립보드 기록 (예전에 복사한 글·이미지 다시 붙여넣기)" \
  "Alt + Tab (Shift)" "다음 창 (이전 창)" \
  "Alt + Shift + 3" "스크린샷: 전체 화면" \
  "Alt + Shift + 4" "스크린샷: 영역을 골라 편집 (Enter = 저장·복사)" \
  "── Super = 창 관리 ──" "" \
  "Super + Q / E / R" "터미널 / 파일 관리자 / 앱 검색" \
  "Super + C" "창 닫기" \
  "Super + V" "창 띄우기 / 타일로 되돌리기" \
  "Super + 방향키" "옆 창으로 이동" \
  "Super + Shift + 방향키" "옆 창과 자리 바꾸기" \
  "Super + 1~0" "워크스페이스 이동" \
  "Super + Shift + 1~0" "창을 그 워크스페이스로 보내기" \
  "Super + S / Super + Shift + S" "숨김 공간 열기 / 창을 숨김 공간으로" \
  "Super + 마우스 끌기" "왼쪽: 창 이동, 오른쪽: 크기 조절" \
  "Super + A" "제어 센터: Wi-Fi·블루투스·밝기·음량·충전 한도 (상단바 토글 아이콘도 같음)" \
  "Super + N" "알림 목록 (상단바 시계 클릭도 같음, 시계 오른쪽 클릭 = 방해 금지)" \
  "Super + L" "화면 잠금" \
  "Super + Esc" "전원 메뉴" \
  "Super + M" "로그아웃" \
  "Super + H" "이 도움말" \
  "── 기타 ──" "" \
  "Print / Shift + Print" "영역을 클립보드로 / 전체 화면을 ~/Pictures에 저장" \
  "Ctrl + Space" "입력기 바꾸기: A → 한 → あ (일본어는 로마자 입력)" \
  "세 손가락 좌우 쓸기" "워크스페이스 전환" \
  "Ctrl + Shift + A 다음 L / M" "터미널 더 투명하게 / 덜 투명하게"
