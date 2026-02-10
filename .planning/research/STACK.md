# Technology Stack: Dotfiles Management & WSL2 Bootstrap

**Project:** Dotfiles management and dev environment bootstrap for WSL2 Ubuntu
**Researched:** 2026-02-10
**Overall confidence:** HIGH

## Executive Summary

The 2025-2026 dotfiles ecosystem has matured around **chezmoi** for management, **Starship** for prompts, and **antidote** for zsh plugin management. The shift away from Oh My Zsh's monolithic approach and Powerlevel10k's life support status is clear. For WSL2 Ubuntu specifically, **apt + targeted tools** beats Homebrew's complexity, and **fnm** has replaced nvm as the performance-oriented Node version manager.

---

## Recommended Stack

### Dotfiles Manager

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **chezmoi** | 2.69.3+ | Dotfiles management | Templates for multi-machine configs, built-in secrets management (age/gpg), single binary with no dependencies, can import from archives (great for plugins), idempotent by design. Beats stow (symlink migration pain) and yadm (unmaintained templating dependencies). |

**Installation:**
```bash
# Via binary (recommended for WSL2)
sh -c "$(curl -fsLS get.chezmoi.io)"

# Or via apt
sudo apt install chezmoi
```

**Rationale:** Chezmoi is the modern standard for 2026. Unlike stow's symlinks, chezmoi uses real files (no migration pain). Unlike yadm's bare git approach, chezmoi has active templating with Go's text/template (no external deps). For WSL2 where you might sync with Windows or other machines, templates handle machine-specific differences cleanly.

**Confidence:** HIGH (official docs, v2.69.3 released Jan 2026, active development)

---

### Shell Prompt

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Starship** | Latest | Cross-shell prompt | Written in Rust (fast), actively maintained (unlike p10k on life support), shell-agnostic (works in bash/zsh/fish), minimal config, measurable perf with `starship explain`. Absolute performance is imperceptible vs p10k (~2-3ms), but active development matters. |

**Installation:**
```bash
# Via curl script
curl -sS https://starship.rs/install.sh | sh

# Or via apt (if available)
# Or download binary from GitHub releases
```

**Configuration:**
```bash
# Add to ~/.zshrc
eval "$(starship init zsh)"
```

**Alternatives considered:**
- **Powerlevel10k:** On life support (no active development), zsh-only. Still works but not maintained.
- **Oh My Posh:** Faster than p10k in some benchmarks, but less popular in Unix ecosystem (more Windows-focused).

**Rationale:** Starship is the 2026 standard. P10k's instant prompt is its killer feature, but project is unmaintained. Starship's Rust implementation + active development + cross-shell support make it the future-proof choice. Performance difference is negligible (both <5ms on modern hardware).

**Confidence:** HIGH (official docs, active GitHub, recent community adoption)

---

### Zsh Plugin Manager

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **antidote** | Latest | Fast zsh plugin management | Native zsh implementation, generates static plugin file (ultra-fast loads), concurrent plugin operations, works WITH Oh My Zsh plugins selectively (load specific plugins, not the framework). Beats zinit (bad load time without turbo mode) and oh-my-zsh (monolithic, slow). |

**Installation:**
```bash
# Clone to ~/.antidote
git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote

# Or via homebrew (if using brew)
brew install antidote
```

**Configuration:**
```bash
# Add to ~/.zshrc
source ${ZDOTDIR:-~}/.antidote/antidote.zsh
antidote load

# Create ~/.zsh_plugins.txt with plugins (one per line)
# Example:
# ohmyzsh/ohmyzsh path:lib/git.zsh
# ohmyzsh/ohmyzsh path:plugins/git
# zsh-users/zsh-autosuggestions
# zsh-users/zsh-syntax-highlighting
```

**Alternatives considered:**
- **Oh My Zsh:** Monolithic framework, loads everything, slower startup. Still useful for individual plugins via antidote.
- **zinit:** Turbo mode is fast but complex config. Bad load time without turbo mode (benchmark confirms).
- **sheldon:** Rust-based, fast, but less popular than antidote in 2026.

**Rationale:** Antidote is the sweet spot: native zsh (no external deps), generates static load file (fast), lets you cherry-pick OMZ plugins without the framework bloat. User already knows OMZ, so transition path is smooth (use same plugins, different manager).

**Confidence:** HIGH (official docs, benchmark data, active development)

---

### Node.js Version Manager

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **fnm** | Latest | Fast Node.js version manager | Written in Rust (40x faster than nvm), cross-platform, `.node-version` and `.nvmrc` support, shell integration for auto-switching. Beats nvm (slow shell scripts) and volta (over-engineered for single-language use). |

**Installation:**
```bash
# Via install script
curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell

# Manual shell setup in ~/.zshrc
export PATH="$HOME/.fnm:$PATH"
eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
```

**Usage:**
```bash
# Install LTS
fnm install --lts

# Install specific version
fnm install 20

# Use version
fnm use 20
```

**Alternatives considered:**
- **nvm:** Standard but slow (shell-based). fnm is nvm-compatible but 40x faster.
- **Volta:** Over-engineered (manages entire JS toolchain). Good for teams, overkill for personal dotfiles.
- **mise (formerly rtx):** Polyglot version manager (Node, Python, Ruby). Good if managing multiple languages, but adds complexity if only managing Node.

**Rationale:** fnm is the 2026 performance standard for Node version management. User already has nvm, so fnm is a drop-in faster replacement. Rust implementation = no shell overhead. If user later needs Python/Ruby management, consider mise, but for Node-only, fnm wins.

**Confidence:** HIGH (official docs, benchmark data, active development)

---

### Polyglot Version Manager (Optional)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **mise** | Latest | Multi-language version manager (optional) | Replaces asdf/nvm/pyenv/rbenv with single tool. Rust-based (fast), no shims (unlike asdf's 120ms overhead), includes Node/Python/Ruby without plugins. Use if managing Python (uv) + Node + others. |

**Installation:**
```bash
# Via install script
curl https://mise.run | sh

# Or via apt (if available)
```

**When to use:**
- Managing Python (via mise or stick with uv for Python-only)
- Managing Ruby/Go/other languages beyond Node
- Team standardization across languages

**When NOT to use:**
- Only managing Node.js (fnm is simpler)
- Already using uv for Python (no need for duplication)

**Rationale:** Mise is the asdf successor with better performance (no shims, Rust implementation). If user needs multi-language management beyond fnm (Node) + uv (Python), mise consolidates everything. Otherwise, keep focused tools (fnm + uv).

**Confidence:** MEDIUM (official docs, good benchmarks, but user context doesn't clearly need polyglot manager yet)

---

### Package Management Strategy

| Layer | Tool | Purpose | Why |
|-------|------|---------|-----|
| **System packages** | `apt` | Ubuntu packages (git, curl, build-essential, etc.) | Native, fast, well-integrated with Ubuntu. Avoid Homebrew on WSL2 (adds complexity, not needed). |
| **Node.js packages** | `npm` / `bun` | JavaScript tooling | User already has bun. Use npm for compatibility, bun for performance. |
| **Python packages** | `uv` | Python tooling | User already has uv. Modern, fast Python package/project manager. |
| **CLI tools** | Direct binary install or `apt` | Modern CLI tools (fzf, zoxide, gh, etc.) | Most have official apt repos or GitHub releases. No Homebrew needed. |

**Package installation pattern (bootstrap.sh):**

```bash
# System packages via apt
apt_packages=(
  git
  curl
  zsh
  tmux
  build-essential
  fzf
  zoxide
)

for pkg in "${apt_packages[@]}"; do
  if ! dpkg -l | grep -q "^ii  $pkg "; then
    sudo apt install -y "$pkg"
  fi
done

# GitHub CLI (official apt repo)
if ! command -v gh &> /dev/null; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install -y gh
fi

# fnm for Node
if ! command -v fnm &> /dev/null; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

# uv for Python (user already has)
if ! command -v uv &> /dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
```

**Why NOT Homebrew on WSL2:**
- Adds 200MB+ dependency layer
- Slower than apt for system packages
- Designed for macOS package gaps, not needed on Ubuntu
- WSL2 has native apt with better Ubuntu integration

**Confidence:** HIGH (official Ubuntu docs, official tool installation methods)

---

## Supporting Tools (Already in User's Stack)

| Tool | Purpose | Installation |
|------|---------|-------------|
| **fzf** | Fuzzy finder | `apt install fzf` |
| **zoxide** | Smarter cd | `apt install zoxide` (or binary install) |
| **tmux** | Terminal multiplexer | `apt install tmux` |
| **gh** | GitHub CLI | Official apt repo (see above) |
| **bun** | Fast JS runtime | User already has |
| **uv** | Python package manager | User already has |

---

## Bootstrap Script Pattern

### Key Principles

1. **Idempotent:** Safe to run multiple times
2. **Fail-fast:** Exit on errors (`set -e`)
3. **Informative:** Echo what's happening
4. **Modular:** Separate functions for each concern

### Recommended Structure

```bash
#!/usr/bin/env bash
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Idempotency checks
command_exists() { command -v "$1" &> /dev/null; }
package_installed() { dpkg -l | grep -q "^ii  $1 "; }
dir_exists() { [ -d "$1" ]; }
file_exists() { [ -f "$1" ]; }

# Install system packages
install_system_packages() {
  log_info "Installing system packages..."

  local packages=(git curl zsh tmux build-essential fzf zoxide)

  for pkg in "${packages[@]}"; do
    if ! package_installed "$pkg"; then
      log_info "Installing $pkg..."
      sudo apt install -y "$pkg"
    else
      log_info "$pkg already installed, skipping"
    fi
  done
}

# Install chezmoi
install_chezmoi() {
  if command_exists chezmoi; then
    log_info "chezmoi already installed, skipping"
    return 0
  fi

  log_info "Installing chezmoi..."
  sh -c "$(curl -fsLS get.chezmoi.io)"
}

# Install fnm
install_fnm() {
  if command_exists fnm; then
    log_info "fnm already installed, skipping"
    return 0
  fi

  log_info "Installing fnm..."
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
}

# Install Starship
install_starship() {
  if command_exists starship; then
    log_info "Starship already installed, skipping"
    return 0
  fi

  log_info "Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
}

# Install antidote
install_antidote() {
  local antidote_dir="${ZDOTDIR:-$HOME}/.antidote"

  if dir_exists "$antidote_dir"; then
    log_info "antidote already installed, skipping"
    return 0
  fi

  log_info "Installing antidote..."
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir"
}

# Change default shell to zsh
setup_zsh() {
  if [ "$SHELL" = "$(which zsh)" ]; then
    log_info "zsh already default shell, skipping"
    return 0
  fi

  log_info "Changing default shell to zsh..."
  chsh -s "$(which zsh)"
}

# Main execution
main() {
  log_info "Starting dotfiles bootstrap..."

  # Update apt
  log_info "Updating apt..."
  sudo apt update

  # Run installation functions
  install_system_packages
  install_chezmoi
  install_fnm
  install_starship
  install_antidote
  setup_zsh

  log_info "Bootstrap complete!"
  log_warn "Please log out and log back in for shell changes to take effect"
}

main "$@"
```

### Idempotency Patterns Used

1. **Command existence:** `command -v "$1" &> /dev/null`
2. **Package check:** `dpkg -l | grep -q "^ii  $pkg "`
3. **Directory check:** `[ -d "$1" ]`
4. **File check:** `[ -f "$1" ]`
5. **Early return:** `return 0` if already installed

### Confidence

**Confidence:** HIGH (established patterns from dotfiles community, tested idempotency approaches)

---

## Anti-Patterns to Avoid

### 1. Don't Use Homebrew on WSL2

**Why:** Adds unnecessary complexity, slower than apt, designed for macOS package gaps.

**Instead:** Use apt for system packages, direct binary install for modern tools.

### 2. Don't Use Oh My Zsh Framework

**Why:** Monolithic, loads everything, slow startup (200-500ms).

**Instead:** Use antidote to selectively load OMZ plugins you actually use.

### 3. Don't Use GNU Stow Without Understanding Migration

**Why:** Symlink farms are hard to migrate away from. If you stop using stow, you manually move all files.

**Instead:** Use chezmoi (real files, easy to stop using anytime).

### 4. Don't Use Bare Git Repo for Dotfiles

**Why:** Works but limited: no templates, no secrets management, no multi-machine support.

**Instead:** Use chezmoi for modern dotfiles management.

### 5. Don't Use nvm

**Why:** Shell-based, slow (200-500ms overhead on every shell start).

**Instead:** Use fnm (40x faster, Rust-based, nvm-compatible).

### 6. Don't Keep Powerlevel10k

**Why:** Project is on life support, no active development.

**Instead:** Migrate to Starship (active development, cross-shell, Rust-based).

### 7. Don't Skip Idempotency Checks

**Why:** Non-idempotent scripts break on re-run, waste time, cause errors.

**Instead:** Check existence before every operation (`command -v`, `dpkg -l`, `[ -d ]`, `[ -f ]`).

### 8. Don't Use `mkdir` Without `-p`

**Why:** Fails if directory exists.

**Instead:** Always `mkdir -p` (idempotent by default).

### 9. Don't Hardcode Paths

**Why:** Breaks portability across machines.

**Instead:** Use `$HOME`, `${ZDOTDIR:-~}`, `$(which zsh)`.

### 10. Don't Mix Package Managers

**Why:** Dependency conflicts, version mismatches.

**Instead:** apt for system, fnm for Node, uv for Python. Keep layers separate.

---

## Migration Path from Current Setup

User currently has: **Oh My Zsh + Powerlevel10k + nvm**

### Phase 1: Add New Tools (Non-Breaking)

1. Install chezmoi
2. Install fnm (alongside nvm)
3. Install antidote (alongside OMZ)
4. Install Starship (alongside p10k)

### Phase 2: Test New Tools

1. Test fnm with a project (keep nvm as fallback)
2. Configure antidote to load same OMZ plugins
3. Test Starship prompt (switch back to p10k if issues)

### Phase 3: Switch Defaults

1. Update `.zshrc` to use fnm instead of nvm
2. Update `.zshrc` to source antidote instead of OMZ framework
3. Update `.zshrc` to init Starship instead of p10k

### Phase 4: Cleanup

1. Remove nvm once fnm is proven
2. Remove OMZ framework (keep using plugins via antidote)
3. Remove p10k config

### Phase 5: Chezmoi Migration

1. Initialize chezmoi: `chezmoi init`
2. Add dotfiles: `chezmoi add ~/.zshrc ~/.gitconfig ~/.tmux.conf`
3. Test: `chezmoi diff`
4. Apply: `chezmoi apply`
5. Push to Git: `chezmoi cd && git remote add origin <repo> && git push`

---

## Version Pins (For Reproducibility)

**Note:** For personal dotfiles, using "latest" is fine. For team/production, pin versions.

If pinning versions in bootstrap.sh:

```bash
# Example: Pin Starship version
STARSHIP_VERSION="1.17.1"
curl -sS "https://starship.rs/install.sh" | sh -s -- --version "$STARSHIP_VERSION"

# Example: Pin fnm version
FNM_VERSION="1.37.0"
curl -fsSL "https://github.com/Schniz/fnm/releases/download/v${FNM_VERSION}/fnm-linux.zip" -o /tmp/fnm.zip
```

**Recommendation for user:** Start with "latest", add version pins if reproducibility becomes critical.

---

## Configuration File Locations

| Tool | Config File | Location |
|------|-------------|----------|
| zsh | `.zshrc` | `~/.zshrc` |
| Starship | `starship.toml` | `~/.config/starship.toml` |
| antidote | `.zsh_plugins.txt` | `~/.zsh_plugins.txt` |
| fnm | (shell integration) | In `.zshrc` |
| chezmoi | Config + dotfiles | `~/.local/share/chezmoi/` |
| tmux | `.tmux.conf` | `~/.tmux.conf` |
| git | `.gitconfig` | `~/.gitconfig` |

**All of these should be managed by chezmoi.**

---

## Quick Start Commands

```bash
# 1. Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# 2. Clone your dotfiles repo (after Phase 5 migration)
chezmoi init --apply https://github.com/yourusername/dotfiles.git

# 3. Run bootstrap script (managed by chezmoi)
~/.local/share/chezmoi/bootstrap.sh

# 4. Reload shell
exec zsh
```

---

## Testing Bootstrap Script

```bash
# Test in Docker container (safe, disposable)
docker run -it ubuntu:24.04 /bin/bash

# Inside container
apt update && apt install -y curl git sudo
curl -fsSL https://raw.githubusercontent.com/yourusername/dotfiles/main/bootstrap.sh | bash

# Verify
command -v zsh
command -v fnm
command -v starship
command -v chezmoi
command -v antidote

# Test idempotency (run again)
curl -fsSL https://raw.githubusercontent.com/yourusername/dotfiles/main/bootstrap.sh | bash
# Should skip already-installed items
```

---

## Sources

### Dotfiles Managers
- [chezmoi official docs](https://www.chezmoi.io/)
- [chezmoi comparison table](https://www.chezmoi.io/comparison-table/)
- [Exploring Tools For Managing Your Dotfiles](https://gbergatto.github.io/posts/tools-managing-dotfiles/)
- [Dotfile Management Tools Battle](https://biggo.com/news/202412191324_dotfile-management-tools-comparison)

### Zsh Plugin Managers
- [antidote official docs](https://antidote.sh/)
- [zsh plugin manager benchmark](https://github.com/rossmacarthur/zsh-plugin-manager-benchmark)
- [Comparison of ZSH frameworks](https://gist.github.com/laggardkernel/4a4c4986ccdcaf47b91e8227f9868ded)

### Prompt Themes
- [Starship official docs](https://starship.rs/)
- [Powerlevel10k is on Life Support](https://hashir.blog/2025/06/powerlevel10k-is-on-life-support-hello-starship/)
- [Moving from powerlevel10k to Starship](https://bulimov.me/post/2025/05/11/powerlevel10k-to-starship/)

### Node Version Managers
- [fnm GitHub](https://github.com/Schniz/fnm)
- [NVM Alternatives Guide](https://betterstack.com/community/guides/scaling-nodejs/nvm-alternatives-guide/)
- [Navigating Node.js Versions](https://leapcell.io/blog/navigating-node-js-versions-a-deep-dive-into-nvm-volta-and-fnm)
- [FNM Complete Guide](https://blog.wenhaofree.com/en/posts/technology/fnm-complete-guide-en/)

### Mise (Polyglot Version Manager)
- [Mise vs asdf](https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/)
- [Mise official docs](https://mise.jdx.dev/)
- [How to Use mise](https://oneuptime.com/blog/post/2026-01-25-mise-tool-version-management/view)

### Bootstrap Patterns
- [How to write idempotent Bash scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/)
- [idempotent-bash GitHub](https://github.com/metaist/idempotent-bash)
- [Bootstrap repositories](https://dotfiles.github.io/bootstrap/)
- [felipecrs/dotfiles](https://github.com/felipecrs/dotfiles)

### WSL2 Ubuntu
- [aubique/dotfiles-wsl](https://github.com/aubique/dotfiles-wsl)
- [Alex-D/dotfiles](https://github.com/Alex-D/dotfiles)

---

## Summary

**Recommended 2026 Stack:**
- **Dotfiles:** chezmoi 2.69.3+
- **Prompt:** Starship (Rust-based, cross-shell, actively maintained)
- **Zsh plugins:** antidote (fast, native zsh, selective OMZ plugin loading)
- **Node:** fnm (40x faster than nvm, Rust-based)
- **Python:** uv (user already has)
- **Packages:** apt (no Homebrew on WSL2)
- **Bootstrap:** Idempotent bash script with clear functions

**Key migrations:**
- Oh My Zsh framework → antidote + selective OMZ plugins
- Powerlevel10k → Starship
- nvm → fnm
- Manual dotfiles → chezmoi

**Confidence:** HIGH across all recommendations (verified with official docs, 2026 sources, active development confirmed)
