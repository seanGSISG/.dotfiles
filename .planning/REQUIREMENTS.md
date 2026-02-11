# Requirements: Dotfiles Migration & Modernization

**Defined:** 2026-02-10
**Core Value:** One command sets up a fresh WSL2 Ubuntu machine with the complete dev environment

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Shell Configuration

- [ ] **SHELL-01**: Zsh is the default login shell with antidote plugin management and Starship prompt
- [ ] **SHELL-02**: .zshrc is modular — split into sourced files (exports, plugins, functions, local)
- [ ] **SHELL-03**: .zshrc loads antidote with plugins: zsh-autosuggestions, zsh-syntax-highlighting, fzf, zoxide
- [ ] **SHELL-04**: .zshrc configures PATH ($HOME/.local/bin, $HOME/bin, $HOME/.bun/bin, $HOME/.fzf/bin)
- [ ] **SHELL-05**: .zshrc loads fnm (replacing nvm) for Node version management
- [ ] **SHELL-06**: .zshrc sources age-decrypted secrets via chezmoi
- [ ] **SHELL-07**: .zshrc includes GNOME Keyring / dbus setup for WSL2
- [ ] **SHELL-08**: .zshrc includes WezTerm OSC 7 integration for cwd inheritance
- [ ] **SHELL-09**: .bashrc is minimal fallback — PATH, secrets, fnm, hint to use zsh
- [ ] **SHELL-10**: .profile is clean — no secrets, no PATH duplication, sources bashrc if bash

### Aliases

- [ ] **ALIAS-01**: 308-line aliases file audited for zsh compatibility (array indexing, syntax)
- [ ] **ALIAS-02**: Aliases split into 6-8 category files (git, docker, navigation, utilities, dev, system, misc)
- [ ] **ALIAS-03**: New useful aliases suggested and added based on current toolset
- [ ] **ALIAS-04**: Alias help system (? / halp) works in zsh and displays categories

### Starship Prompt

- [ ] **STAR-01**: Starship installed and configured as the prompt in starship.toml
- [ ] **STAR-02**: Starship config shows: git branch/status, virtualenv, node version, command duration
- [ ] **STAR-03**: Starship theme is visually comparable or better than current Powerlevel10k setup

### Secrets

- [ ] **SEC-01**: All inline secrets removed from shell config files
- [ ] **SEC-02**: Secrets stored as age-encrypted files in chezmoi repo
- [ ] **SEC-03**: Secrets decrypted and applied by chezmoi during `chezmoi apply`
- [ ] **SEC-04**: Age key documented for storage in Bitwarden
- [ ] **SEC-05**: .secrets.env.example template committed with placeholder values

### Tool Configs

- [ ] **CONF-01**: .tmux.conf cleaned up and included in chezmoi repo
- [ ] **CONF-02**: .gitconfig cleaned up, uses chezmoi template for user-specific values (name, email)
- [ ] **CONF-03**: All config files use $HOME or chezmoi templates, no hardcoded /home/vscode paths

### Chezmoi Setup

- [ ] **CZMOI-01**: Dotfiles managed by chezmoi (not manual symlinks)
- [ ] **CZMOI-02**: chezmoi repo initialized with proper directory structure
- [ ] **CZMOI-03**: chezmoi templates used for machine-specific values (hostname, username)
- [ ] **CZMOI-04**: chezmoi age encryption configured for secret files
- [ ] **CZMOI-05**: `chezmoi apply` deploys all configs to correct locations

### WSL2 Integration

- [x] **WSL-01**: Configs auto-detect WSL2 and load WSL-specific settings conditionally
- [x] **WSL-02**: GNOME Keyring / dbus integration works in WSL2
- [x] **WSL-03**: Bootstrap configures /etc/wsl.conf (systemd=true)

### Package Management

- [ ] **PKG-01**: apt-packages.txt lists all required system packages with repo sources documented
- [ ] **PKG-02**: uv-tools.txt lists uv-managed tools (basedpyright, pre-commit, virtualenv, just)
- [ ] **PKG-03**: Package lists are declarative and consumed by bootstrap script

### SSH & Credentials Migration

- [x] **SSH-01**: Bootstrap copies ~/.ssh/ directory (keys, config, known_hosts) with correct permissions (700/600)
- [x] **SSH-02**: SSH config preserved — especially production Azure VM key (idm-prod-key)
- [x] **SSH-03**: Bootstrap verifies SSH key permissions are correct after copy

### Bootstrap Script

- [x] **BOOT-01**: bootstrap.sh is idempotent — safe to re-run without breaking anything
- [x] **BOOT-02**: Bootstrap installs apt packages from apt-packages.txt (with custom repo setup)
- [x] **BOOT-03**: Bootstrap installs antidote (zsh plugin manager)
- [x] **BOOT-04**: Bootstrap installs Starship prompt
- [x] **BOOT-05**: Bootstrap installs fnm + latest LTS Node
- [x] **BOOT-06**: Bootstrap installs fzf, zoxide, uv, bun, tmux plugin manager
- [x] **BOOT-07**: Bootstrap installs Claude Code
- [x] **BOOT-08**: Bootstrap sets zsh as default shell (chsh)
- [x] **BOOT-09**: Bootstrap runs `chezmoi init` and `chezmoi apply` to deploy configs
- [x] **BOOT-10**: Bootstrap backs up existing dotfiles to ~/.dotfiles-backup/<timestamp>/
- [x] **BOOT-11**: Bootstrap prints post-install checklist (age key from Bitwarden, gh auth, SSH keys, tmux prefix+I, claude login)
- [x] **BOOT-12**: Bootstrap has basic error handling (set -euo pipefail, colored output)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Performance

- **PERF-01**: Shell startup time under 100ms via lazy loading
- **PERF-02**: Async plugin loading for non-critical plugins
- **PERF-03**: Compilation cache for zsh completions (compdump)

### Advanced Secrets

- **SECV2-01**: chezmoi + Bitwarden CLI integration for runtime secret retrieval
- **SECV2-02**: Automated age key provisioning from Bitwarden during bootstrap

### CI/CD

- **CI-01**: GitHub Actions workflow to test bootstrap in Docker container
- **CI-02**: Automated startup time benchmarking in CI

### Cross-Platform

- **PLAT-01**: macOS support in bootstrap (conditional brew vs apt)
- **PLAT-02**: Native Linux (non-WSL) support

## Out of Scope

| Feature | Reason |
|---------|--------|
| Oh My Zsh framework | Replaced by antidote — lighter, faster |
| Powerlevel10k | Replaced by Starship — actively maintained |
| nvm | Replaced by fnm — 40x faster |
| Homebrew on WSL2 | apt + direct binaries is cleaner on Linux |
| Oh My Bash | Retiring entirely — zsh is sole primary shell |
| Docker test container | Test manually on new machine |
| Dry-run / resume-on-failure | Keep bootstrap solid but simple |
| Claude Code config in dotfiles | Just install binary, copy configs manually |
| Windows PATH interop | Can add bloat, handle manually if needed |
| 1Password CLI integration | Use age encryption with key in Bitwarden instead |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CZMOI-01 | Phase 1 | Complete |
| CZMOI-02 | Phase 1 | Complete |
| CZMOI-03 | Phase 1 | Complete |
| CZMOI-04 | Phase 1 | Complete |
| CZMOI-05 | Phase 1 | Complete |
| SEC-01 | Phase 1 | Complete |
| SEC-02 | Phase 1 | Complete |
| SEC-03 | Phase 1 | Complete |
| SEC-04 | Phase 1 | Complete |
| SEC-05 | Phase 1 | Complete |
| PKG-01 | Phase 2 | Complete |
| PKG-02 | Phase 2 | Complete |
| PKG-03 | Phase 2 | Complete |
| SHELL-01 | Phase 3 | Complete |
| SHELL-02 | Phase 3 | Complete |
| SHELL-03 | Phase 3 | Complete |
| SHELL-04 | Phase 3 | Complete |
| SHELL-05 | Phase 3 | Complete |
| SHELL-06 | Phase 3 | Complete |
| SHELL-07 | Phase 3 | Complete |
| SHELL-08 | Phase 3 | Complete |
| SHELL-09 | Phase 3 | Complete |
| SHELL-10 | Phase 3 | Complete |
| ALIAS-01 | Phase 3 | Complete |
| ALIAS-02 | Phase 3 | Complete |
| ALIAS-03 | Phase 3 | Complete |
| ALIAS-04 | Phase 3 | Complete |
| CONF-01 | Phase 4 | Complete |
| CONF-02 | Phase 4 | Complete |
| CONF-03 | Phase 4 | Complete |
| STAR-01 | Phase 4 | Complete |
| STAR-02 | Phase 4 | Complete |
| STAR-03 | Phase 4 | Complete |
| BOOT-01 | Phase 5 | Complete |
| BOOT-02 | Phase 5 | Complete |
| BOOT-03 | Phase 5 | Complete |
| BOOT-04 | Phase 5 | Complete |
| BOOT-05 | Phase 5 | Complete |
| BOOT-06 | Phase 5 | Complete |
| BOOT-07 | Phase 5 | Complete |
| BOOT-08 | Phase 5 | Complete |
| BOOT-09 | Phase 5 | Complete |
| BOOT-10 | Phase 5 | Complete |
| BOOT-11 | Phase 5 | Complete |
| BOOT-12 | Phase 5 | Complete |
| WSL-01 | Phase 5 | Complete |
| WSL-02 | Phase 5 | Complete |
| WSL-03 | Phase 5 | Complete |
| SSH-01 | Phase 5 | Complete |
| SSH-02 | Phase 5 | Complete |
| SSH-03 | Phase 5 | Complete |

**Coverage:**
- v1 requirements: 51 total
- Mapped to phases: 51
- Unmapped: 0

**Phase 6 Note:** Phase 6 (Migration & Testing) performs cross-cutting validation of all 51 requirements on the new machine rather than mapping to specific new requirements.

---
*Requirements defined: 2026-02-10*
*Last updated: 2026-02-10 - Phase 5 requirements marked Complete (BOOT-01 through BOOT-12, WSL-01 through WSL-03, SSH-01 through SSH-03)*
