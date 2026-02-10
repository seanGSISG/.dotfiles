# Dotfiles Migration

## What This Is

A git-managed dotfiles repo (`~/.dotfiles`) with an idempotent bootstrap script that migrates a heavily customized WSL2 Ubuntu dev environment from the current machine (user `vscode`) to a new machine (user `adminuser`). Consolidates a dual-shell setup (bash + zsh) into zsh as the sole primary shell, extracts secrets, cleans up all configs, and makes the entire environment reproducible.

## Core Value

One command (`bootstrap.sh`) sets up a fresh WSL2 Ubuntu machine with the complete dev environment — zsh with Powerlevel10k, all tools installed, all configs symlinked, ready to code.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Consolidate to zsh as primary shell with minimal bash fallback
- [ ] Rewrite ~/.zshrc with all PATH, env, NVM, brew, fzf, zoxide, GNOME Keyring, WezTerm OSC 7
- [ ] Rewrite ~/.bashrc as minimal fallback (PATH, secrets, NVM, brew)
- [ ] Rewrite ~/.profile (clean, no secrets, no duplication)
- [ ] Audit aliases file for zsh compatibility and suggest new aliases
- [ ] Move aliases to ~/.oh-my-zsh/custom/aliases.zsh
- [ ] Extract secrets to git-ignored ~/.secrets.env with .example template
- [ ] Clean up ~/.tmux.conf
- [ ] Clean up ~/.gitconfig
- [ ] Create ~/.dotfiles repo with structured layout and symlink mapping
- [ ] Generate package lists (apt-packages.txt, Brewfile, uv tools)
- [ ] Write idempotent bootstrap.sh (solid, basic error handling, not dry-run/resume)
- [ ] Bootstrap installs: apt packages, brew, oh-my-zsh, p10k, plugins, fzf, zoxide, uv, nvm, node, bun, tmux plugin manager, Claude Code
- [ ] Bootstrap creates symlinks with backup of existing files
- [ ] Bootstrap prints post-install checklist (secrets, gh auth, SSH keys, tmux plugins, claude login)
- [ ] Replace all hardcoded /home/vscode paths with $HOME

### Out of Scope

- Claude Code config migration — just install the binary, configs copied manually
- Docker testing container — test manually on the new machine
- Dry-run mode / resume-on-failure in bootstrap — keep it solid but simple
- Oh My Bash preservation — retiring entirely
- Windows-side tooling (Docker Desktop, VS Code) — handled separately

## Context

- Current machine: WSL2 Ubuntu, user `vscode`
- New machine: WSL2 Ubuntu, user `adminuser` (not yet provisioned)
- Current shell setup: bash with Oh My Bash + zsh with Oh My Zsh/Powerlevel10k (dual)
- Target: zsh-only with Powerlevel10k, bash as minimal fallback
- Aliases file: 308 lines in ~/.oh-my-bash/custom/aliases/personal.aliases.sh
- Key tools: nvm, bun, uv, fzf, zoxide, tmux, gh, Claude Code
- Secrets currently inline in shell configs: GITHUB_PERSONAL_ACCESS_TOKEN, EXA_API_KEY, GREPTILE_API_KEY
- Detailed migration plan exists at ~/.claude/plans/luminous-seeking-dewdrop.md

## Constraints

- **Portability**: All paths must use $HOME, not hardcoded usernames
- **Idempotency**: bootstrap.sh must be safe to re-run without breaking anything
- **Secrets**: Never committed to git — extracted to ~/.secrets.env, git-ignored
- **Symlinks**: Dotfiles repo is the source of truth, home directory gets symlinks
- **WSL2**: Must handle WSL-specific concerns (systemd, Windows path mounts, dbus)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Zsh as sole primary shell | Eliminate dual-shell maintenance, zsh has better plugins/UX | — Pending |
| Oh My Zsh (not zinit/antidote) | Already using it, good enough, less migration friction | — Pending |
| Symlinks from dotfiles repo | Single source of truth, easy to update and sync | — Pending |
| Secrets in ~/.secrets.env | Simple, no external tool dependency (no 1Password CLI, etc.) | — Pending |
| No Docker test container | Faster to iterate, test manually on real machine | — Pending |
| Solid but simple bootstrap | Basic error handling + idempotency, no dry-run/resume complexity | — Pending |

---
*Last updated: 2026-02-10 after initialization*
