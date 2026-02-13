#!/usr/bin/env bash
# verify.sh - Validate WSL2 dev environment setup
# Run after bootstrap.sh or anytime to check environment health

set -euo pipefail

#===============================================================================
# Colors and Formatting
#===============================================================================

RED=$(tput setaf 1 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
YELLOW=$(tput setaf 3 2>/dev/null || echo "")
BLUE=$(tput setaf 4 2>/dev/null || echo "")
MAGENTA=$(tput setaf 5 2>/dev/null || echo "")
CYAN=$(tput setaf 6 2>/dev/null || echo "")
BOLD=$(tput bold 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")

#===============================================================================
# Counters
#===============================================================================

PASSED=0
FAILED=0
WARNINGS=0

#===============================================================================
# Check Functions
#===============================================================================

check_pass() {
  echo "${GREEN}  ✓${RESET} $1"
  PASSED=$((PASSED + 1))
}

check_fail() {
  echo "${RED}  ✗${RESET} $1"
  FAILED=$((FAILED + 1))
}

check_warn() {
  echo "${YELLOW}  ⚠${RESET} $1"
  WARNINGS=$((WARNINGS + 1))
}

section_header() {
  echo ""
  echo "${BOLD}${CYAN}$1${RESET}"
  echo "${CYAN}────────────────────────────────────────────────────────${RESET}"
}

#===============================================================================
# Verification Checks
#===============================================================================

verify_shell_config() {
  section_header "1. Shell Configuration"

  # Default shell is zsh
  if [ "$SHELL" = "/usr/bin/zsh" ]; then
    check_pass "Default shell is zsh"
  else
    check_fail "Default shell is not zsh (current: $SHELL)"
  fi

  # .zshenv exists (sets ZDOTDIR)
  if [ -f ~/.zshenv ]; then
    check_pass ".zshenv exists"
  else
    check_fail ".zshenv not found"
  fi

  # .zshrc exists in ZDOTDIR
  if [ -f ~/.config/zsh/.zshrc ]; then
    check_pass ".config/zsh/.zshrc exists"
  else
    check_fail "~/.config/zsh/.zshrc not found"
  fi

  # Zsh config directory exists
  if [ -d ~/.config/zsh ]; then
    check_pass "Zsh config directory exists"
  else
    check_fail "~/.config/zsh not found"
  fi

  # Antidote installed
  if [ -d ~/.antidote ]; then
    check_pass "antidote installed"
  else
    check_fail "antidote not found"
  fi
}

verify_tools() {
  section_header "2. Tools on PATH"

  local tools=(
    chezmoi
    starship
    fnm
    fzf
    zoxide
    uv
    bun
    gh
    tmux
    git
    age
    claude
    opencode
  )

  for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      check_pass "$tool"
    else
      check_fail "$tool not found"
    fi
  done
}

verify_config_files() {
  section_header "3. Config Files Deployed"

  local files=(
    ~/.zshenv
    ~/.config/zsh/.zshrc
    ~/.bashrc
    ~/.profile
    ~/.gitconfig
    ~/.config/zsh/exports.zsh
    ~/.config/zsh/plugins.zsh
    ~/.config/zsh/tools.zsh
    ~/.config/starship.toml
    ~/.config/tmux/tmux.conf
  )

  for file in "${files[@]}"; do
    if [ -f "$file" ]; then
      check_pass "$(basename "$file")"
    else
      check_fail "$(basename "$file") not found"
    fi
  done

  # Aliases directory
  if [ -d ~/.config/zsh/aliases ]; then
    check_pass "aliases/ directory exists"
  else
    check_fail "aliases/ directory not found"
  fi
}

verify_ssh_keys() {
  section_header "4. SSH Keys"

  # ~/.ssh/ directory exists with 700 permissions
  if [ -d ~/.ssh ]; then
    local perms=$(stat -c %a ~/.ssh 2>/dev/null || stat -f %OLp ~/.ssh 2>/dev/null)
    if [ "$perms" = "700" ]; then
      check_pass "~/.ssh/ directory exists with correct permissions (700)"
    else
      check_warn "~/.ssh/ exists but permissions are $perms (expected 700)"
    fi
  else
    check_fail "~/.ssh/ directory not found"
  fi

  # SSH private key exists
  if [ -f ~/.ssh/idm-prod-key ]; then
    check_pass "SSH private key exists (idm-prod-key)"

    # Check private key permissions
    local key_perms=$(stat -c %a ~/.ssh/idm-prod-key 2>/dev/null || stat -f %OLp ~/.ssh/idm-prod-key 2>/dev/null)
    if [ "$key_perms" = "600" ]; then
      check_pass "SSH private key permissions correct (600)"
    else
      check_warn "SSH private key permissions are $key_perms (expected 600)"
    fi
  else
    check_fail "SSH private key not found (idm-prod-key)"
  fi

  # SSH public key exists
  if [ -f ~/.ssh/idm-prod-key.pub ]; then
    check_pass "SSH public key exists"
  else
    check_fail "SSH public key not found (idm-prod-key.pub)"
  fi
}

verify_secrets() {
  section_header "5. Secrets & Encryption"

  # Age key exists
  if [ -f ~/.config/age/keys.txt ]; then
    check_pass "Age key exists"
  else
    check_fail "Age key not found (~/.config/age/keys.txt)"
  fi

  # Secrets file exists
  if [ -f ~/.secrets.env ]; then
    check_pass "Secrets file exists"
  else
    check_fail "Secrets file not found (~/.secrets.env)"
  fi

  # GitHub CLI authenticated
  if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
    check_pass "GitHub CLI authenticated"
  else
    check_fail "GitHub CLI not authenticated (gh auth status failed)"
  fi
}

verify_wsl_config() {
  section_header "6. WSL2 Configuration"

  # /etc/wsl.conf exists with systemd=true
  if [ -f /etc/wsl.conf ]; then
    if grep -q 'systemd=true' /etc/wsl.conf 2>/dev/null; then
      check_pass "/etc/wsl.conf configured with systemd=true"
    else
      check_fail "/etc/wsl.conf exists but systemd=true not found"
    fi
  else
    check_fail "/etc/wsl.conf not found"
  fi
}

verify_workspace_folders() {
  section_header "7. Workspace Folders"

  local folders=(
    ~/projects
    ~/labs
    ~/tools
    ~/tmp
    ~/command-center
  )

  for folder in "${folders[@]}"; do
    if [ -d "$folder" ]; then
      check_pass "$(basename "$folder")/"
    else
      check_fail "$(basename "$folder")/ not found"
    fi
  done
}

verify_claude_code() {
  section_header "8. Claude Code"

  # claude command available
  if command -v claude &>/dev/null; then
    check_pass "claude command available"
  else
    check_fail "claude command not found"
  fi

  # ~/.claude/ directory exists
  if [ -d ~/.claude ]; then
    check_pass "~/.claude/ directory exists"
  else
    check_fail "~/.claude/ directory not found"
  fi

  # hooks.json exists
  if [ -f ~/.claude/hooks.json ]; then
    check_pass "hooks.json exists"
  else
    check_fail "hooks.json not found"
  fi
}

#===============================================================================
# Summary
#===============================================================================

print_summary() {
  local total=$((PASSED + FAILED + WARNINGS))

  echo ""
  echo "${BOLD}${MAGENTA}═══════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}${MAGENTA}  Verification Summary${RESET}"
  echo "${BOLD}${MAGENTA}═══════════════════════════════════════════════════════${RESET}"
  echo ""
  echo "  ${GREEN}Passed:${RESET}   $PASSED"
  echo "  ${RED}Failed:${RESET}   $FAILED"
  echo "  ${YELLOW}Warnings:${RESET} $WARNINGS"
  echo "  Total:    $total"
  echo ""

  if [ $FAILED -eq 0 ]; then
    echo "  ${GREEN}✓${RESET} Environment is ${BOLD}${GREEN}ready${RESET}"
  else
    echo "  ${RED}✗${RESET} Environment is ${BOLD}${RED}not ready${RESET}"
  fi
  echo ""
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
  echo "${BOLD}${CYAN}"
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║                                                               ║"
  echo "║           Environment Verification                            ║"
  echo "║                                                               ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo "${RESET}"

  # Run all verification checks
  verify_shell_config
  verify_tools
  verify_config_files
  verify_ssh_keys
  verify_secrets
  verify_wsl_config
  verify_workspace_folders
  verify_claude_code

  # Print summary
  print_summary

  # Exit with appropriate code
  if [ $FAILED -gt 0 ]; then
    exit 1
  else
    exit 0
  fi
}

# Execute main function
main "$@"
