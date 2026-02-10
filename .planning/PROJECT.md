# Dotfiles Migration & Modernization

## What This Is

A chezmoi-managed dotfiles repo with an idempotent bootstrap script that migrates and modernizes a heavily customized WSL2 Ubuntu dev environment from the current machine (user `vscode`) to a new machine (user `adminuser`). Consolidates a dual-shell setup (bash + zsh) into zsh as the sole primary shell, modernizes the toolchain (Starship, antidote, fnm), extracts secrets, cleans up all configs, and makes the entire environment reproducible.

## Core Value

One command (`bootstrap.sh`) sets up a fresh WSL2 Ubuntu machine with the complete dev environment — zsh with Starship prompt, all tools installed, all configs managed by chezmoi, ready to code.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Consolidate to zsh as primary shell with minimal bash fallback
- [ ] Rewrite ~/.zshrc with antidote plugin management, Starship prompt, fnm, fzf, zoxide
- [ ] Rewrite ~/.bashrc as minimal fallback (PATH, secrets, fnm)
- [ ] Rewrite ~/.profile (clean, no secrets, no duplication)
- [ ] Audit 308-line aliases file for zsh compatibility and suggest new aliases
- [ ] Split aliases into modular category files (git, docker, navigation, etc.)
- [ ] Extract secrets to git-ignored ~/.secrets.env with .example template
- [ ] Clean up ~/.tmux.conf
- [ ] Clean up ~/.gitconfig
- [ ] Set up chezmoi-managed dotfiles repo with templates for portability
- [ ] Generate package lists (apt-packages.txt, uv tools)
- [ ] Write idempotent bootstrap.sh (solid, basic error handling)
- [ ] Bootstrap installs: apt packages, antidote, Starship, fnm, fzf, zoxide, uv, bun, tmux plugin manager, Claude Code
- [ ] Bootstrap runs chezmoi init/apply for config deployment
- [ ] Bootstrap prints post-install checklist (secrets, gh auth, SSH keys, tmux plugins, claude login)
- [ ] Replace all hardcoded /home/vscode paths with $HOME (chezmoi templates)
- [ ] Migrate from Oh My Zsh to antidote (selectively loading useful OMZ plugins)
- [ ] Migrate from Powerlevel10k to Starship
- [ ] Migrate from nvm to fnm

### Out of Scope

- Claude Code config migration — just install the binary, configs copied manually
- Docker testing container — test manually on the new machine
- Dry-run mode / resume-on-failure in bootstrap — keep it solid but simple
- Oh My Bash preservation — retiring entirely
- Oh My Zsh framework — replaced by antidote
- Powerlevel10k — replaced by Starship
- nvm — replaced by fnm
- Homebrew on WSL2 — apt + direct binaries is cleaner
- Windows-side tooling (Docker Desktop, VS Code) — handled separately

## Context

- Current machine: WSL2 Ubuntu, user `vscode`
- New machine: WSL2 Ubuntu, user `adminuser` (not yet provisioned)
- Current shell setup: bash with Oh My Bash + zsh with Oh My Zsh/Powerlevel10k (dual)
- Target: zsh-only with Starship + antidote, bash as minimal fallback
- Aliases file: 308 lines in ~/.oh-my-bash/custom/aliases/personal.aliases.sh
- Key tools: fnm (replacing nvm), bun, uv, fzf, zoxide, tmux, gh, Claude Code
- Secrets currently inline in shell configs: GITHUB_PERSONAL_ACCESS_TOKEN, EXA_API_KEY, GREPTILE_API_KEY
- Detailed original migration plan at ~/.claude/plans/luminous-seeking-dewdrop.md
- Research at .planning/research/ — STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md

## Constraints

- **Portability**: chezmoi templates with $HOME, no hardcoded usernames
- **Idempotency**: bootstrap.sh must be safe to re-run without breaking anything
- **Secrets**: Never committed to git — extracted to ~/.secrets.env, git-ignored
- **chezmoi**: Dotfiles managed by chezmoi (templates, apply), not raw symlinks
- **WSL2**: Must handle WSL-specific concerns (systemd, Windows path mounts, dbus)
- **No Homebrew**: Use apt + direct binary installs on WSL2 (research recommendation)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Zsh as sole primary shell | Eliminate dual-shell maintenance, zsh has better plugins/UX | — Pending |
| antidote over Oh My Zsh | Lighter, faster, can selectively load OMZ plugins without framework bloat | — Pending |
| Starship over Powerlevel10k | p10k unmaintained, Starship is cross-shell, Rust-based, actively developed | — Pending |
| fnm over nvm | 40x faster (Rust), nvm-compatible, drop-in replacement | — Pending |
| chezmoi over manual symlinks | Templating, secrets management, multi-machine support built in | — Pending |
| No Homebrew on WSL2 | apt + direct binaries is faster and cleaner, Homebrew designed for macOS gaps | — Pending |
| Secrets in ~/.secrets.env | Simple, no external tool dependency (no 1Password CLI, etc.) | — Pending |
| No Docker test container | Faster to iterate, test manually on real machine | — Pending |
| Solid but simple bootstrap | Basic error handling + idempotency, no dry-run/resume complexity | — Pending |

---
*Last updated: 2026-02-10 after research decisions*
