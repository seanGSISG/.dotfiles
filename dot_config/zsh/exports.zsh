# Zsh environment exports
# Purpose: Core environment setup - PATH, history, and zsh options

# --- ZDOTDIR ---
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# --- SSH stty guard (prevents weird remote terminal settings) ---
if [[ -n "$SSH_CONNECTION" ]]; then
  stty() { case "$1" in *:*:*) return 0 ;; *) command stty "$@" ;; esac; }
fi

# --- Terminal type fallback (Ghostty, Kitty, etc.) ---
if [[ -n "$TERM" ]] && ! infocmp "$TERM" &>/dev/null 2>&1; then
  export TERM="xterm-256color"
fi

# --- PATH Construction ---
# Single authoritative location - no duplication
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$HOME/.atuin/bin:$HOME/.opencode/bin:$HOME/.fzf/bin:$PATH"
[[ -d /usr/local/go/bin ]] && export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
[[ -d "$HOME/.kimi-code/bin" ]] && export PATH="$HOME/.kimi-code/bin:$PATH"
[[ -d "$HOME/.claude/bin" ]] && export PATH="$HOME/.claude/bin:$PATH"   # CCG multi-model wrapper
[[ -d "$HOME/.grok/bin" ]] && export PATH="$HOME/.grok/bin:$PATH"

# --- Environment Variables ---
export EDITOR="${EDITOR:-code}"
export LANG="${LANG:-en_US.UTF-8}"
export ENABLE_LSP_TOOLS=1
export BUN_INSTALL="$HOME/.bun"
export BAT_THEME="Dracula"
export UV_LINK_MODE=copy
export HONCHO_PEER_NAME="sean"

# --- fd alias (Debian/Ubuntu ships fd as fdfind) ---
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  alias fd='fdfind'
fi

# --- fzf Configuration ---
# Use fd for file finding (faster, respects .gitignore)
if command -v fd &>/dev/null || command -v fdfind &>/dev/null; then
  _fd_cmd="${commands[fd]:-fdfind}"
  export FZF_DEFAULT_COMMAND="$_fd_cmd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$_fd_cmd --type f --hidden --follow --exclude .git"
  export FZF_ALT_C_COMMAND="$_fd_cmd --type d --hidden --follow --exclude .git"
  unset _fd_cmd
fi
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"

# --- History Configuration ---
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000

# History deduplication and sharing
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first
setopt HIST_IGNORE_DUPS          # Don't record duplicate consecutive entries
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS         # Do not display duplicates when searching
setopt HIST_IGNORE_SPACE         # Don't record entries starting with space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries to history file
setopt INC_APPEND_HISTORY        # Write to history file immediately, not when shell exits
setopt SHARE_HISTORY             # Share history between all sessions

# --- Zsh Options ---
setopt AUTO_CD              # cd by typing directory name
setopt AUTO_PUSHD           # push directories to stack
setopt PUSHD_IGNORE_DUPS    # no duplicates in dir stack
setopt PUSHD_SILENT         # don't print dir stack after pushd/popd
