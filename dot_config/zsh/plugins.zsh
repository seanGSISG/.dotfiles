# Antidote plugin manager
# Source: https://github.com/mattmc3/antidote

# Ensure antidote is installed
if [[ ! -d ${ZDOTDIR:-$HOME}/.antidote ]]; then
  echo "Installing antidote..."
  git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-$HOME}/.antidote
fi

# Source antidote
source ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh

# Load plugins from .zsh_plugins.txt
antidote load ${ZDOTDIR:-$HOME/.config/zsh}/.zsh_plugins.txt

# --- Completion System ---
# Load completion system (call once only)
autoload -Uz compinit

# Speed optimization: only regenerate .zcompdump once per day
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit -d "${ZDOTDIR:-$HOME}/.zcompdump"
else
  compinit -C -d "${ZDOTDIR:-$HOME}/.zcompdump"
fi

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # Case-insensitive
zstyle ':completion:*' menu select                            # Menu selection
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"       # Colored completions

# Bind history-substring-search to arrow keys
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
