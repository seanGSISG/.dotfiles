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

#===============================================================================
# Binary Tools Installation
#===============================================================================

install_binary_tools() {
  section_header "Binary Tools"

  # Ensure ~/.local/bin is in PATH for this session
  export PATH="$HOME/.local/bin:$PATH"

  # Starship prompt
  install_starship

  # fnm (Fast Node Manager)
  install_fnm

  # fzf (fuzzy finder)
  install_fzf

  # uv (Python package manager)
  install_uv

  # bun (JavaScript runtime)
  install_bun

  # age (encryption tool)
  install_age
}

install_starship() {
  if command -v starship &>/dev/null; then
    log_skip "Starship already installed"
    SKIPPED+=("Starship")
    return 0
  fi

  log_info "Installing Starship..."
  if curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir "$HOME/.local/bin" >/dev/null 2>&1; then
    log_success "Starship installed"
    INSTALLED+=("Starship")
  else
    log_error "Starship installation failed"
    FAILED_STEPS+=("Starship")
    return 1
  fi
}

install_fnm() {
  if command -v fnm &>/dev/null; then
    log_skip "fnm already installed"
    SKIPPED+=("fnm")
    return 0
  fi

  log_info "Installing fnm..."
  if curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell >/dev/null 2>&1; then
    log_success "fnm installed"
    INSTALLED+=("fnm")
  else
    log_error "fnm installation failed"
    FAILED_STEPS+=("fnm")
    return 1
  fi
}

install_fzf() {
  if command -v fzf &>/dev/null; then
    log_skip "fzf already installed"
    SKIPPED+=("fzf")
    return 0
  fi

  log_info "Installing fzf..."
  if [ -d "$HOME/.fzf" ]; then
    log_skip "fzf directory already exists"
    SKIPPED+=("fzf")
    return 0
  fi

  if git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" >/dev/null 2>&1 && \
     "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish >/dev/null 2>&1; then
    log_success "fzf installed"
    INSTALLED+=("fzf")
  else
    log_error "fzf installation failed"
    FAILED_STEPS+=("fzf")
    return 1
  fi
}

install_uv() {
  if command -v uv &>/dev/null; then
    log_skip "uv already installed"
    SKIPPED+=("uv")
    return 0
  fi

  log_info "Installing uv..."
  if curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1; then
    log_success "uv installed"
    INSTALLED+=("uv")
  else
    log_error "uv installation failed"
    FAILED_STEPS+=("uv")
    return 1
  fi
}

install_bun() {
  if command -v bun &>/dev/null; then
    log_skip "bun already installed"
    SKIPPED+=("bun")
    return 0
  fi

  log_info "Installing bun..."
  if curl -fsSL https://bun.sh/install | bash >/dev/null 2>&1; then
    log_success "bun installed"
    INSTALLED+=("bun")
  else
    log_error "bun installation failed"
    FAILED_STEPS+=("bun")
    return 1
  fi
}

install_age() {
  if command -v age &>/dev/null; then
    log_skip "age already installed"
    SKIPPED+=("age")
    return 0
  fi

  # Check if age is available in apt repositories
  log_info "Installing age..."
  if sudo apt-get install -y -qq age >/dev/null 2>&1; then
    log_success "age installed"
    INSTALLED+=("age")
  else
    # Fallback to GitHub release if apt install fails
    log_info "Installing age from GitHub releases..."
    local age_version="v1.2.1"
    local age_url="https://github.com/FiloSottile/age/releases/download/${age_version}/age-${age_version}-linux-amd64.tar.gz"

    if curl -fsSL "$age_url" | tar -xz -C /tmp && \
       cp /tmp/age/age /tmp/age/age-keygen "$HOME/.local/bin/" && \
       chmod +x "$HOME/.local/bin/age" "$HOME/.local/bin/age-keygen"; then
      log_success "age installed from GitHub releases"
      INSTALLED+=("age")
      rm -rf /tmp/age
    else
      log_error "age installation failed"
      FAILED_STEPS+=("age")
      return 1
    fi
  fi
}

#===============================================================================
# Plugin Manager Installation
#===============================================================================

install_plugin_managers() {
  section_header "Plugin Managers"

  # antidote (zsh plugin manager)
  install_antidote

  # TPM note (managed by chezmoi)
  log_info "TPM (Tmux Plugin Manager) will be installed via chezmoi .chezmoiexternal.toml"
}

install_antidote() {
  if [ -d "$HOME/.antidote" ]; then
    log_skip "antidote already installed"
    SKIPPED+=("antidote")
    return 0
  fi

  log_info "Installing antidote..."
  if git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote" >/dev/null 2>&1; then
    log_success "antidote installed"
    INSTALLED+=("antidote")
  else
    log_error "antidote installation failed"
    FAILED_STEPS+=("antidote")
    return 1
  fi
}

#===============================================================================
# Python Tools Installation
#===============================================================================

install_python_tools() {
  section_header "Python Tools"

  # Verify uv is available
  if ! command -v uv &>/dev/null; then
    log_error "uv not found - Python tools installation skipped"
    FAILED_STEPS+=("Python tools (uv required)")
    return 1
  fi

  # Ensure uv is in PATH for this session
  export PATH="$HOME/.local/bin:$PATH"

  local tools_file="$DOTFILES_DIR/packages/uv-tools.txt"

  if [ ! -f "$tools_file" ]; then
    log_error "Tools list not found: $tools_file"
    return 1
  fi

  # Read tools (ignore comments and empty lines)
  local tools=()
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue

    # Extract tool name
    local tool=$(echo "$line" | xargs)
    [[ -n "$tool" ]] && tools+=("$tool")
  done < "$tools_file"

  local installed=0
  local skipped=0

  for tool in "${tools[@]}"; do
    # Check if tool is already installed
    if uv tool list 2>/dev/null | grep -q "^$tool "; then
      log_skip "$tool already installed"
      SKIPPED+=("$tool")
      ((skipped++))
    else
      log_info "Installing $tool..."
      if uv tool install "$tool" >/dev/null 2>&1; then
        log_success "$tool installed"
        INSTALLED+=("$tool")
        ((installed++))
      else
        log_error "$tool installation failed"
        FAILED_STEPS+=("Python tool: $tool")
      fi
    fi
  done

  echo ""
  log_success "Python tools: $installed installed, $skipped skipped"
}

#===============================================================================
# Node.js and JavaScript Tools Installation
#===============================================================================

install_node_tools() {
  section_header "Node.js & JavaScript Tools"

  # Verify fnm is available
  if ! command -v fnm &>/dev/null; then
    log_error "fnm not found - Node.js tools installation skipped"
    FAILED_STEPS+=("Node.js tools (fnm required)")
    return 1
  fi

  # Source fnm into current shell
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env --use-on-cd)" 2>/dev/null || true

  # Check if Node LTS is already installed
  if fnm list 2>/dev/null | grep -q "22"; then
    log_skip "Node.js 22 (LTS) already installed"
    SKIPPED+=("Node.js 22")
  else
    log_info "Installing Node.js 22 (LTS)..."
    if fnm install 22 >/dev/null 2>&1 && fnm default 22 >/dev/null 2>&1; then
      log_success "Node.js 22 (LTS) installed"
      INSTALLED+=("Node.js 22")
    else
      log_error "Node.js installation failed"
      FAILED_STEPS+=("Node.js 22")
      return 1
    fi
  fi

  # Install Claude Code
  install_claude_code
}

install_claude_code() {
  # Refresh PATH after Node installation
  eval "$(fnm env --use-on-cd)" 2>/dev/null || true

  if command -v claude &>/dev/null; then
    log_skip "Claude Code already installed"
    SKIPPED+=("Claude Code")
    return 0
  fi

  log_info "Installing Claude Code..."

  # Prefer bun if available, fallback to npm
  if command -v bun &>/dev/null; then
    if bun install -g @anthropic-ai/claude-code >/dev/null 2>&1; then
      log_success "Claude Code installed (via bun)"
      INSTALLED+=("Claude Code")
    else
      log_error "Claude Code installation failed"
      FAILED_STEPS+=("Claude Code")
      return 1
    fi
  elif command -v npm &>/dev/null; then
    if npm install -g @anthropic-ai/claude-code >/dev/null 2>&1; then
      log_success "Claude Code installed (via npm)"
      INSTALLED+=("Claude Code")
    else
      log_error "Claude Code installation failed"
      FAILED_STEPS+=("Claude Code")
      return 1
    fi
  else
    log_error "Neither bun nor npm available - Claude Code installation skipped"
    FAILED_STEPS+=("Claude Code (bun/npm required)")
    return 1
  fi
}
