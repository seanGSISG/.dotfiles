#!/usr/bin/env bash
# bootstrap.sh - Idempotent WSL2 Ubuntu dev environment setup
# One command to transform a fresh WSL2 Ubuntu machine into a fully configured dev environment

# Exit on error for prerequisites check only
set -euo pipefail

#===============================================================================
# Global Configuration
#===============================================================================

DOTFILES_DIR="$HOME/.dotfiles"

#===============================================================================
# Colors and Formatting
#===============================================================================

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

#===============================================================================
# Logging Functions
#===============================================================================

log_info() {
  echo "${BLUE}▶${RESET} $1"
}

log_success() {
  echo "${GREEN}✓${RESET} $1"
}

log_skip() {
  echo "${YELLOW}⊘${RESET} $1 ${YELLOW}(skipped)${RESET}"
}

log_error() {
  echo "${RED}✗${RESET} $1" >&2
}

section_header() {
  echo ""
  echo "${BOLD}${MAGENTA}═══════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}${MAGENTA}  $1${RESET}"
  echo "${BOLD}${MAGENTA}═══════════════════════════════════════════════════════${RESET}"
  echo ""
}

#===============================================================================
# Error Tracking
#===============================================================================

FAILED_STEPS=()
INSTALLED=()
SKIPPED=()

run_step() {
  local step_name="$1"
  shift

  if "$@"; then
    return 0
  else
    log_error "$step_name failed"
    FAILED_STEPS+=("$step_name")
    return 1
  fi
}

#===============================================================================
# Prerequisites Check
#===============================================================================

check_prerequisites() {
  section_header "Checking Prerequisites"

  local missing=0
  for cmd in curl git sudo; do
    if command -v "$cmd" &>/dev/null; then
      log_success "$cmd available"
    else
      log_error "$cmd not found"
      missing=1
    fi
  done

  if [ $missing -eq 1 ]; then
    echo ""
    log_error "Missing required prerequisites. Install them and retry."
    exit 1
  fi

  log_success "All prerequisites available"
}

#===============================================================================
# System Configuration
#===============================================================================

configure_wsl() {
  section_header "WSL2 Configuration"

  local wsl_conf="/etc/wsl.conf"

  # Check if already configured
  if grep -q "systemd=true" "$wsl_conf" 2>/dev/null; then
    log_skip "WSL2 already configured with systemd"
    SKIPPED+=("WSL2 configuration")
    return 0
  fi

  log_info "Configuring /etc/wsl.conf with systemd support..."

  # Create/update wsl.conf
  sudo tee "$wsl_conf" > /dev/null <<'EOF'
[boot]
systemd=true

[interop]
enabled=true
appendWindowsPath=true
EOF

  log_success "/etc/wsl.conf configured (WSL restart required: wsl.exe --shutdown)"
  INSTALLED+=("WSL2 configuration")
}

#===============================================================================
# APT Repository Setup
#===============================================================================

setup_apt_repos() {
  section_header "APT Repository Setup"

  local repos_added=0

  # GitHub CLI repository
  if [ -f /etc/apt/sources.list.d/github-cli.list ]; then
    log_skip "GitHub CLI repository already configured"
  else
    log_info "Adding GitHub CLI repository..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    log_success "GitHub CLI repository added"
    repos_added=1
  fi

  # PowerShell repository
  if [ -f /etc/apt/sources.list.d/microsoft-prod.list ] || dpkg -l | grep -q "^ii.*powershell"; then
    log_skip "PowerShell repository already configured or PowerShell already installed"
  else
    log_info "Adding PowerShell repository..."
    # Download Microsoft repository GPG keys
    wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    log_success "PowerShell repository added"
    repos_added=1
  fi

  # Update package cache if repos were added
  if [ $repos_added -eq 1 ]; then
    log_info "Updating package cache..."
    sudo apt-get update -qq
    log_success "Package cache updated"
  else
    log_skip "No new repositories to add"
  fi
}

#===============================================================================
# APT Package Installation
#===============================================================================

install_apt_packages() {
  section_header "Installing System Packages"

  log_info "Updating package cache..."
  sudo apt-get update -qq

  local packages_file="$DOTFILES_DIR/packages/apt-packages.txt"

  if [ ! -f "$packages_file" ]; then
    log_error "Package list not found: $packages_file"
    return 1
  fi

  # Read packages (ignore comments, empty lines, strip version constraints and trailing comments)
  local packages=()
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue

    # Extract package name (everything before # or >= or whitespace)
    local pkg=$(echo "$line" | sed -E 's/[[:space:]]*#.*$//' | sed -E 's/>=[^[:space:]]*//' | xargs)
    [[ -n "$pkg" ]] && packages+=("$pkg")
  done < "$packages_file"

  local installed=0
  local skipped=0

  for pkg in "${packages[@]}"; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
      log_skip "$pkg already installed"
      SKIPPED+=("$pkg")
      ((skipped++))
    else
      log_info "Installing $pkg..."
      if sudo apt-get install -y -qq "$pkg" 2>&1 | grep -v "^debconf:"; then
        log_success "$pkg installed"
        INSTALLED+=("$pkg")
        ((installed++))
      else
        log_error "$pkg installation failed"
        FAILED_STEPS+=("apt package: $pkg")
      fi
    fi
  done

  echo ""
  log_success "APT packages: $installed installed, $skipped skipped"
}
