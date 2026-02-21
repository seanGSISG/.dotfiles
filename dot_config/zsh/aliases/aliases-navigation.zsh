# Navigation Aliases
# Quick directory navigation shortcuts

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# ── Jump target registry ──────────────────────────────────────
# Shared between j() and jc(). Add new targets here.
typeset -A _jump_targets=(
  ccenter   "$HOME/command-center"
  projects  "$HOME/projects"
  labs      "$HOME/labs"
  models    "$HOME/models"
  tmp       "$HOME/tmp"
  tools     "$HOME/tools"
  dotfiles  "$HOME/projects/.dotfiles"
  config    "$HOME/.config"
)

# ── j() — jump to workspace ──────────────────────────────────
# Pure cd, no side effects.
j() {
  if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: j <target>"
    echo ""
    echo "Targets:"
    local key
    for key in ${(ko)_jump_targets}; do
      printf "  %-12s %s\n" "$key" "${_jump_targets[$key]/#$HOME/~}"
    done
    echo ""
    echo "See also: jc <target>  (jump + launch claude)"
    return 1
  fi

  local target="${_jump_targets[$1]}"
  if [[ -z "$target" ]]; then
    echo "j: unknown target '$1'" >&2
    echo "Run 'j' for available targets." >&2
    return 1
  fi

  if [[ ! -d "$target" ]]; then
    echo "j: directory not found: ${target/#$HOME/~}" >&2
    return 1
  fi

  cd "$target"
}

# ── jc() — jump + code (launch claude session) ───────────────
# cd to target, then launch claude --dangerously-skip-permissions.
jc() {
  if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: jc <target> [claude args...]"
    echo ""
    echo "Jump to workspace and launch claude --dangerously-skip-permissions."
    echo "Extra arguments are forwarded to claude."
    echo ""
    echo "Targets:"
    local key
    for key in ${(ko)_jump_targets}; do
      printf "  %-12s %s\n" "$key" "${_jump_targets[$key]/#$HOME/~}"
    done
    echo ""
    echo "Examples:"
    echo "  jc ccenter              # cd ~/command-center && claude"
    echo "  jc dotfiles --resume    # cd ~/.dotfiles && claude --resume"
    return 1
  fi

  local target_name="$1"
  shift

  local target="${_jump_targets[$target_name]}"
  if [[ -z "$target" ]]; then
    echo "jc: unknown target '$target_name'" >&2
    echo "Run 'jc' for available targets." >&2
    return 1
  fi

  if [[ ! -d "$target" ]]; then
    echo "jc: directory not found: ${target/#$HOME/~}" >&2
    return 1
  fi

  if ! command -v claude &>/dev/null; then
    echo "jc: 'claude' not found in PATH. Falling back to cd only." >&2
    cd "$target"
    return 1
  fi

  cd "$target" && claude --dangerously-skip-permissions "$@"
}

# ── Tab completion ────────────────────────────────────────────
_j_complete() { compadd ${(ko)_jump_targets}; }
compdef _j_complete j
compdef _j_complete jc

# ── Project launchers ─────────────────────────────────────────
prefect() {
  cd ~/projects/prefect-antig && uv sync && source .venv/bin/activate && claude --dangerously-skip-permissions
}
