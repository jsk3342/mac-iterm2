#!/bin/bash
# ============================================================
# 맥 iTerm2 꾸미기 되돌리기
# 사용법: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jsk3342/mac-iterm2/main/uninstall.sh)"
# 프로필·프롬프트 칸·기본 프로필 지정을 원래대로. 글꼴과 oh-my-zsh 폴더는 남긴다(다른 데서 쓸 수 있어서).
# ============================================================

set -euo pipefail

PROFILE_FILE="$HOME/Library/Application Support/iTerm2/DynamicProfiles/closeai.json"
STATE_DIR="$HOME/.config/mac-iterm2"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
MARK_BEGIN="# >>> mac-iterm2 (CloseAI) >>>"
MARK_END="# <<< mac-iterm2 (CloseAI) <<<"
ITERM_DOMAIN="com.googlecode.iterm2"
# 예약 표시 — 본문 전체가 bash -c 인자로 돌아서, 글자를 이어 쓰면 pkill -f가 이 스크립트까지 죽인다
WAITER_TAG="mac-iterm2-""waiter"

if [[ -f "$ZSHRC" ]] && grep -qF "$MARK_BEGIN" "$ZSHRC"; then
  cp "$ZSHRC" "$STATE_DIR/zshrc.before-uninstall-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
  # 설치가 칸 앞에 붙인 빈 줄까지 같이 지운다
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0==b { held=0; skip=1; next }
    $0==e { skip=0; next }
    skip  { next }
    held  { print ""; held=0 }
    $0=="" { held=1; next }
    { print }
    END { if (held) print "" }' "$ZSHRC" > "$ZSHRC.tmp"
  mv "$ZSHRC.tmp" "$ZSHRC"
  echo "✓ .zshrc의 mac-iterm2 칸을 지웠습니다"
fi

restore_cmd=""
backup_file="$STATE_DIR/iterm-defaults.before"
if [[ -f "$backup_file" ]]; then
  while IFS='=' read -r key value; do
    if [[ -n "$value" ]]; then
      if [[ "$key" == "TabStyleWithAutomaticOption" ]]; then
        restore_cmd+="defaults write $ITERM_DOMAIN '$key' -int '$value'; "
      else
        restore_cmd+="defaults write $ITERM_DOMAIN '$key' -string '$value'; "
      fi
    else
      restore_cmd+="defaults delete $ITERM_DOMAIN '$key' 2>/dev/null || true; "
    fi
  done < "$backup_file"
fi

finish="rm -f '$PROFILE_FILE' '$backup_file'"
# 설치가 걸어 둔 "꺼지면 적용" 예약이 남아 있으면 되돌린 걸 다시 덮어쓴다 — 먼저 끈다
pkill -f "$WAITER_TAG" 2>/dev/null || true
if pgrep -xq iTerm2; then
  waiter=": $WAITER_TAG; for i in \$(seq 1 43200); do pgrep -xq iTerm2 || { $restore_cmd $finish; exit 0; }; sleep 1; done"
  if [[ -x /usr/bin/perl ]]; then
    /usr/bin/perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV' /bin/bash -c "$waiter" </dev/null >/dev/null 2>&1 &
  else
    nohup /bin/bash -c "$waiter" </dev/null >/dev/null 2>&1 &
  fi
  echo "✓ iTerm2를 ⌘Q로 끄면 원래 기본 프로필로 돌아가고 'CloseAI' 프로필이 지워집니다"
else
  eval "$restore_cmd $finish"
  echo "✓ 원래 기본 프로필로 돌렸고 'CloseAI' 프로필을 지웠습니다"
fi
echo "  글꼴(D2Coding Nerd Font)과 ~/.oh-my-zsh 폴더는 남겨뒀습니다."
