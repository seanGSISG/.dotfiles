# Zsh environment exports
# Purpose: Core environment setup - PATH, history, and zsh options

# --- ZDOTDIR ---
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# --- PATH Construction ---
# Single authoritative location - no duplication
export PATH="$HOME/.local/bin:$HOME/.local/share/fnm:$HOME/bin:$HOME/.bun/bin:$HOME/.opencode/bin:$HOME/.fzf/bin:$PATH"

# --- Environment Variables ---
export EDITOR="${EDITOR:-code}"
export LANG="${LANG:-en_US.UTF-8}"
export ENABLE_LSP_TOOLS=1
export BUN_INSTALL="$HOME/.bun"

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
