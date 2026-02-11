#!/usr/bin/env bash
# bootstrap.sh - Idempotent WSL2 Ubuntu dev environment setup
# One command to transform a fresh WSL2 Ubuntu machine into a fully configured dev environment

# Exit on error for prerequisites check only
set -euo pipefail

#===============================================================================
# Global Configuration
#===============================================================================

DOTFILES_DIR="$HOME/.dotfiles"

# Detect GitHub repo from existing git remote, or use default
if [ -d "$DOTFILES_DIR/.git" ]; then
  GITHUB_REPO=$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||' || echo "")
fi
GITHUB_REPO="${GITHUB_REPO:-YOUR_GITHUB_USERNAME/dotfiles}"

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

#===============================================================================
# Dotfile Backup
#===============================================================================

backup_dotfiles() {
  section_header "Dotfile Backup"

  local backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
  local files_to_backup=(.zshrc .bashrc .profile .gitconfig .tmux.conf)
  local dirs_to_backup=(.config/zsh .config/tmux .config/starship.toml)
  local backed_up=0

  # Check files
  for file in "${files_to_backup[@]}"; do
    if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
      if [ $backed_up -eq 0 ]; then
        log_info "Backing up existing dotfiles to $backup_dir..."
        mkdir -p "$backup_dir"
        backed_up=1
      fi
      cp -aL "$HOME/$file" "$backup_dir/"
      log_info "Backed up: $file"
    fi
  done

  # Check directories
  for dir in "${dirs_to_backup[@]}"; do
    if [ -d "$HOME/$dir" ] && [ ! -L "$HOME/$dir" ]; then
      if [ $backed_up -eq 0 ]; then
        log_info "Backing up existing dotfiles to $backup_dir..."
        mkdir -p "$backup_dir"
        backed_up=1
      fi
      mkdir -p "$backup_dir/$(dirname "$dir")"
      cp -aL "$HOME/$dir" "$backup_dir/$dir"
      log_info "Backed up: $dir"
    fi
  done

  if [ $backed_up -eq 1 ]; then
    log_success "Dotfiles backed up to $backup_dir"
    INSTALLED+=("Dotfile backup")
  else
    log_skip "No existing dotfiles to backup"
    SKIPPED+=("Dotfile backup")
  fi
}

#===============================================================================
# Chezmoi Setup
#===============================================================================

setup_chezmoi() {
  section_header "Chezmoi Configuration"

  # Check if chezmoi is installed
  if ! command -v chezmoi &>/dev/null; then
    log_info "Installing chezmoi..."
    if sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin" >/dev/null 2>&1; then
      log_success "chezmoi installed"
      INSTALLED+=("chezmoi")
      # Ensure it's in PATH for this session
      export PATH="$HOME/.local/bin:$PATH"
    else
      log_error "chezmoi installation failed"
      FAILED_STEPS+=("chezmoi")
      return 1
    fi
  else
    log_skip "chezmoi already installed"
    SKIPPED+=("chezmoi")
  fi

  # Check if dotfiles repo already cloned
  if [ -d "$DOTFILES_DIR/.git" ]; then
    log_info "Dotfiles repo exists, running chezmoi apply..."
    if chezmoi init --apply --source "$DOTFILES_DIR" >/dev/null 2>&1; then
      log_success "chezmoi configurations applied"
      INSTALLED+=("chezmoi apply")
    else
      log_error "chezmoi apply failed"
      FAILED_STEPS+=("chezmoi apply")
      return 1
    fi
  else
    log_info "Cloning dotfiles repo from GitHub..."
    if git clone "https://github.com/$GITHUB_REPO.git" "$DOTFILES_DIR" >/dev/null 2>&1; then
      log_success "Dotfiles repo cloned"
      log_info "Running chezmoi init --apply..."
      if chezmoi init --apply --source "$DOTFILES_DIR" >/dev/null 2>&1; then
        log_success "chezmoi configurations applied"
        INSTALLED+=("chezmoi init + apply")
      else
        log_error "chezmoi apply failed"
        FAILED_STEPS+=("chezmoi apply")
        return 1
      fi
    else
      log_error "Failed to clone dotfiles repo"
      FAILED_STEPS+=("dotfiles clone")
      return 1
    fi
  fi

  # Check for age key
  if [ ! -f "$HOME/.config/age/keys.txt" ]; then
    echo ""
    echo "${YELLOW}⚠${RESET}  Age encryption key not found at ~/.config/age/keys.txt"
    echo "${YELLOW}   Encrypted files were skipped. Add the key and run 'chezmoi apply' again.${RESET}"
  fi
}

#===============================================================================
# Shell Change
#===============================================================================

change_default_shell() {
  section_header "Default Shell"

  local target_shell="/usr/bin/zsh"

  # Check if already using zsh
  if [ "$SHELL" = "$target_shell" ]; then
    log_skip "Shell already set to zsh"
    SKIPPED+=("Shell change")
    return 0
  fi

  # Verify zsh is in /etc/shells
  if ! grep -q "^$target_shell$" /etc/shells 2>/dev/null; then
    log_info "Adding zsh to /etc/shells..."
    echo "$target_shell" | sudo tee -a /etc/shells >/dev/null
  fi

  log_info "Changing default shell to zsh..."
  echo "${YELLOW}Note: You'll be prompted for your password${RESET}"

  # chsh requires interactive password
  if chsh -s "$target_shell"; then
    log_success "Default shell changed to zsh (takes effect on next login)"
    INSTALLED+=("zsh as default shell")
  else
    log_error "Failed to change default shell"
    FAILED_STEPS+=("Shell change")
    return 1
  fi
}

#===============================================================================
# SSH Key Setup
#===============================================================================

setup_ssh_keys() {
  section_header "SSH Keys"

  echo ""
  echo "${CYAN}SSH Key Setup${RESET}"
  echo "Enter path to existing SSH directory (e.g., /mnt/c/Users/YourName/.ssh)"
  echo "or press Enter to skip:"
  read -r ssh_source

  # Skip if user pressed Enter
  if [ -z "$ssh_source" ]; then
    log_skip "SSH key setup skipped"
    SKIPPED+=("SSH keys")
    return 0
  fi

  # Validate source directory exists
  if [ ! -d "$ssh_source" ]; then
    log_error "SSH source directory not found: $ssh_source"
    FAILED_STEPS+=("SSH keys")
    return 1
  fi

  log_info "Copying SSH keys from $ssh_source..."

  # Create .ssh directory with correct permissions
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # Copy all files
  if cp -r "$ssh_source"/* "$HOME/.ssh/" 2>/dev/null; then
    log_success "SSH keys copied"
  else
    log_error "Failed to copy SSH keys"
    FAILED_STEPS+=("SSH keys")
    return 1
  fi

  # Fix permissions
  log_info "Setting correct permissions..."
  chmod 700 "$HOME/.ssh"
  find "$HOME/.ssh" -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
  find "$HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true
  [ -f "$HOME/.ssh/config" ] && chmod 600 "$HOME/.ssh/config"
  [ -f "$HOME/.ssh/known_hosts" ] && chmod 644 "$HOME/.ssh/known_hosts"

  # Verify permissions
  local ssh_perms=$(stat -c '%a' "$HOME/.ssh" 2>/dev/null || echo "000")
  if [ "$ssh_perms" = "700" ]; then
    log_success "SSH keys configured with correct permissions (700/600/644)"
    INSTALLED+=("SSH keys")
  else
    log_error "SSH directory permissions incorrect: $ssh_perms (expected 700)"
    FAILED_STEPS+=("SSH key permissions")
    return 1
  fi
}

#===============================================================================
# Summary and Checklist
#===============================================================================

print_summary() {
  echo ""
  echo "${BOLD}${GREEN}═══════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}${GREEN}  Bootstrap Complete!${RESET}"
  echo "${BOLD}${GREEN}═══════════════════════════════════════════════════════${RESET}"
  echo ""

  # Print installed items
  if [ ${#INSTALLED[@]} -gt 0 ]; then
    echo "${BOLD}${GREEN}Installed:${RESET}"
    for item in "${INSTALLED[@]}"; do
      echo "  ${GREEN}✓${RESET} $item"
    done
    echo ""
  fi

  # Print skipped items
  if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo "${BOLD}${YELLOW}Skipped (already installed):${RESET}"
    for item in "${SKIPPED[@]}"; do
      echo "  ${YELLOW}⊘${RESET} $item"
    done
    echo ""
  fi

  # Print failed items
  if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
    echo "${BOLD}${RED}Failed:${RESET}"
    for item in "${FAILED_STEPS[@]}"; do
      echo "  ${RED}✗${RESET} $item"
    done
    echo ""
  fi

  # Post-install checklist
  echo "${BOLD}${CYAN}Post-Install Checklist:${RESET}"
  echo ""
  echo "  ${BOLD}1. Age Encryption Key${RESET}"
  echo "     Retrieve from Bitwarden and save to: ${CYAN}~/.config/age/keys.txt${RESET}"
  echo "     Then run: ${CYAN}chezmoi apply${RESET}"
  echo ""
  echo "  ${BOLD}2. GitHub Authentication${RESET}"
  echo "     Run: ${CYAN}gh auth login${RESET}"
  echo ""
  echo "  ${BOLD}3. Tmux Plugins${RESET}"
  echo "     Open tmux and press: ${CYAN}prefix + I${RESET} (Install plugins)"
  echo ""
  echo "  ${BOLD}4. Claude Code Authentication${RESET}"
  echo "     Run: ${CYAN}claude login${RESET}"
  echo ""
  echo "  ${BOLD}5. SSH Verification${RESET}"
  echo "     Test SSH keys: ${CYAN}ssh -T git@github.com${RESET}"
  echo ""
  echo "  ${BOLD}6. WSL Restart${RESET}"
  echo "     From PowerShell, run: ${CYAN}wsl.exe --shutdown${RESET}"
  echo "     Then restart WSL to enable systemd"
  echo ""
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
  echo "${BOLD}${CYAN}"
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║                                                               ║"
  echo "║           WSL2 Dev Environment Bootstrap                      ║"
  echo "║                                                               ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo "${RESET}"
  echo ""

  # Check prerequisites (under set -euo pipefail)
  check_prerequisites

  # Disable exit-on-error for main sections (continue-on-failure pattern)
  set +e

  # Run all sections via run_step
  run_step "WSL2 Configuration" configure_wsl
  run_step "APT Repository Setup" setup_apt_repos
  run_step "System Packages" install_apt_packages
  run_step "Binary Tools" install_binary_tools
  run_step "Plugin Managers" install_plugin_managers
  run_step "Python Tools" install_python_tools
  run_step "Node.js Tools" install_node_tools
  run_step "Dotfile Backup" backup_dotfiles
  run_step "Chezmoi Configuration" setup_chezmoi
  run_step "Default Shell" change_default_shell
  run_step "SSH Keys" setup_ssh_keys

  # Re-enable exit-on-error
  set -e

  # Print summary
  print_summary

  # Handle failures
  if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
    echo ""
    echo "${BOLD}${RED}═══════════════════════════════════════════════════════${RESET}"
    echo "${BOLD}${RED}  Some steps failed. See above for details.${RESET}"
    echo "${BOLD}${RED}═══════════════════════════════════════════════════════${RESET}"
    echo ""
    echo "Re-run this script to retry failed steps."
    exit 1
  fi

  # Auto-start zsh
  echo ""
  echo "${CYAN}Starting new zsh shell...${RESET}"
  exec zsh
}

# Execute main function
main "$@"
