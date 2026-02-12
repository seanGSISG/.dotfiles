# Roadmap: Dotfiles Migration & Modernization

## Overview

This project transforms a heavily customized WSL2 Ubuntu dev environment into a chezmoi-managed, one-command reproducible setup. Starting with repository foundations and secret safety, we'll migrate shell configurations (zsh with Starship + antidote), modernize the toolchain (fnm, fzf, zoxide), extract secrets to age-encrypted storage, and build an idempotent bootstrap script that handles the full dependency chain. The result: `bootstrap.sh` on a fresh WSL2 machine installs everything and deploys all configs, ready to code.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Repository Foundation & Safety** - Establish chezmoi structure and secret management
- [x] **Phase 2: Package Management & Tool Inventory** - Generate declarative package lists
- [x] **Phase 2.1: Repository Consolidation** - Unify chezmoi source, .dotfiles, and .planning into single repo (INSERTED)
- [x] **Phase 3: Shell Configuration** - Migrate zsh/bash configs and aliases
- [x] **Phase 4: Tool Configs** - Set up git, tmux, and Starship prompt
- [x] **Phase 5: Bootstrap Implementation** - Build idempotent installer script
- [x] **Phase 5.1: Bootstrap Folders & Claude Code Command Center** - Set up bootstrap folder structure and central Claude Code config (INSERTED)
- [ ] **Phase 6: Migration & Testing** - Deploy and validate on new machine

## Phase Details

### Phase 1: Repository Foundation & Safety
**Goal**: Establish chezmoi-managed dotfiles repository with age-encrypted secret handling and safety guardrails to prevent data loss and secret exposure.

**Depends on**: Nothing (first phase)

**Requirements**: CZMOI-01, CZMOI-02, CZMOI-03, CZMOI-04, CZMOI-05, SEC-01, SEC-02, SEC-03, SEC-04, SEC-05

**Success Criteria** (what must be TRUE):
  1. Developer can run `chezmoi init` to create local dotfiles repo with proper directory structure
  2. Developer can add encrypted secrets via `chezmoi add --encrypt` and they're stored as age-encrypted files in repo
  3. Developer can run `chezmoi apply` and secrets are decrypted and applied to correct locations
  4. Secrets template (.secrets.env.example) exists in repo with placeholder values for documentation
  5. Age encryption key can be stored in Bitwarden and documented for multi-machine setup

**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md — Install chezmoi + age, backup existing dotfiles, initialize repo with age encryption (3 min)
- [x] 01-02-PLAN.md — Safety guardrails (gitignore, pre-commit hooks, detect-secrets) and secret extraction (3 min)
- [x] 01-03-PLAN.md — README, chezmoi.toml.tmpl, remote origin, initial commit and push (4 min)

### Phase 2: Package Management & Tool Inventory
**Goal**: Generate declarative package lists documenting all system packages, uv-managed tools, and direct binary installs needed for environment reproduction.

**Depends on**: Phase 1 (chezmoi structure exists to store lists)

**Requirements**: PKG-01, PKG-02, PKG-03

**Success Criteria** (what must be TRUE):
  1. File apt-packages.txt exists listing all system packages with repo sources documented
  2. File uv-tools.txt exists listing all uv-managed tools (basedpyright, pre-commit, virtualenv, just)
  3. Package lists are committed to chezmoi repo and can be consumed by bootstrap script

**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md — Auto-discover and curate apt-packages.txt from apt-mark showmanual (1 min)
- [x] 02-02-PLAN.md — Create uv-tools.txt and binary-installs.txt for non-apt tools (1 min)

### Phase 2.1: Repository Consolidation (INSERTED)
**Goal**: Consolidate the split repo structure into a single `~/.dotfiles` directory — move chezmoi source from `~/.local/share/chezmoi` to `~/.dotfiles`, merge the `.planning/` files into the same repo, and clean up the accidental home-directory git repo.

**Depends on**: Phase 2 (package lists exist in chezmoi source)

**Requirements**: (Structural fix — no new requirements, but prerequisite for clean Phase 3+ work)

**Success Criteria** (what must be TRUE):
  1. `~/.dotfiles` IS the chezmoi source directory (`chezmoi source-path` returns `~/.dotfiles`)
  2. All chezmoi files (dotfile sources, package lists, encrypted secrets) are in `~/.dotfiles`
  3. `.planning/` directory is inside `~/.dotfiles` and tracked by the same git repo
  4. `~/.dotfiles` has its own `.git` directory (single repo for everything)
  5. No git repo at `~/` (home directory is NOT a git repo)
  6. `git log` in `~/.dotfiles` shows all prior commit history preserved

**Plans**: 2 plans

Plans:
- [x] 02.1-01-PLAN.md — Move chezmoi source to ~/.dotfiles, merge home repo history, configure chezmoi sourceDir, relocate age key to XDG path (2 min)
- [x] 02.1-02-PLAN.md — Move package lists to packages/ subdirectory, clean up old repos, verify success criteria, push to GitHub (2 min)

### Phase 3: Shell Configuration
**Goal**: Migrate zsh as primary shell with antidote plugin management, Starship prompt, and modular alias system; bash becomes minimal fallback.

**Depends on**: Phase 2 (package lists establish what tools exist)

**Requirements**: SHELL-01, SHELL-02, SHELL-03, SHELL-04, SHELL-05, SHELL-06, SHELL-07, SHELL-08, SHELL-09, SHELL-10, ALIAS-01, ALIAS-02, ALIAS-03, ALIAS-04

**Success Criteria** (what must be TRUE):
  1. Developer can source .zshrc and get working zsh with antidote, Starship, fnm, fzf, zoxide loaded
  2. Developer can see 308-line aliases file split into 6-8 category files (git, docker, navigation, utilities, dev, system, misc)
  3. Developer can run alias help command (? or halp) and see categorized aliases
  4. Developer can source .bashrc and get minimal fallback with hint to use zsh
  5. All configs use $HOME or chezmoi templates, no hardcoded /home/vscode paths

**Plans**: 4 plans

Plans:
- [x] 03-01-PLAN.md -- Zsh foundation: exports.zsh (PATH, env vars, history), plugins.zsh (antidote, completion), .zsh_plugins.txt
- [x] 03-02-PLAN.md -- Tool integrations: tools.zsh (fnm, fzf, zoxide) and wsl.zsh.tmpl (GNOME Keyring, dbus, WezTerm OSC 7)
- [x] 03-03-PLAN.md -- Aliases and functions: audit + split 308-line file into 6 categories, alias-help system, shell functions
- [x] 03-04-PLAN.md -- Shell entry points: .zshrc (pure sourcer), .bashrc (fallback with banner), .profile (minimal clean)

### Phase 4: Tool Configs
**Goal**: Clean up and template git, tmux, and Starship configurations for portability and modern aesthetics.

**Depends on**: Phase 3 (shell configs reference these tools)

**Requirements**: CONF-01, CONF-02, CONF-03, STAR-01, STAR-02, STAR-03

**Success Criteria** (what must be TRUE):
  1. Developer can run git commands with cleaned-up .gitconfig that uses chezmoi templates for name/email
  2. Developer can launch tmux with cleaned-up .tmux.conf configuration
  3. Developer sees Starship prompt showing git branch/status, virtualenv, node version, command duration
  4. Starship theme is visually comparable or better than current Powerlevel10k setup

**Plans**: 2 plans (2 complete)

Plans:
- [x] 04-01-PLAN.md -- Git config templated with chezmoi variables (name, email, editor) + update .chezmoi.toml.tmpl [data] section
- [x] 04-02-PLAN.md -- Tmux config (XDG-compliant, TPM auto-install) + Starship prompt config (P10k Pure style)

### Phase 5: Bootstrap Implementation
**Goal**: Build idempotent bootstrap.sh that installs all dependencies, sets up zsh as default shell, configures WSL2, handles SSH keys, and deploys chezmoi configs.

**Depends on**: Phase 4 (all configs must exist before bootstrap can deploy them)

**Requirements**: BOOT-01, BOOT-02, BOOT-03, BOOT-04, BOOT-05, BOOT-06, BOOT-07, BOOT-08, BOOT-09, BOOT-10, BOOT-11, BOOT-12, WSL-01, WSL-02, WSL-03, SSH-01, SSH-02, SSH-03

**Success Criteria** (what must be TRUE):
  1. Developer can run bootstrap.sh twice in a row without errors (idempotency verified)
  2. Bootstrap installs all apt packages, antidote, Starship, fnm, fzf, zoxide, uv, bun, tmux plugin manager, Claude Code
  3. Bootstrap sets zsh as default shell via chsh
  4. Bootstrap backs up existing dotfiles to ~/.dotfiles-backup/[timestamp] before applying
  5. Bootstrap runs chezmoi init and apply to deploy all configs
  6. Bootstrap prints post-install checklist (age key from Bitwarden, gh auth, SSH keys, tmux prefix+I, claude login)
  7. Bootstrap copies ~/.ssh/ with correct permissions (700/600) preserving production keys
  8. WSL2-specific settings applied (/etc/wsl.conf with systemd=true, GNOME Keyring/dbus integration)

**Plans**: 2 plans

Plans:
- [x] 05-01-PLAN.md -- Scaffolding, system config, apt packages, binary tools, plugin managers, Python/Node tools (2.1 min)
- [x] 05-02-PLAN.md -- Dotfile backup, chezmoi deploy, shell change, SSH keys, summary/checklist, main() wiring (4.5 min)

### Phase 5.1: Bootstrap Folders & Claude Code Command Center (INSERTED)
**Goal**: Deploy reproducible workspace structure and complete Claude Code environment via chezmoi — workspace folders with boundary files, hook scripts, learning system, and encrypted MCP configs.

**Depends on**: Phase 5 (bootstrap script exists)

**Requirements**: (Structural enhancement — prepares environment for Claude Code workflows)

**Success Criteria** (what must be TRUE):
  1. Workspace folders (~/projects/, ~/labs/, ~/tools/, ~/tmp/, ~/command-center/) created by chezmoi apply with CLAUDE.md boundary files
  2. Central command center has CLAUDE.md with workspace map, learning system docs, and safety rules
  3. Claude Code hooks.json deployed with session + learning hooks (no linting hooks)
  4. Hook scripts (session-start, session-end, pre-compact, evaluate-session) deployed to ~/.claude/scripts/hooks/
  5. Continuous-learning-v2 skill deployed with observation hooks, instinct CLI, and observer agent
  6. MCP server configs age-encrypted and deployed via chezmoi
  7. Bootstrap.sh uses official Claude Code installer (not bun/npm)

**Plans**: 3 plans

Plans:
- [x] 05.1-01-PLAN.md — Workspace folders with CLAUDE.md boundary files + bootstrap.sh Claude Code installer update
- [x] 05.1-02-PLAN.md — Hook scripts and shared utility library for ~/.claude/scripts/
- [x] 05.1-03-PLAN.md — Claude Code config (hooks.json, settings.json), continuous-learning-v2 skill, encrypted MCP servers

### Phase 6: Migration & Testing
**Goal**: Deploy complete environment to new machine (user adminuser) and validate all functionality works end-to-end.

**Depends on**: Phase 5 (bootstrap script complete and tested)

**Requirements**: (Cross-cutting validation of all 51 requirements on new machine)

**Success Criteria** (what must be TRUE):
  1. Developer can run single bootstrap.sh command on fresh WSL2 Ubuntu and get complete working environment
  2. Developer can start new shell and see Starship prompt with all integrations working
  3. Developer can use all aliases, functions, and tools (fnm, fzf, zoxide, gh, tmux) without errors
  4. Developer can access production Azure VM via SSH with idm-prod-key
  5. Age-decrypted secrets are available in environment variables
  6. All tool configs (git, tmux) work correctly on new machine with user adminuser

**Plans**: 3 plans

Plans:
- [ ] 06-01-PLAN.md -- SSH keys into chezmoi (age-encrypted) + age key paste prompt in bootstrap
- [ ] 06-02-PLAN.md -- Bootstrap tee logging + standalone verify.sh script
- [ ] 06-03-PLAN.md -- Push, deploy on fresh machine via curl, validate with verify.sh (checkpoint)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 2.1 -> 3 -> 4 -> 5 -> 5.1 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Repository Foundation & Safety | 3/3 | Complete | 2026-02-10 |
| 2. Package Management & Tool Inventory | 2/2 | Complete | 2026-02-10 |
| 2.1 Repository Consolidation (INSERTED) | 2/2 | Complete | 2026-02-10 |
| 3. Shell Configuration | 4/4 | Complete | 2026-02-10 |
| 4. Tool Configs | 2/2 | Complete | 2026-02-10 |
| 5. Bootstrap Implementation | 2/2 | Complete | 2026-02-10 |
| 5.1 Bootstrap Folders & Claude Code Command Center (INSERTED) | 3/3 | Complete | 2026-02-11 |
| 6. Migration & Testing | 0/3 | Not started | - |

---
*Roadmap created: 2026-02-10*
*Last updated: 2026-02-12 - Phase 6 planned (3 plans in 2 waves)*
