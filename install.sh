#!/bin/bash
# ============================================================
# 맥 iTerm2 꾸미기 — CloseAI 영상 속 iTerm2 화면을 명령 한 줄로
# 사용법: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jsk3342/mac-iterm2/main/install.sh)"
#
# 하는 일 (여러 번 실행해도 안전, 관리자 권한 불필요)
#   1. 글꼴: D2Coding Nerd Font (Homebrew)
#   2. iTerm2 프로필 'CloseAI': 배색·글꼴·위 상태 막대(시계·메모리·CPU)
#   3. 프롬프트: oh-my-zsh + agnoster + 자동 제안·문법 색
#   4. 기본 프로필 지정 + Minimal 테마 — iTerm2가 꺼져 있을 때 적용
# 기존 설정은 덮어쓰지 않는다. 되돌리기 = uninstall.sh
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

REPO_RAW="${MAC_ITERM2_RAW:-https://raw.githubusercontent.com/jsk3342/mac-iterm2/main}"
PROFILE_GUID="closeai-iterm2-profile"
PROFILE_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
PROFILE_FILE="$PROFILE_DIR/closeai.json"
STATE_DIR="$HOME/.config/mac-iterm2"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
MARK_BEGIN="# >>> mac-iterm2 (CloseAI) >>>"
MARK_END="# <<< mac-iterm2 (CloseAI) <<<"
ITERM_DOMAIN="com.googlecode.iterm2"
# 예약 표시 — 본문 전체가 bash -c 인자로 돌아서, 글자를 이어 쓰면 pkill -f가 이 스크립트까지 죽인다
WAITER_TAG="mac-iterm2-""waiter"

step=0
total=4
warnings=()

progress() {
  step=$((step + 1))
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}[$step/$total] $1${NC}"
  echo "  이유: $2"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
skip() { echo -e "  ${YELLOW}→${NC} $1"; }
warn() { echo -e "  ${RED}!${NC} $1"; warnings+=("$1"); }

# ── 0. 확인 ──
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "맥 전용입니다. 윈도우는 https://github.com/jsk3342/win-iterm2 를 쓰세요."
  exit 1
fi

brew_bin=""
for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [[ -x "$candidate" ]]; then brew_bin="$candidate"; break; fi
done
if [[ -z "$brew_bin" ]]; then
  echo -e "${RED}Homebrew가 없습니다.${NC} 클로드 코드 기본 설치를 먼저 해주세요:"
  echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jsk3342/claude-setup/main/install.sh)"'
  exit 1
fi
brew_prefix="$("$brew_bin" --prefix)"

iterm_app=""
for candidate in "$HOME/Applications/iTerm.app" /Applications/iTerm.app; do
  if [[ -d "$candidate" ]]; then iterm_app="$candidate"; break; fi
done
if [[ -z "$iterm_app" ]]; then
  echo -e "${RED}iTerm2가 없습니다.${NC} 클로드 코드 기본 설치를 먼저 하거나 https://iterm2.com 에서 설치해주세요."
  exit 1
fi

mkdir -p "$STATE_DIR"

echo ""
echo -e "${BOLD}🎨 iTerm2를 CloseAI 영상 화면처럼 꾸밉니다${NC}"
echo "  기존 설정은 지우지 않습니다. 되돌리기 명령은 끝에 안내합니다."

# ── 1. 글꼴 ──
progress "글꼴 (D2Coding Nerd Font)" "한글이 고르게 보이고, 프롬프트의 화살표·아이콘 글자가 들어 있는 글꼴입니다."
font_name=""
find_font() {
  local dir
  for dir in "$HOME/Library/Fonts" /Library/Fonts; do
    if [[ -f "$dir/D2KodingLigatureNerdFontMono-Regular.ttf" ]]; then font_name="D2KodingLigatureNFM"; return 0; fi
    if [[ -f "$dir/D2CodingLigatureNerdFontMono-Regular.ttf" ]]; then font_name="D2CodingLigatureNFM"; return 0; fi
  done
  return 1
}
if find_font; then
  skip "글꼴이 이미 있습니다 ($font_name)"
elif HOMEBREW_NO_ASK=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1 "$brew_bin" install --cask font-d2coding-nerd-font && find_font; then
  ok "글꼴 설치 완료 ($font_name)"
else
  font_name="Menlo"
  warn "글꼴 설치에 실패해 Menlo로 대신합니다. 프롬프트 화살표가 네모로 보일 수 있습니다. 다시 실행하면 재시도합니다."
fi

# ── 2. iTerm2 프로필 ──
progress "iTerm2 프로필 'CloseAI'" "배색·글꼴·위 상태 막대(시계·메모리·CPU)를 새 프로필로 추가합니다. 기존 프로필은 그대로 둡니다."
mkdir -p "$PROFILE_DIR"
template="$(mktemp)"
trap 'rm -f "$template"' EXIT
script_dir=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [[ -n "$script_dir" && -f "$script_dir/profile/closeai.json" ]]; then
  cp "$script_dir/profile/closeai.json" "$template"
else
  curl -fsSL "$REPO_RAW/profile/closeai.json" -o "$template"
fi
if ! grep -q "\"Guid\": \"$PROFILE_GUID\"" "$template"; then
  echo -e "${RED}프로필 파일을 받지 못했습니다.${NC} 인터넷 연결을 확인하고 다시 실행해주세요."
  exit 1
fi
sed "s/__FONT__/$font_name/g" "$template" > "$PROFILE_FILE.tmp"
mv "$PROFILE_FILE.tmp" "$PROFILE_FILE"
ok "프로필 추가 완료 (iTerm2 → 설정 → Profiles 에 'CloseAI')"

# ── 3. 프롬프트 ──
progress "프롬프트 (oh-my-zsh · agnoster)" "지금 폴더와 git 상태를 색 칸으로 보여주고, 전에 친 명령을 흐리게 제안합니다."
zsh_dir="$HOME/.oh-my-zsh"
if [[ -f "$ZSHRC" ]] && grep -qF "$MARK_BEGIN" "$ZSHRC"; then
  skip "이미 적용돼 있습니다 ($ZSHRC)"
elif [[ -f "$ZSHRC" ]] && grep -Eq '^[^#]*(oh-my-zsh\.sh|powerlevel10k|starship init|oh-my-posh|prezto|zinit|antigen)' "$ZSHRC"; then
  skip "이미 쓰는 프롬프트 설정이 있어 건드리지 않습니다 ($ZSHRC). 배색·글꼴만 적용됩니다."
else
  # .zshrc가 없으면 oh-my-zsh 설치기가 자기 틀로 새로 만들어 아래 칸과 겹친다 — 빈 파일을 먼저 둔다
  touch "$ZSHRC"
  if [[ ! -f "$zsh_dir/oh-my-zsh.sh" ]]; then
    if ! "$brew_prefix/bin/git" --version >/dev/null 2>&1; then
      HOMEBREW_NO_ASK=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1 "$brew_bin" install git
    fi
    omz_installer="$(mktemp)"
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$omz_installer"
    echo "  oh-my-zsh 내려받는 중… (자세한 기록: $STATE_DIR/oh-my-zsh-install.log)"
    if ! PATH="$brew_prefix/bin:$PATH" ZSH="$zsh_dir" sh "$omz_installer" --unattended --keep-zshrc > "$STATE_DIR/oh-my-zsh-install.log" 2>&1; then
      tail -5 "$STATE_DIR/oh-my-zsh-install.log"
      echo -e "${RED}oh-my-zsh 설치에 실패했습니다.${NC} 인터넷 연결을 확인하고 다시 실행해주세요."
      exit 1
    fi
    rm -f "$omz_installer"
  fi
  plugin_root="$zsh_dir/custom/plugins"
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ ! -d "$plugin_root/$plugin" ]]; then
      "$brew_prefix/bin/git" clone -q --depth 1 "https://github.com/zsh-users/$plugin" "$plugin_root/$plugin"
    fi
  done
  if [[ -f "$ZSHRC" ]]; then
    cp "$ZSHRC" "$STATE_DIR/zshrc.before-$(date +%Y%m%d-%H%M%S)"
  fi
  cat >> "$ZSHRC" <<EOF

$MARK_BEGIN
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
ZSH_DISABLE_COMPFIX=true
zstyle ':omz:update' mode auto
plugins=(git node npm yarn web-search jsontools colored-man-pages zsh-autosuggestions zsh-syntax-highlighting)
source "\$ZSH/oh-my-zsh.sh"
$MARK_END
EOF
  if zsh -i -c 'exit' </dev/null >/dev/null 2>&1; then
    ok "프롬프트 적용 완료 (원래 .zshrc 백업: $STATE_DIR)"
  else
    warn "새 셸 시작 확인에 실패했습니다. $ZSHRC 의 'mac-iterm2' 칸을 지우면 원래대로 돌아갑니다."
  fi
fi

# ── 4. 기본 프로필 + Minimal 테마 ──
progress "기본 프로필 지정" "iTerm2를 열면 바로 'CloseAI' 화면으로 뜨게 합니다. 켜져 있는 동안 바꾸면 iTerm2가 덮어써서, 꺼진 뒤에 적용합니다."
backup_file="$STATE_DIR/iterm-defaults.before"
if [[ ! -f "$backup_file" ]]; then
  {
    echo "Default Bookmark Guid=$(defaults read "$ITERM_DOMAIN" "Default Bookmark Guid" 2>/dev/null || true)"
    echo "TabStyleWithAutomaticOption=$(defaults read "$ITERM_DOMAIN" TabStyleWithAutomaticOption 2>/dev/null || true)"
  } > "$backup_file"
fi
apply_cmd="defaults write $ITERM_DOMAIN 'Default Bookmark Guid' -string '$PROFILE_GUID'; defaults write $ITERM_DOMAIN TabStyleWithAutomaticOption -int 5"
# 전에 걸어 둔 예약(설치·되돌리기)이 남아 있으면 같은 순간에 겹쳐 덮어쓴다 — 마지막 실행만 남긴다
pkill -f "$WAITER_TAG" 2>/dev/null || true
if pgrep -xq iTerm2; then
  # iTerm2가 꺼질 때까지(최대 12시간) 기다렸다 적용. 이 창이 닫혀도 살아 있게 새 세션으로 띄운다.
  waiter=": $WAITER_TAG; for i in \$(seq 1 43200); do pgrep -xq iTerm2 || { $apply_cmd; exit 0; }; sleep 1; done"
  if [[ -x /usr/bin/perl ]]; then
    /usr/bin/perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV' /bin/bash -c "$waiter" </dev/null >/dev/null 2>&1 &
  else
    nohup /bin/bash -c "$waiter" </dev/null >/dev/null 2>&1 &
  fi
  ok "iTerm2를 끄면 바로 적용되도록 예약했습니다"
  pending=1
else
  eval "$apply_cmd"
  ok "적용 완료"
  pending=0
fi

# ── 끝 ──
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [[ ${#warnings[@]} -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}꾸미기 완료${NC}"
else
  echo -e "${YELLOW}${BOLD}꾸미기 일부 미완료${NC}"
  for w in "${warnings[@]}"; do echo "  - $w"; done
fi
echo ""
if [[ $pending -eq 1 ]]; then
  echo -e "  ${BOLD}iTerm2를 ⌘Q로 완전히 끄고 다시 열어주세요.${NC} 다시 열면 바뀐 화면으로 뜹니다."
else
  echo -e "  ${BOLD}iTerm2를 열어주세요.${NC} 바뀐 화면으로 뜹니다."
fi
echo "  되돌리기: /bin/bash -c \"\$(curl -fsSL $REPO_RAW/uninstall.sh)\""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
