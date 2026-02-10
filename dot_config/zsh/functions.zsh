# Shell Functions
# Reusable functions for zsh/bash

# ============================================
# Section 1: Alias Help System
# ============================================

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

alias-help() {
  printf "\n${BLUE}%s${RESET}\n" "======================================="
  printf "${GREEN}%s${RESET}\n" "  Available Aliases"
  printf "${BLUE}%s${RESET}\n\n" "======================================="

  for category_file in "$HOME/.config/zsh/aliases"/aliases-*.zsh; do
    [ -r "$category_file" ] || continue
    local category
    category=$(basename "$category_file" .zsh | sed 's/aliases-//' | tr '[:lower:]' '[:upper:]')
    printf "${YELLOW}>>> %s${RESET}\n" "$category"

    grep "^alias " "$category_file" | while IFS= read -r line; do
      local name value
      name=$(echo "$line" | sed "s/^alias //" | cut -d= -f1)
      value=$(echo "$line" | cut -d= -f2- | sed "s/^'//" | sed "s/'$//" | sed 's/^"//' | sed 's/"$//')
      printf "  ${CYAN}%-16s${RESET} %s\n" "$name" "$value"
    done
    echo ""
  done

  printf "${YELLOW}>>> %s${RESET}\n" "QUICK REFERENCE"
  printf "  ${CYAN}%-16s${RESET} %s\n" "z <query>" "Jump to directory (zoxide)"
  printf "  ${CYAN}%-16s${RESET} %s\n" "Ctrl+R" "Fuzzy search history (fzf)"
  printf "  ${CYAN}%-16s${RESET} %s\n" "Ctrl+T" "Fuzzy find files (fzf)"
  printf "  ${CYAN}%-16s${RESET} %s\n" "Alt+C" "Fuzzy cd into subdirs (fzf)"
  echo ""
}

alias '?'='alias-help'
alias halp='alias-help'

# ============================================
# Section 2: Navigation Functions
# ============================================

mkcd() { mkdir -p "$1" && cd "$1"; }

# ============================================
# Section 3: Utility Functions
# ============================================

cheat() { curl -s "cheat.sh/$1"; }

reload() {
  if [ -n "$ZSH_VERSION" ]; then
    source "$HOME/.zshrc"
  elif [ -n "$BASH_VERSION" ]; then
    source "$HOME/.bashrc"
  fi
}

# ============================================
# Section 4: Azure Key Vault Functions
# ============================================

az-secret() {
  local vault="${AZ_KEYVAULT:-kv-idm-webapp-prod}"
  if [ -z "$1" ]; then
    echo "Usage: az-secret <secret-name> [vault-name]"
    echo "Default vault: $vault (set AZ_KEYVAULT to change)"
    return 1
  fi
  [ -n "$2" ] && vault="$2"
  az keyvault secret show --vault-name "$vault" --name "$1" --query "value" -o tsv
}

az-secrets-list() {
  local vault="${AZ_KEYVAULT:-kv-idm-webapp-prod}"
  [ -n "$1" ] && vault="$1"
  az keyvault secret list --vault-name "$vault" -o table
}

# ============================================
# Section 5: WezTerm + Claude Functions
# ============================================

cct() {
  local prompt="$*"
  if [ -n "$prompt" ]; then
    wezterm.exe cli spawn --cwd "$(pwd)" -- bash -lc "claude --dangerously-skip-permissions \"$prompt\""
  else
    wezterm.exe cli spawn --cwd "$(pwd)" -- bash -lc "claude --dangerously-skip-permissions"
  fi
}

ccr() {
  local prompt="$*"
  if [ -n "$prompt" ]; then
    wezterm.exe cli split-pane --right --cwd "$(pwd)" -- bash -lc "claude --dangerously-skip-permissions \"$prompt\""
  else
    wezterm.exe cli split-pane --right --cwd "$(pwd)" -- bash -lc "claude --dangerously-skip-permissions"
  fi
}

ccb() {
  local prompt="$*"
  if [ -n "$prompt" ]; then
    wezterm.exe cli split-pane --bottom --cwd "$(pwd)" -- bash -lc "claude --dangerously-skip-permissions \"$prompt\""
  else
    wezterm.exe cli split-pane --bottom --cwd "$(pwd)" -- bash -lc "claude --dangerously-skip-permissions"
  fi
}

# ============================================
# Section 6: Tmux + Claude Functions
# ============================================

ccv() { tmux split-window -h "claude --dangerously-skip-permissions $*"; }
cch() { tmux split-window -v "claude --dangerously-skip-permissions $*"; }
