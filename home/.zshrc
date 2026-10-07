# zsh 설정. mac-dotfiles의 .zshrc를 Arch 경로로 옮겼다 (Homebrew·macOS 전용 줄은 뺐다)
# 도구별 블록은 그 도구가 없으면 아무 일도 하지 않는다

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="amuse"

plugins=(git)

# zsh-completions는 pacman이 /usr/share/zsh/site-functions에 넣어서 따로 등록할 필요가 없다
if [[ -s "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if [[ -d "$HOME/bin" ]]; then
  export PATH="$HOME/bin:$PATH"
fi

# 입력 중 자동완성 제안, 명령어 색칠 (pacman 패키지)
if [[ -s /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -s /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# --- Machine tools (guarded so each is a no-op where the tool is absent) ---

# nvm (pacman nvm 패키지)
[ -s /usr/share/nvm/init-nvm.sh ] && source /usr/share/nvm/init-nvm.sh

# bun
export BUN_INSTALL="$HOME/.bun"
if [[ -d "$BUN_INSTALL/bin" ]]; then
  export PATH="$BUN_INSTALL/bin:$PATH"
fi
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# Colored ls via GNU dircolors (~/.dircolors: Catppuccin Mocha)
if command -v dircolors >/dev/null 2>&1 && [[ -e "$HOME/.dircolors" ]]; then
  eval "$(dircolors -b "$HOME/.dircolors")"
  alias ls='ls --color=auto'
fi

# Android SDK (Linux의 Android Studio 기본 위치)
export ANDROID_HOME="$HOME/Android/Sdk"
if [[ -d "$ANDROID_HOME" ]]; then
  export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools"
fi

# flashlight / maestro
if [[ -d "$HOME/.flashlight/bin" ]]; then
  export PATH="$HOME/.flashlight/bin:$PATH"
fi
if [[ -d "$HOME/.maestro/bin" ]]; then
  export PATH="$PATH:$HOME/.maestro/bin"
fi

# opencode
if [[ -d "$HOME/.opencode/bin" ]]; then
  export PATH="$HOME/.opencode/bin:$PATH"
  export OPENCODE_DISABLE_EXTERNAL_SKILLS=1
fi

# Windsurf
if [[ -d "$HOME/.codeium/windsurf/bin" ]]; then
  export PATH="$HOME/.codeium/windsurf/bin:$PATH"
fi
