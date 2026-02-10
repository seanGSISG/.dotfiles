# Tool integrations
# Each tool is loaded only if available (graceful on fresh machines)

# --- fnm (Fast Node Manager) ---
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

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
