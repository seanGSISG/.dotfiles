# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-10)

**Core value:** One command (`bootstrap.sh`) sets up a fresh WSL2 Ubuntu machine with the complete dev environment — zsh with Starship prompt, all tools installed, all configs managed by chezmoi, ready to code.

**Current focus:** Phase 5.1 - Bootstrap Folders & Claude Code Command Center (next)

## Current Position

Phase: 5.1 of 6 in progress (Phase 5.1 - Bootstrap Folders & Claude Code Command Center)
Plan: 3 of 6 complete in Phase 5.1
Status: In progress
Last activity: 2026-02-11 — Completed 05.1-01-PLAN.md (Workspace Folders & Claude Installer)

Progress: [███████████████████░] 95% overall (19/20 plans complete)

## Performance Metrics

**Velocity:**
- Total plans completed: 19
- Average duration: 1.9 min
- Total execution time: 0.65 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Repository Foundation & Safety | 3 | 10 min | 3.3 min |
| 2. Package Management & Tool Inventory | 2 | 2 min | 1.0 min |
| 2.1. Repository Consolidation | 2 | 4 min | 2.0 min |
| 3. Shell Configuration | 4 | 5.5 min | 1.4 min |
| 4. Tool Configs | 2 | 3.6 min | 1.8 min |
| 5. Bootstrap Implementation | 2 | 6.6 min | 3.3 min |
| 5.1. Bootstrap Folders & Claude Command Center | 3 | 8 min | 2.7 min |

**Recent Trend:**
- Last 5 plans: [05-01: 2.1min, 05-02: 4.5min, 05.1-01: 2min, 05.1-02: 2min, 05.1-01: 4min]
- Trend: Phase 5.1 completing workspace and Claude Code setup

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Zsh as sole primary shell (eliminate dual-shell maintenance)
- antidote over Oh My Zsh (lighter, faster, selective plugin loading)
- Starship over Powerlevel10k (p10k unmaintained, Starship actively developed)
- fnm over nvm (40x faster, Rust-based)
- chezmoi over manual symlinks (templating, secrets management, multi-machine support)
- No Homebrew on WSL2 (apt + direct binaries is cleaner)
- Secrets in age-encrypted chezmoi files (no external tool dependency)
- Install chezmoi from official installer (not apt) to get latest v2.x (01-01)
- Store age key at ~/key.txt outside git, never committed to version control (01-01)
- Use GitHub releases for age when sudo not available (01-01)
- Use detect-secrets with baseline workflow for pre-commit scanning (01-02)
- Use pipx to install detect-secrets (not pip, due to externally-managed environment) (01-02)
- Extract all inline secrets into single ~/.secrets.env file (01-02)
- Use chezmoi template variables for machine-specific values in config (01-03)
- Keep README practical (~100-150 lines, not enterprise docs) (01-03)
- Include .planning/ in the chezmoi repo for project history (01-03)
- Curate apt packages from 101 to 34 by removing GUI/desktop and base system packages (02-01)
- Store package manifests in chezmoi repo but exclude from apply (repo-only files) (02-01)
- Annotate all packages with purpose, repo source, and auth requirements (02-01)
- Curate uv tools list - exclude experimental AI tools (02-02)
- Document Node.js LTS 22.x via fnm (not direct install) (02-02)
- Use structured format for binary-installs.txt (02-02)
- Chezmoi repo is primary - keeps commit hashes unchanged (02.1-01)
- Home repo .planning/ commits merged via merge commit with --allow-unrelated-histories (02.1-01)
- Use main branch (chezmoi repo branch) as primary branch (02.1-01)
- Relocate age key to ~/.config/age/keys.txt (XDG-compliant path) (02.1-01)
- Package manifests stored in packages/ subdirectory for clear organization (02.1-02)
- Force-pushed unified history to GitHub to establish single source of truth (02.1-02)
- Cleaned up all stale repos and artifacts (~/git, ~/.planning, ~/.local/share/chezmoi, ~/key.txt) (02.1-02)
- Auto-install antidote if missing for graceful fresh machine setup (03-01)
- Day-based .zcompdump caching to optimize completion init time (03-01)
- Single authoritative PATH in exports.zsh (no duplication across files) (03-01)
- 100k history entries with comprehensive deduplication (8 setopts) (03-01)
- Use command -v checks for graceful tool loading (tools load only if installed) (03-02)
- Use chezmoi .tmpl suffix with template guards for WSL2-conditional deployment (03-02)
- fnm loaded with --use-on-cd flag for automatic Node version switching (03-02)
- fzf integration uses fallback pattern: ~/.fzf.zsh then fzf --zsh (03-02)
- WezTerm OSC 7 uses native shell-integration if available, else custom implementation (03-02)
- Split aliases into 6 category files (navigation, docker, git, dev, utilities, system) (03-03)
- Dynamic alias-help system reads files directly to stay in sync (03-03)
- Remove hardcoded project paths from aliases for portability (03-03)
- Shell-agnostic reload function detects zsh vs bash (03-03)
- Pure sourcer pattern: .zshrc contains only source commands (03-04)
- Shared alias pattern: bash sources same alias files from ~/.config/zsh/aliases/ (03-04)
- Fixed missing sourceDir in .chezmoi.toml.tmpl during verification (03-04)
- Use chezmoi template variables (git_name, git_email, editor) for portable git config (04-01)
- Preserve gh credential helper for GitHub authentication (04-01)
- Remove non-portable sections from gitconfig (coderabbit, gtr) (04-01)
- Add modern git defaults: main branch, autocrlf=input, autoSetupRemote (04-01)
- Use XDG-compliant paths for tmux (~/.config/tmux/ instead of ~/.tmux/) (04-02)
- Auto-clone TPM via .chezmoiexternal.toml (not manual git clone) (04-02)
- Show only virtualenv name in Python module, not version (reduce noise) (04-02)
- 5-second threshold for cmd_duration (matches P10k default) (04-02)
- Disable package and time modules in Starship (reduce noise) (04-02)
- Use tput for colored output instead of raw ANSI codes (more portable) (05-01)
- Continue-on-failure pattern with error collection for bootstrap scripts (05-01)
- Strip version constraints from apt-packages.txt during parsing (05-01)
- Try apt install for age before GitHub releases fallback (05-01)
- Install fzf from git with --no-update-rc flags (shell integration in zsh config) (05-01)
- Prefer bun over npm for Claude Code installation (faster, already installed) (05-01)
- Auto-detect GitHub repo from git remote origin (falls back to placeholder) (05-02)
- Chezmoi handles two cases: existing clone (apply) vs fresh machine (clone + apply) (05-02)
- SSH key setup is interactive (prompts for source path, skippable) (05-02)
- chsh prompts for password naturally (no automation workaround) (05-02)
- Post-install checklist has 6 items covering all manual steps (05-02)
- Continue-on-failure pattern: set +e in main, set -e after (05-02)
- exec zsh at end lands user in new shell immediately (05-02)
- Hardcoded ~/.claude/ paths in hook scripts (not CLAUDE_PLUGIN_ROOT) (05.1-02)
- "insights" directory name replaces "homunculus" (05.1-02)
- create_ prefix for ~/.claude/ configs (initial deploy only) (05.1-02)
- Linux-only deployment (WSL2 Ubuntu) (05.1-02)
- Use official Claude Code installer (claude.ai/install.sh) instead of bun/npm (05.1-01)
- Claude Code installs before chezmoi apply (configs deploy after installation) (05.1-01)
- Exclude .claude/insights/ from chezmoi management (runtime-generated data) (05.1-01)
- Workspace boundary files (CLAUDE.md) define Claude Code scope for each workspace (05.1-01)

### Pending Todos

None yet.

### Roadmap Evolution

- Phase 2.1 inserted after Phase 2: Repository Consolidation (URGENT) — unified split repositories into single source at ~/.dotfiles
- Phase 5.1 inserted after Phase 5: Bootstrap Folders & Claude Code Command Center (URGENT) — set up bootstrap folder structure and central Claude Code config

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-02-11
Stopped at: Completed 05.1-01-PLAN.md (Workspace Folders & Claude Installer)
Resume file: None
Next: Continue Phase 5.1 - 3 more plans (MCP servers, learning system, hooks.json/final integration)
