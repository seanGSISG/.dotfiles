# Tool integrations
# Each tool is loaded only if available (graceful on fresh machines)

# --- Node.js (Node 24 LTS at ~/.local/node, symlinked into ~/.local/bin; fnm removed 2026-07-16) ---

# --- fzf (Fuzzy Finder) ---
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
elif command -v fzf &>/dev/null; then
  eval "$(fzf --zsh)"
fi

# --- zoxide (Smart cd) ---
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# --- direnv (Auto-load .envrc per directory) ---
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# --- Cargo/Rust ---
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# --- Atuin (Better shell history) ---
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
  bindkey '^r' atuin-search  # Force Ctrl-R to Atuin
fi

# --- Azure CLI (az completion) ---
if command -v az &>/dev/null; then
  source /etc/bash_completion.d/azure-cli 2>/dev/null
fi

# --- mise (tool version manager, shim mode) ---
# .zshenv already put the shims on PATH, but exports.zsh re-prepends ~/.local/bin
# afterwards, where a manually-installed node lives, which would shadow the shim.
# tools.zsh is sourced after exports.zsh, so strip any existing entry and re-prepend
# here — that is what actually lets a project mise.toml win in interactive shells.
if [[ -d "$HOME/.local/share/mise/shims" ]]; then
  PATH="${PATH//$HOME\/.local\/share\/mise\/shims:/}"
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi
