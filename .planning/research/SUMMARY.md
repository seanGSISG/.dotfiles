# Project Research Summary

**Project:** Dotfiles Management & WSL2 Bootstrap System
**Domain:** Developer Environment Configuration Management
**Researched:** 2026-02-10
**Confidence:** HIGH

## Executive Summary

This project aims to create a modern, maintainable dotfiles management system optimized for WSL2 Ubuntu development environments. The research reveals a clear industry shift toward lightweight, performance-focused tooling: **chezmoi** has replaced GNU Stow for dotfile management, **Starship** has superseded Powerlevel10k (which is on life support), **antidote** provides plugin management without Oh My Zsh bloat, and **fnm** delivers 40x faster Node version management than nvm. The architecture should be topic-based with modular shell configuration, avoiding the monolithic anti-patterns that plague legacy dotfiles.

The recommended approach is a phased migration strategy that doesn't disrupt the current working environment. Start by establishing the repository structure and extracting secrets (critical for security), then migrate configurations incrementally with comprehensive idempotency checks. The bootstrap script must handle the complex dependency chain (apt → Homebrew → Oh My Zsh → plugins → tools) while remaining safe to re-run. Performance optimization through lazy loading is essential - naive Oh My Zsh configurations can balloon shell startup from <1s to 5-10s, making the terminal unusable.

Critical risks include accidentally committing secrets to Git (permanent exposure), clobbering existing configurations without backup (data loss), and bash-to-zsh migration pitfalls like array indexing differences. These are mitigated through pre-commit hooks, timestamped backups, and systematic testing. The 308-line aliases file requires careful categorization into 6-8 focused modules rather than a monolithic dump. WSL2-specific concerns around Windows PATH pollution and interop must be addressed early through `/etc/wsl.conf` configuration.

## Key Findings

### Recommended Stack

The 2026 dotfiles ecosystem has consolidated around performance-oriented, actively maintained tools. The core stack consists of **chezmoi 2.69.3+** for dotfile management (templates, secrets, idempotency by design), **Starship** for shell prompts (Rust-based, cross-shell, actively maintained unlike Powerlevel10k), **antidote** for zsh plugin management (native zsh, generates static files, selective Oh My Zsh plugin loading), and **fnm** for Node version management (40x faster than nvm, Rust implementation).

**Core technologies:**
- **chezmoi**: Dotfiles manager — templates for multi-machine configs, built-in secrets management, single binary with no dependencies, beats stow/yadm for maintainability
- **Starship**: Shell prompt — Rust-based performance, active development, cross-shell support (p10k is unmaintained)
- **antidote**: Zsh plugin manager — generates static plugin file for fast loads, works with OMZ plugins selectively without framework bloat
- **fnm**: Node version manager — 40x faster than nvm, Rust-based, nvm-compatible, handles .nvmrc files
- **apt**: Package management — native Ubuntu integration, avoid Homebrew on WSL2 (adds 200MB+ complexity)
- **uv**: Python tooling — user already has, modern fast package manager
- **bun**: JavaScript runtime — user already has for performance

**Critical version requirements:**
- chezmoi 2.69.3+ (released Jan 2026, stable templating)
- Starship latest (active development, no pinning needed)
- fnm latest (rapid iteration, backward compatible)

### Expected Features

Dotfiles repositories have clear table stakes requirements and known differentiators. The research identifies critical foundation features versus optimization features.

**Must have (table stakes):**
- Idempotent bootstrap script — must be safely re-runnable for multi-machine sync
- Version control (Git) — track changes, sync, rollback capability
- Symlink management — link configs from repo to expected locations (manual or tool-based)
- Shell configuration (.zshrc) — PATH, aliases, prompt setup
- Git configuration (.gitconfig) — name, email, aliases, editor
- Package installation automation — install required tools on fresh machine
- Safe secret handling — never commit API keys/tokens to repo
- Host-specific configuration — handle differences between machines (work/personal, different OSes)

**Should have (competitive):**
- Modular organization by tool — each tool in separate directory/file for maintainability
- Lazy loading / async plugin loading — shell startup <0.1s vs 0.5-1.0s naive approaches
- Template generation — populate configs with user-specific values during bootstrap
- Dead symlink cleanup — automatically remove broken symlinks
- Separate alias files by category — organize 300+ aliases into domain-specific files
- Environment detection — auto-detect OS, hostname, WSL vs native
- WSL-specific integration — .wslconfig, Windows Terminal settings, credential sharing
- Bootstrap hooks system — modular bootstrap.d/ directory with numbered scripts

**Defer (v2+):**
- CI/CD testing — low value for personal dotfiles, add if sharing publicly
- Encrypted secrets storage (PGP+SOPS) — start with .secrets.env file, upgrade later
- Password manager integration — unless already using 1Password/Bitwarden CLI
- Backup verification scripts — nice to have, not essential for MVP

**Anti-features to avoid:**
- Oh My Zsh without cleanup — adds 0.5-1.0s startup bloat, use minimal plugin manager instead
- Aliasing core commands — dangerous to override ls/grep, use distinct names
- Monolithic .zshrc — 1000+ line files unmaintainable, split into sourced modules
- Committing secrets in plain text — catastrophic exposure, use .gitignore + separate file
- Manual symlink tracking — error-prone, use GNU Stow/chezmoi/yadm
- Platform-specific branches — merge hell, use conditional loading in single branch
- No idempotency — bootstrap breaks on re-run, can't safely update
- Hardcoded absolute paths — breaks portability, use $HOME/$USER

### Architecture Approach

The recommended architecture is a **topic-based directory structure** with **modular shell configuration** and **idempotent bootstrap orchestration**. This beats bare git repositories (too complex), Dotbot (unnecessary abstraction), and unstructured approaches (unmaintainable).

**Major components:**
1. **Bootstrap orchestrator** (bootstrap.sh) — main entry point, orchestrates installation, calls helper scripts, implements idempotency checks for all operations
2. **Topic directories** (zsh/, git/, tmux/, etc.) — group related configs, enable selective deployment, clear organization
3. **Modular .zshrc loader** — sources .zsh.d/*.zsh in order (00-exports, 05-paths, 10-nvm, 20-tools, 30-aliases, 40-functions, 99-wsl), prevents monolithic config
4. **Package lists** (packages/*.txt, Brewfile) — declarative tool declarations, version controlled, read by install scripts
5. **Install scripts** (scripts/install-*.sh) — focused installers for categories (packages, OMZ, plugins), called by bootstrap
6. **Symlink manager** (scripts/create-symlinks.sh) — creates safe symlinks from dotfiles to $HOME, uses ln -sfn for idempotency
7. **Secrets template** (secrets/.secrets.env.example) — documents required secrets without committing them, .secrets.env is gitignored
8. **Machine detection** (scripts/machine-detect.sh) — identifies OS/platform for conditional logic

**Data flow:**
- Installation: bootstrap.sh → machine detection → backup existing → install dependencies → create symlinks → print post-install checklist
- Shell loading: .zshenv → .zshrc → .zsh.d/*.zsh (alphabetical) → .secrets.env → Oh My Zsh → ready
- Update: git pull → bootstrap.sh (idempotent, skips installed, adds new) → refresh symlinks

**Key patterns:**
- Idempotent checks: `command -v`, `dpkg -l`, `[ -d ]`, `[ -f ]` before all operations
- Safe symlinks: `ln -sfn` (symbolic, force, no-dereference) with absolute paths
- Platform detection: WSL vs Mac vs Linux conditional loading
- Lazy loading: NVM wrapped in function, only loads on first use (70x faster)
- Modular sourcing: `for config in .zsh.d/*.zsh; do source "$config"; done`

### Critical Pitfalls

The research identified 12 pitfalls ranging from critical (data loss) to minor (annoyance). The top 5 that will derail this project:

1. **Clobbering existing configuration files** — During checkout/symlink creation, existing configs get overwritten without backup. Prevention: Create timestamped backup directory, backup all .*rc/.*profile files before any operations, use `stow --no-folding` (fails safely on conflict) or check for conflicts before git checkout.

2. **Secrets committed to Git history** — API keys, tokens embedded in shell configs get committed. Even after removal, they remain in history forever. Prevention: Set up .gitignore BEFORE first commit, install git-secrets or pre-commit hooks with detect-secrets/gitleaks, externalize secrets to gitignored .secrets file sourced at runtime, never skip pre-commit hooks.

3. **Non-idempotent bootstrap script** — Script fails on second run, creates duplicate PATH entries, double-sources files, installs packages multiple times. Prevention: Check before action pattern (`if ! command -v tool; then install; fi`), use grep -qF to check before appending to files, verify symlink target before creating, test by running bootstrap twice.

4. **Bash-to-zsh array indexing trap** — Bash arrays start at index 0, zsh arrays start at index 1. Direct copy-paste breaks silently. Prevention: Audit 308-line aliases file for `[0]` or `[\d+]` patterns, prefer iteration over indexing (`for item in "${arr[@]}"`), consider `setopt KSH_ARRAYS` but this breaks zsh plugins.

5. **PATH ordering catastrophes** — Wrong binary executes because search order incorrect, system commands shadowed, security risk if current directory in PATH. Prevention: Document priority order (user bins → version managers → system), use prepend for higher priority (`export PATH="$HOME/.local/bin:$PATH"`), WSL2: disable Windows PATH in /etc/wsl.conf and manually add needed tools, debug with `which -a <command>`.

**Moderate pitfalls (cause delays):**
- Oh My Zsh startup performance collapse (5-10s) — lazy load NVM, minimize plugins, optimize compinit
- WSL2 Windows PATH pollution — Linux commands find Windows executables, configure /etc/wsl.conf early
- Symlink direction confusion — symlinks point wrong way, use absolute paths or GNU Stow
- Oh My Zsh plugin conflicts — overlapping functionality, document load order (syntax-highlighting MUST be last)
- NVM not found in zsh — not sourced correctly, use zsh-nvm plugin with lazy loading

## Implications for Roadmap

Based on research, the project should be structured in 5-6 phases following dependency order and risk mitigation. Early phases establish foundation and safety, middle phases migrate configurations, late phases optimize.

### Phase 1: Repository Foundation & Secret Safety
**Rationale:** Must establish Git structure and security guardrails BEFORE any commits to prevent permanent secret exposure. Creating backups before any file operations prevents data loss.
**Delivers:** Git repository with proper .gitignore, secret detection hooks, timestamped backups, README with setup instructions
**Addresses:** Secret handling (table stakes), version control (table stakes)
**Avoids:** Pitfall #2 (secrets in Git), Pitfall #1 (file clobbering) through backup strategy

### Phase 2: Package Lists & Tool Inventory
**Rationale:** Document current state before migration. Generates apt-packages.txt, Brewfile, identifies all tools to preserve. Low risk, preserves current working state.
**Delivers:** Declarative package lists, tool inventory, documentation of current environment
**Addresses:** Package installation automation (table stakes)
**Avoids:** Nothing gets installed yet, pure documentation phase

### Phase 3: Modular Shell Configuration
**Rationale:** Extract and organize 308-line aliases file into 6-8 focused modules. This is complex work that benefits from having Git safety net established. Audit for bash-to-zsh incompatibilities here.
**Delivers:** Modular .zshrc structure (.zsh.d/), categorized aliases (git.zsh, docker.zsh, navigation.zsh, utilities.zsh, dev.zsh, system.zsh), functions.zsh, exports.zsh
**Addresses:** Shell configuration (table stakes), modular organization (differentiator), separate alias files by category (differentiator)
**Avoids:** Pitfall #4 (array indexing) through audit, monolithic config anti-pattern

### Phase 4: Core Config Files
**Rationale:** Individual tool configs (git, tmux) are independent and low risk. Can be created/tested in parallel. No complex dependencies.
**Delivers:** git/.gitconfig, git/.gitignore_global, tmux/.tmux.conf, bash/.bashrc (fallback)
**Addresses:** Git configuration (table stakes)
**Avoids:** Low risk phase, establishes foundation for later phases

### Phase 5: Bootstrap Script Development
**Rationale:** Now that configs exist, build the installer. Must implement comprehensive idempotency from day one. This is high complexity requiring all prior work complete.
**Delivers:** Idempotent bootstrap.sh orchestrator, install scripts (install-packages.sh, install-omz.sh, create-symlinks.sh), machine detection
**Addresses:** Idempotent bootstrap (table stakes), package installation automation (table stakes), environment detection (differentiator)
**Avoids:** Pitfall #3 (non-idempotent) through check-before-action pattern, Pitfall #5 (PATH) through documented priority order
**Uses:** apt for system packages, avoids Homebrew on WSL2 (per STACK.md research)

### Phase 6: Performance Optimization
**Rationale:** Only after basic setup works. Focus on lazy loading, plugin optimization, startup time measurement.
**Delivers:** Lazy-loaded NVM, optimized compinit, minimal plugin set, zprof profiling setup, instant prompt configuration
**Addresses:** Lazy loading (differentiator), async plugin loading (differentiator)
**Avoids:** Pitfall #6 (OMZ performance collapse) through lazy loading patterns

### Phase Ordering Rationale

- **Security first:** Phase 1 establishes Git safety net before ANY commits
- **Document before modify:** Phase 2 captures current state before changes
- **Complex work with safety net:** Phase 3 tackles alias migration after Git established
- **Independent work in parallel:** Phase 4 creates configs that don't depend on each other
- **Integration last:** Phase 5 builds bootstrap only after all pieces exist
- **Optimization at end:** Phase 6 optimizes working system, not blocking for MVP

**Dependency chain from research:**
1. Git → curl (to download installers)
2. System packages (apt-packages.txt)
3. Homebrew (optional, skip for WSL2 per STACK.md)
4. Zsh (shell itself)
5. Oh My Zsh (depends on zsh + git + curl)
6. Zsh plugins (depends on OMZ)
7. Powerlevel10k/Starship (depends on OMZ)
8. NVM (independent but needed before Node)
9. Node (depends on NVM)
10. Other tools (fzf, zoxide, mostly independent)
11. Symlinks (should be last to ensure all dependencies exist)
12. Secrets file creation (manual post-install)

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 3:** Bash-to-zsh alias compatibility — audit 308 aliases for array indexing, parameter expansion, glob patterns. May need case-by-case testing.
- **Phase 5:** WSL2-specific configurations — /etc/wsl.conf settings, Windows Terminal integration, PATH filtering. Check Microsoft WSL docs for latest best practices.
- **Phase 5:** Idempotency patterns for Oh My Zsh plugin installation — git clone vs oh-my-zsh installer, how to check if plugin exists, symlink strategy for custom/ directory.

Phases with standard patterns (skip research-phase):

- **Phase 1:** Git setup is well-documented, pre-commit hooks have official docs
- **Phase 2:** Package list generation is straightforward (dpkg -l, brew bundle dump)
- **Phase 4:** Individual tool configs follow established formats
- **Phase 6:** Performance optimization patterns well-documented in Oh My Zsh issues

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified with official docs, chezmoi 2.69.3 released Jan 2026, active development confirmed for Starship/fnm/antidote |
| Features | MEDIUM | Based on web search of dotfiles best practices, community consensus clear but not official documentation |
| Architecture | HIGH | Topic-based structure is dotfiles community standard, multiple authoritative sources (Atlassian, ArchWiki, thoughtbot) |
| Pitfalls | HIGH | Verified with official sources (AWS git-secrets, Microsoft WSL docs, Oh My Zsh GitHub issues, bash/zsh documentation) |

**Overall confidence:** HIGH

The stack recommendations are backed by official documentation and 2026 release notes. Architecture patterns come from established community consensus (dotfiles.github.io, ArchWiki, multiple production repositories). Pitfalls are documented in official sources (Microsoft WSL troubleshooting, git-secrets README, zsh manual).

The medium confidence on features reflects that "table stakes" and "differentiators" are community-derived classifications rather than official specifications, but the patterns are consistent across 10+ dotfiles guides.

### Gaps to Address

The research reveals a few areas requiring validation during implementation:

- **Symlink strategy for Oh My Zsh custom/ directory:** Research shows multiple approaches (symlink entire directory vs individual files, symlink to ~/.oh-my-zsh/custom/ vs custom plugin paths). Need to test which works best with OMZ update mechanism. Test during Phase 5 bootstrap development.

- **fnm vs mise decision:** Research recommends fnm for Node-only, mise for polyglot (Node + Python + Ruby). User already has uv for Python, so fnm is likely sufficient. However, if user later needs Ruby/Go/other languages, mise consolidates everything. Decision: Start with fnm, document migration path to mise if needed.

- **Starship vs Powerlevel10k timing:** Research confirms p10k is "on life support" with no active development, but it still works and has instant prompt feature. User currently has p10k. Migration timing: Phase 3 can keep p10k temporarily, Phase 6 migrates to Starship as optimization step (not blocking).

- **Homebrew on WSL2 decision:** Research strongly recommends avoiding Homebrew on WSL2 (apt is faster, native, simpler). However, user might have existing Homebrew setup. Bootstrap should detect and support both, but default to apt for new installs. Validate during Phase 2 tool inventory.

- **Antidote vs zinit vs manual plugin management:** Research shows antidote is cleaner and faster than zinit without turbo mode. User currently has Oh My Zsh. Migration strategy: Phase 3 keeps OMZ but cherry-picks plugins, Phase 6 can optionally migrate to antidote if OMZ bloat becomes issue. Not blocking for MVP.

## Sources

### Primary (HIGH confidence)

**Stack Research:**
- chezmoi official docs (chezmoi.io) — verified v2.69.3 release Jan 2026
- Starship official docs (starship.rs) — active development confirmed
- fnm GitHub (github.com/Schniz/fnm) — 40x performance vs nvm benchmark
- antidote official docs (antidote.sh) — native zsh implementation details
- zsh plugin manager benchmark (github.com/rossmacarthur/zsh-plugin-manager-benchmark) — objective performance data

**Architecture Research:**
- Atlassian Git Tutorial: How to Store Dotfiles — bare git vs symlink approaches
- ArchWiki: Dotfiles — community-vetted patterns
- dotfiles.github.io — curated best practices
- GNU Stow manual (gnu.org/software/stow/) — symlink semantics
- thoughtbot/dotfiles — production implementation example

**Pitfalls Research:**
- Microsoft Learn: WSL Troubleshooting & Advanced Settings — official WSL2 guidance
- AWS Labs git-secrets GitHub — official secret detection tool
- Oh My Zsh Issues #5327 — performance investigation with profiling
- Zsh Manual: Arrays — official bash vs zsh indexing documentation

### Secondary (MEDIUM confidence)

**Features Research:**
- Daytona: Ultimate Guide to Dotfiles — feature categorization
- GitHub awesome-dotfiles — community patterns
- yadm.io bootstrap docs — automation patterns
- Scott Spence: My Updated ZSH Config 2025 — recent community example

**Stack Research:**
- "Powerlevel10k is on Life Support" blog post (hashir.blog) — maintainer status
- NVM Alternatives Guide (betterstack.com) — fnm comparison
- Mise vs asdf (betterstack.com) — polyglot version manager comparison

**Pitfalls Research:**
- "How to write idempotent Bash scripts" (arslan.io) — idempotency patterns
- Medium articles on dotfiles security — secret management approaches
- SitePoint: 10 Zsh Tips & Tricks — shell configuration advice

### Tertiary (LOW confidence)

- Various GitHub dotfiles repositories — implementation examples, but need validation for specific use cases
- Blog posts on WSL2 optimization — anecdotal, need testing in specific environment
- Stack Overflow discussions — useful patterns but not authoritative

---
*Research completed: 2026-02-10*
*Ready for roadmap creation: yes*
