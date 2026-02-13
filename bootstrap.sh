#!/usr/bin/env bash
# bootstrap.sh - Idempotent WSL2 Ubuntu dev environment setup
# One command to transform a fresh WSL2 Ubuntu machine into a fully configured dev environment
#
# Output is logged to: ~/.dotfiles-bootstrap-YYYYMMDD_HHMMSS.log
# Both screen output and log file are updated simultaneously via tee

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
GITHUB_REPO="${GITHUB_REPO:-seanGSISG/.dotfiles}"

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

  # Charm repository (for glow)
  if [ -f /etc/apt/sources.list.d/charm.list ]; then
    log_skip "Charm repository already configured"
  else
    log_info "Adding Charm repository (for glow)..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
    log_success "Charm repository added"
    repos_added=1
  fi

  # Always update package cache (needed for fresh machines and after repo additions)
  log_info "Updating package cache..."
  sudo apt-get update -qq
  log_success "Package cache updated"
}

#===============================================================================
# APT Package Installation
#===============================================================================

install_apt_packages() {
  section_header "Installing System Packages"

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
      if sudo apt-get install -y -qq "$pkg" >/dev/null 2>&1; then
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

  # Ensure ~/.local/bin exists and is in PATH for this session
  mkdir -p "$HOME/.local/bin"
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
  local tmp
  tmp=$(mktemp)
  if curl -sS https://starship.rs/install.sh -o "$tmp" && \
     sh "$tmp" -y --bin-dir "$HOME/.local/bin" </dev/null >/dev/null 2>&1; then
    rm -f "$tmp"
    log_success "Starship installed"
    INSTALLED+=("Starship")
  else
    rm -f "$tmp"
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
  if bash -c "$(curl -fsSL https://fnm.vercel.app/install)" -- --skip-shell </dev/null >/dev/null 2>&1; then
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
  if bash -c "$(curl -LsSf https://astral.sh/uv/install.sh)" </dev/null >/dev/null 2>&1; then
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
  if bash -c "$(curl -fsSL https://bun.sh/install)" </dev/null >/dev/null 2>&1; then
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

  # TPM (Tmux Plugin Manager) — cloned here instead of via chezmoi externals
  # to avoid hanging on slow git clones during bootstrap
  install_tpm
}

install_tpm() {
  local tpm_dir="$HOME/.config/tmux/plugins/tpm"

  if [ -d "$tpm_dir" ]; then
    log_skip "TPM already installed"
    SKIPPED+=("TPM")
    return 0
  fi

  log_info "Installing TPM (Tmux Plugin Manager)..."
  mkdir -p "$(dirname "$tpm_dir")"
  if timeout 30 git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir" </dev/null >/dev/null 2>&1; then
    log_success "TPM installed"
    INSTALLED+=("TPM")
    # Install plugins headlessly (no tmux session needed)
    if [ -x "$tpm_dir/bin/install_plugins" ]; then
      log_info "Installing tmux plugins..."
      if timeout 60 "$tpm_dir/bin/install_plugins" >/dev/null 2>&1; then
        log_success "Tmux plugins installed"
        INSTALLED+=("tmux plugins")
      else
        log_error "Tmux plugin install failed (run Ctrl-b Shift-I in tmux)"
      fi
    fi
  else
    log_error "TPM installation timed out or failed"
    log_info "Install manually: git clone https://github.com/tmux-plugins/tpm $tpm_dir"
    FAILED_STEPS+=("TPM")
    return 1
  fi
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

    # Extract tool name (strip inline comments)
    local tool=$(echo "$line" | sed -E 's/[[:space:]]*#.*$//' | xargs)
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

  # Ensure fnm is on PATH (installs to ~/.local/share/fnm by default)
  export PATH="$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"

  # Verify fnm is available
  if ! command -v fnm &>/dev/null; then
    log_error "fnm not found - Node.js tools installation skipped"
    FAILED_STEPS+=("Node.js tools (fnm required)")
    return 1
  fi

  # Check if Node LTS is already installed
  if fnm list 2>/dev/null | grep -q "22"; then
    log_skip "Node.js 22 (LTS) already installed"
    SKIPPED+=("Node.js 22")
  else
    log_info "Installing Node.js 22 (LTS)..."
    if fnm install 22 >/dev/null 2>&1; then
      log_success "Node.js 22 (LTS) installed"
      INSTALLED+=("Node.js 22")
    else
      log_error "Node.js installation failed"
      FAILED_STEPS+=("Node.js 22")
      return 1
    fi
  fi

  # Always ensure default is set, THEN activate so node is on PATH
  fnm default 22 >/dev/null 2>&1 || true
  eval "$(fnm env --use-on-cd)" 2>/dev/null || true
}

install_claude_code() {
  if command -v claude &>/dev/null; then
    log_skip "Claude Code already installed"
    SKIPPED+=("Claude Code")
    return 0
  fi

  log_info "Installing Claude Code via official installer..."
  if bash -c "$(curl -fsSL https://claude.ai/install.sh)" </dev/null >/dev/null 2>&1; then
    log_success "Claude Code installed"
    INSTALLED+=("Claude Code")
  else
    log_error "Claude Code installation failed"
    FAILED_STEPS+=("Claude Code")
    return 1
  fi
}

install_opencode() {
  if command -v opencode &>/dev/null; then
    log_skip "OpenCode already installed"
    SKIPPED+=("OpenCode")
    return 0
  fi

  log_info "Installing OpenCode via official installer..."
  if curl -fsSL https://opencode.ai/install | bash </dev/null >/dev/null 2>&1; then
    log_success "OpenCode installed"
    INSTALLED+=("OpenCode")
  else
    log_error "OpenCode installation failed"
    FAILED_STEPS+=("OpenCode")
    return 1
  fi
}

#===============================================================================
# Dotfile Backup
#===============================================================================

backup_dotfiles() {
  section_header "Dotfile Backup"

  local backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
  local files_to_backup=(.zshenv .zshrc .bashrc .profile .gitconfig .tmux.conf)
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

install_chezmoi() {
  section_header "Chezmoi Installation"

  # Ensure install directory exists
  mkdir -p "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"

  # Check if chezmoi is installed
  if ! command -v chezmoi &>/dev/null; then
    log_info "Installing chezmoi..."
    if bash -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin" </dev/null >/dev/null 2>&1; then
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
  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    log_info "Cloning dotfiles repo from GitHub..."

    # Public repo — no auth needed for clone
    if git clone "https://github.com/$GITHUB_REPO.git" "$DOTFILES_DIR" </dev/null >/dev/null 2>&1; then
      log_success "Dotfiles repo cloned"
      INSTALLED+=("dotfiles clone")
    else
      log_error "Failed to clone dotfiles repo"
      log_error "Clone manually: git clone https://github.com/$GITHUB_REPO.git $DOTFILES_DIR"
      FAILED_STEPS+=("dotfiles clone")
      return 1
    fi
  else
    # Pull latest changes so chezmoi apply uses current source
    log_info "Updating dotfiles repo..."
    if git -C "$DOTFILES_DIR" pull --ff-only origin main </dev/null >/dev/null 2>&1; then
      log_success "Dotfiles repo updated"
      INSTALLED+=("dotfiles update")
    else
      log_skip "Dotfiles repo already exists (pull skipped — may be offline or have local changes)"
      SKIPPED+=("dotfiles clone")
    fi
  fi
}

setup_age_key() {
  section_header "Age Encryption Key"

  # Check if age key already exists
  if [ -f "$HOME/.config/age/keys.txt" ]; then
    log_skip "Age key already exists"
    SKIPPED+=("Age key")
    return 0
  fi

  echo ""
  echo "${CYAN}Age encryption key is required to decrypt secrets and SSH keys.${RESET}"
  echo "Your age key is stored in Bitwarden (search: 'age encryption key')"
  echo ""
  echo "Paste your age secret key (starts with AGE-SECRET-KEY-1...)"
  echo "or press Enter to skip:"
  read -r age_key </dev/tty || age_key=""

  # Skip if user pressed Enter
  if [ -z "$age_key" ]; then
    log_skip "Age key setup skipped — encrypted files will not be decrypted"
    echo ""
    echo "${YELLOW}⚠${RESET}  Encrypted files (secrets, SSH keys) will be skipped during chezmoi apply."
    echo "${YELLOW}   You can add the key later to ~/.config/age/keys.txt and run 'chezmoi apply'${RESET}"
    SKIPPED+=("Age key")
    return 0
  fi

  # Validate key format
  if [[ ! "$age_key" =~ ^AGE-SECRET-KEY- ]]; then
    log_error "Invalid age key format (must start with AGE-SECRET-KEY-)"
    FAILED_STEPS+=("Age key validation")
    return 1
  fi

  # Create directory and save key
  log_info "Saving age key to ~/.config/age/keys.txt..."
  mkdir -p "$HOME/.config/age"
  echo "$age_key" > "$HOME/.config/age/keys.txt"
  chmod 600 "$HOME/.config/age/keys.txt"

  log_success "Age encryption key saved"
  INSTALLED+=("Age key")
}

apply_chezmoi() {
  section_header "Chezmoi Apply"

  # Initialize chezmoi config (creates ~/.config/chezmoi/chezmoi.toml from template)
  # Skip if config already exists (avoids potential git operations on re-runs)
  if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
    log_info "Initializing chezmoi configuration..."
    if ! timeout 30 chezmoi init --source "$DOTFILES_DIR" --no-pager --no-tty </dev/null >/dev/null 2>&1; then
      log_error "chezmoi init failed or timed out"
      FAILED_STEPS+=("chezmoi init")
      return 1
    fi
  fi

  # Apply managed files, excluding externals (TPM handled in install_plugin_managers)
  # --force: don't prompt for overwrite confirmation (we already backed up dotfiles)
  # --no-pager --no-tty: prevent pager/TTY deadlock (chezmoi issue #4874)
  log_info "Applying chezmoi configurations..."
  local chezmoi_output
  if chezmoi_output=$(timeout 120 chezmoi apply --source "$DOTFILES_DIR" --force --no-pager --no-tty --exclude=externals </dev/null 2>&1); then
    log_success "chezmoi configurations applied"
    INSTALLED+=("chezmoi apply")
  else
    local exit_code=$?
    if [ $exit_code -eq 124 ]; then
      log_error "chezmoi apply timed out after 120 seconds"
    else
      log_error "chezmoi apply failed (exit code: $exit_code)"
    fi
    [ -n "$chezmoi_output" ] && log_info "Output: $chezmoi_output"
    FAILED_STEPS+=("chezmoi apply")
    return 1
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

  # Use sudo chsh to avoid PAM password prompt (fails in piped execution)
  if sudo chsh -s "$target_shell" "$USER"; then
    log_success "Default shell changed to zsh (takes effect on next login)"
    INSTALLED+=("zsh as default shell")
  else
    log_error "Failed to change default shell"
    FAILED_STEPS+=("Shell change")
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
  echo "  ${BOLD}1. Claude Code Authentication${RESET}"
  echo "     Run: ${CYAN}claude login${RESET}"
  echo ""
  echo "  ${BOLD}2. SSH Verification${RESET}"
  echo "     Test GitHub SSH access: ${CYAN}ssh -T git@github.com${RESET}"
  echo "     (Requires your SSH public key to be added to your GitHub account)"
  echo ""
  echo "  ${BOLD}3. WSL Restart${RESET}"
  echo "     From PowerShell, run: ${CYAN}wsl.exe --shutdown${RESET}"
  echo "     Then restart WSL to enable systemd"
  echo ""
  echo "  ${BOLD}4. Verify Setup${RESET}"
  echo "     Run: ${CYAN}~/.dotfiles/verify.sh${RESET}"
  echo ""
  echo "${BOLD}Log file:${RESET} $LOG_FILE"
  echo ""
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
  # Set up logging to file and screen simultaneously
  LOG_FILE="$HOME/.dotfiles-bootstrap-$(date +%Y%m%d_%H%M%S).log"
  exec > >(tee -a "$LOG_FILE") 2>&1

  echo "${BOLD}${CYAN}"
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║                                                               ║"
  echo "║           WSL2 Dev Environment Bootstrap                      ║"
  echo "║                                                               ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo "${RESET}"
  echo ""

  log_info "Logging to: $LOG_FILE"
  echo ""

  # Check prerequisites (under set -euo pipefail)
  check_prerequisites

  # Disable exit-on-error for main sections (continue-on-failure pattern)
  set +e

  # Ensure ~/.local/bin exists and set PATH to match shell configs
  # This ensures command -v checks work for already-installed tools on re-runs
  mkdir -p "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$HOME/.local/share/fnm:$HOME/.bun/bin:$HOME/.fzf/bin:$PATH"

  # Run all sections via run_step
  # Phase 1: System foundation + repo clone
  run_step "WSL2 Configuration" configure_wsl
  run_step "APT Repository Setup" setup_apt_repos
  run_step "Chezmoi Installation" install_chezmoi

  # Phase 2: Package installation (repo now available for package lists)
  run_step "System Packages" install_apt_packages
  run_step "Binary Tools" install_binary_tools
  run_step "Plugin Managers" install_plugin_managers
  run_step "Python Tools" install_python_tools
  run_step "Node.js Tools" install_node_tools
  run_step "Claude Code" install_claude_code
  run_step "OpenCode" install_opencode

  # Phase 3: Deploy configs
  run_step "Dotfile Backup" backup_dotfiles
  run_step "Age Key" setup_age_key
  run_step "Chezmoi Apply" apply_chezmoi
  run_step "Default Shell" change_default_shell

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
