# mac-iterm2

CloseAI 영상 속 맥 iTerm2 화면을 **명령 한 줄로** 맞춥니다.
관리자 권한이 필요 없고, 여러 번 실행해도 안전합니다. 윈도우는 [win-iterm2](https://github.com/jsk3342/win-iterm2).

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jsk3342/mac-iterm2/main/install.sh)"
```

끝나면 iTerm2를 **⌘Q로 완전히 끄고 다시 열기**만 하면 됩니다.

> 먼저 [클로드 코드 기본 설치](https://github.com/jsk3342/claude-setup)를 해주세요. Homebrew와 iTerm2가 거기서 준비됩니다.

## 무엇이 바뀌나

| 층 | 구성 요소 | 바뀌는 것 |
|---|---|---|
| 글꼴 | **D2Coding Nerd Font** | 한글이 고르게 보이고, 프롬프트 화살표·아이콘 글자가 들어 있음 |
| 배색 | iTerm2 프로필 **CloseAI** | 짙은 남색 바탕 + 선명한 파랑·초록·분홍, 세로 막대 커서 |
| 상태 막대 | 창 위쪽 | 시계 · 메모리 · CPU |
| 프롬프트 | **oh-my-zsh** + agnoster | `사용자@컴퓨터 ▶ 지금 폴더 ▶ git 상태`를 색 칸으로 |
| 입력 | zsh-autosuggestions · zsh-syntax-highlighting | 전에 친 명령을 흐리게 제안(→ 키로 채택), 틀린 명령은 빨간색 |
| 창 | Minimal 테마 | 제목 막대가 바탕색과 이어짐 |

## 기존 설정은?

- 새 프로필 **CloseAI**를 추가하고 기본으로 지정할 뿐, 원래 프로필은 그대로 남습니다.
- `.zshrc`는 끝에 표시된 칸(`# >>> mac-iterm2 (CloseAI) >>>`)만 덧붙이고, 붙이기 전 원본을 `~/.config/mac-iterm2/`에 백업합니다.
- 이미 oh-my-zsh·powerlevel10k·starship 같은 프롬프트를 쓰고 있으면 프롬프트는 건드리지 않고 배색·글꼴만 적용합니다.
- iTerm2가 켜져 있는 동안 기본 프로필을 바꾸면 iTerm2가 덮어씁니다. 그래서 켜져 있으면 **꺼지는 순간 적용**되도록 예약합니다.

## 되돌리기

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jsk3342/mac-iterm2/main/uninstall.sh)"
```

원래 기본 프로필·테마로 돌리고, CloseAI 프로필과 `.zshrc`의 표시된 칸을 지웁니다. 글꼴과 `~/.oh-my-zsh` 폴더는 남깁니다.

## 문제 해결

| 증상 | 원인 · 해결 |
|---|---|
| 다시 열어도 그대로 | ⌘W(창 닫기)가 아니라 **⌘Q**(앱 종료)로 꺼야 합니다. 그래도 그대로면 iTerm2를 끈 채로 터미널(기본 앱)에서 설치 명령을 한 번 더 실행하세요 |
| 프롬프트 화살표가 네모 | 글꼴 설치가 실패한 경우입니다. 설치 명령을 다시 실행하면 재시도합니다 |
| `Homebrew가 없습니다` | 기본 설치(claude-setup)를 먼저 해주세요 |
| 프롬프트가 안 바뀜 | 이미 다른 프롬프트 설정이 있어 건드리지 않은 경우입니다(설치 출력에 안내) |
