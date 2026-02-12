# Shell Functions
# Reusable functions for zsh/bash

# ============================================
# Section 1: Alias Help System
# ============================================

alias-help() {
  local bold=$'\033[1m' dim=$'\033[2m'
  local blue=$'\033[34m' yellow=$'\033[33m' cyan=$'\033[36m'
  local magenta=$'\033[35m' reset=$'\033[0m'
  local line name value category count dashes header_lines pending_section
  local total_width=48

  echo ""
  printf " ${bold}${blue}╭──────────────────────────────────────────────╮${reset}\n"
  printf " ${bold}${blue}│${reset}               ${bold}Shell Cheatsheet${reset}               ${bold}${blue}│${reset}\n"
  printf " ${bold}${blue}╰──────────────────────────────────────────────╯${reset}\n"

  for category_file in "$HOME/.config/zsh/aliases"/aliases-*.zsh; do
    [ -r "$category_file" ] || continue
    category=$(basename "$category_file" .zsh | sed 's/aliases-//' | tr '[:lower:]' '[:upper:]')
    count=$(grep -c "^alias " "$category_file" 2>/dev/null || echo 0)

    dashes=$(printf '%*s' "$(( total_width - ${#category} - 2 ))" '' | tr ' ' '─')

    echo ""
    printf " ${bold}${yellow}%s${reset} ${dim}%s${reset} ${dim}(%d)${reset}\n" "$category" "$dashes" "$count"

    header_lines=0
    pending_section=""
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue

      # Skip the first 2 comment lines (file header)
      if [[ "$line" == \#* ]] && (( header_lines < 2 )); then
        (( header_lines++ ))
        continue
      fi

      # Sub-section comment (buffer it, only print if aliases follow)
      if [[ "$line" == \#\ * ]]; then
        pending_section="${line#\# }"
        continue
      fi

      # Skip non-alias lines (functions, etc.)
      [[ "$line" != alias\ * ]] && continue

      # Print buffered sub-section header
      if [[ -n "$pending_section" ]]; then
        printf "\n   ${magenta}%s${reset}\n" "$pending_section"
        pending_section=""
      fi

      # Parse alias name and value
      name="${line#alias }"
      name="${name%%=*}"
      value="${line#*=}"
      value="${value#\'}" ; value="${value%\'}"
      value="${value#\"}" ; value="${value%\"}"

      printf "   ${cyan}%-16s${reset} ${dim}%s${reset}\n" "$name" "$value"
    done < "$category_file"
  done

  echo ""
  dashes=$(printf '%*s' "$(( total_width - 17 ))" '' | tr ' ' '─')
  printf " ${bold}${yellow}QUICK REFERENCE${reset} ${dim}%s${reset}\n\n" "$dashes"
  printf "   ${cyan}%-16s${reset} ${dim}%s${reset}\n" "j <name>" "Jump to workspace (ccenter, labs, ...)"
  printf "   ${cyan}%-16s${reset} ${dim}%s${reset}\n" "z <query>" "Jump to directory (zoxide)"
  printf "   ${cyan}%-16s${reset} ${dim}%s${reset}\n" "Ctrl+R" "Fuzzy search history (fzf)"
  printf "   ${cyan}%-16s${reset} ${dim}%s${reset}\n" "Ctrl+T" "Fuzzy find files (fzf)"
  printf "   ${cyan}%-16s${reset} ${dim}%s${reset}\n" "Alt+C" "Fuzzy cd into subdirs (fzf)"
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
