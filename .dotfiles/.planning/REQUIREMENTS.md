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

- [x] **SEC-01**: All inline secrets removed from shell config files
- [x] **SEC-02**: Secrets stored as age-encrypted files in chezmoi repo
- [x] **SEC-03**: Secrets decrypted and applied by chezmoi during `chezmoi apply`
- [x] **SEC-04**: Age key documented for storage in Bitwarden
- [x] **SEC-05**: .secrets.env.example template committed with placeholder values

### Tool Configs

- [ ] **CONF-01**: .tmux.conf cleaned up and included in chezmoi repo
- [ ] **CONF-02**: .gitconfig cleaned up, uses chezmoi template for user-specific values (name, email)
- [ ] **CONF-03**: All config files use $HOME or chezmoi templates, no hardcoded /home/vscode paths

### Chezmoi Setup

- [x] **CZMOI-01**: Dotfiles managed by chezmoi (not manual symlinks)
- [x] **CZMOI-02**: chezmoi repo initialized with proper directory structure
- [x] **CZMOI-03**: chezmoi templates used for machine-specific values (hostname, username)
- [x] **CZMOI-04**: chezmoi age encryption configured for secret files
- [x] **CZMOI-05**: `chezmoi apply` deploys all configs to correct locations

### WSL2 Integration

- [ ] **WSL-01**: Configs auto-detect WSL2 and load WSL-specific settings conditionally
- [ ] **WSL-02**: GNOME Keyring / dbus integration works in WSL2
- [ ] **WSL-03**: Bootstrap configures /etc/wsl.conf (systemd=true)

### Package Management

- [ ] **PKG-01**: apt-packages.txt lists all required system packages with repo sources documented
- [ ] **PKG-02**: uv-tools.txt lists uv-managed tools (basedpyright, pre-commit, virtualenv, just)
- [ ] **PKG-03**: Package lists are declarative and consumed by bootstrap script

### SSH & Credentials Migration

- [ ] **SSH-01**: Bootstrap copies ~/.ssh/ directory (keys, config, known_hosts) with correct permissions (700/600)
- [ ] **SSH-02**: SSH config preserved — especially production Azure VM key (idm-prod-key)
- [ ] **SSH-03**: Bootstrap verifies SSH key permissions are correct after copy

### Bootstrap Script

- [ ] **BOOT-01**: bootstrap.sh is idempotent — safe to re-run without breaking anything
- [ ] **BOOT-02**: Bootstrap installs apt packages from apt-packages.txt (with custom repo setup)
- [ ] **BOOT-03**: Bootstrap installs antidote (zsh plugin manager)
- [ ] **BOOT-04**: Bootstrap installs Starship prompt
- [ ] **BOOT-05**: Bootstrap installs fnm + latest LTS Node
- [ ] **BOOT-06**: Bootstrap installs fzf, zoxide, uv, bun, tmux plugin manager
- [ ] **BOOT-07**: Bootstrap installs Claude Code
- [ ] **BOOT-08**: Bootstrap sets zsh as default shell (chsh)
- [ ] **BOOT-09**: Bootstrap runs `chezmoi init` and `chezmoi apply` to deploy configs
- [ ] **BOOT-10**: Bootstrap backs up existing dotfiles to ~/.dotfiles-backup/<timestamp>/
- [ ] **BOOT-11**: Bootstrap prints post-install checklist (age key from Bitwarden, gh auth, SSH keys, tmux prefix+I, claude login)
- [ ] **BOOT-12**: Bootstrap has basic error handling (set -euo pipefail, colored output)

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
| PKG-01 | Phase 2 | Pending |
| PKG-02 | Phase 2 | Pending |
| PKG-03 | Phase 2 | Pending |
| SHELL-01 | Phase 3 | Pending |
| SHELL-02 | Phase 3 | Pending |
| SHELL-03 | Phase 3 | Pending |
| SHELL-04 | Phase 3 | Pending |
| SHELL-05 | Phase 3 | Pending |
| SHELL-06 | Phase 3 | Pending |
| SHELL-07 | Phase 3 | Pending |
| SHELL-08 | Phase 3 | Pending |
| SHELL-09 | Phase 3 | Pending |
| SHELL-10 | Phase 3 | Pending |
| ALIAS-01 | Phase 3 | Pending |
| ALIAS-02 | Phase 3 | Pending |
| ALIAS-03 | Phase 3 | Pending |
| ALIAS-04 | Phase 3 | Pending |
| CONF-01 | Phase 4 | Pending |
| CONF-02 | Phase 4 | Pending |
| CONF-03 | Phase 4 | Pending |
| STAR-01 | Phase 4 | Pending |
| STAR-02 | Phase 4 | Pending |
| STAR-03 | Phase 4 | Pending |
| BOOT-01 | Phase 5 | Pending |
| BOOT-02 | Phase 5 | Pending |
| BOOT-03 | Phase 5 | Pending |
| BOOT-04 | Phase 5 | Pending |
| BOOT-05 | Phase 5 | Pending |
| BOOT-06 | Phase 5 | Pending |
| BOOT-07 | Phase 5 | Pending |
| BOOT-08 | Phase 5 | Pending |
| BOOT-09 | Phase 5 | Pending |
| BOOT-10 | Phase 5 | Pending |
| BOOT-11 | Phase 5 | Pending |
| BOOT-12 | Phase 5 | Pending |
| WSL-01 | Phase 5 | Pending |
| WSL-02 | Phase 5 | Pending |
| WSL-03 | Phase 5 | Pending |
| SSH-01 | Phase 5 | Pending |
| SSH-02 | Phase 5 | Pending |
| SSH-03 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 51 total
- Mapped to phases: 51
- Unmapped: 0

**Phase 6 Note:** Phase 6 (Migration & Testing) performs cross-cutting validation of all 51 requirements on the new machine rather than mapping to specific new requirements.

---
*Requirements defined: 2026-02-10*
*Last updated: 2026-02-10 — Phase 1 requirements marked Complete*
