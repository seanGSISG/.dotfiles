# Feature Landscape: Dotfiles Repository

**Domain:** Developer Environment Configuration Management
**Researched:** 2026-02-10
**Confidence:** MEDIUM (WebSearch-based, verified across multiple sources)

## Table Stakes

Features users expect. Missing = setup fails or feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Idempotent bootstrap script** | Must be safely re-runnable when merging changes from other machines | Medium | Core requirement for multi-machine sync. Check for existing installations before attempting changes |
| **Version control (Git)** | Track changes, sync across machines, rollback capability | Low | Industry standard. Enables backup, restore, and sync workflows |
| **Symlink management** | Link configs from repo to expected locations without copying | Medium | Either manual or tool-based (GNU Stow, chezmoi, yadm). Prevents config drift |
| **Shell configuration (.zshrc)** | Configure shell environment, PATH, aliases, prompt | Low | Core shell functionality. Users expect customized shell on new machines |
| **Git configuration (.gitconfig)** | Name, email, aliases, default editor, color scheme | Low | Every developer needs this configured |
| **Package installation automation** | Install required tools/packages on fresh machine | High | Critical for bootstrap. Must handle missing packages gracefully |
| **Safe secret handling** | Never commit API keys, tokens, credentials to repo | High | Security fundamental. Missing this = catastrophic exposure risk |
| **Host-specific configuration** | Handle differences between machines (work/personal, macOS/Linux) | Medium | Without this, dotfiles break across different environments |
| **README documentation** | Explain repo structure, installation, and usage | Low | Users need to understand how to use the dotfiles |

## Differentiators

Features that set great dotfiles repos apart. Not expected, but highly valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Modular organization by tool** | Each tool/app in separate directory/file. Easy to add/remove tools | Medium | Package-based structure (e.g., bash/, git/, tmux/). Enables selective deployment |
| **Lazy loading / async plugin loading** | Shell startup time <0.1s vs 0.5-1.0s for naive approaches | High | Critical for performance with many plugins. Zinit recommended for async loading |
| **Template generation** | Populate configs with user-specific values during bootstrap | Medium | For .gitconfig.local, host-specific settings. Prevents manual editing |
| **Dead symlink cleanup** | Automatically remove broken symlinks pointing to deleted dotfiles | Low | Quality-of-life feature. Prevents clutter over time |
| **CI/CD testing** | Test dotfiles work correctly, measure startup times | High | Catches breaking changes before deployment. Rare but impressive |
| **Separate alias files by category** | Organize 300+ aliases into domain-specific files (git.aliases, docker.aliases) | Low | Maintainability for large alias collections. Source all from main rc file |
| **Environment detection** | Auto-detect OS, hostname, WSL vs native Linux | Medium | Enables smart conditional loading without manual flags |
| **Encrypted secrets storage** | Use PGP+SOPS, password manager integration, or OS keychain | High | Allows tracking encrypted secrets in repo. PGP+SOPS is Unix-native standard |
| **Backup verification** | Script to verify all dotfiles are tracked/backed up | Low | Prevents forgetting to track important configs |
| **WSL-specific integration** | .wslconfig for memory/CPU tuning, Windows Terminal settings | Medium | For WSL2 users: improves performance, integrates with Windows tools |
| **Bootstrap hooks system** | Modular bootstrap.d/ directory with numbered scripts | Medium | Each script runs in order. Enables platform-specific bootstrap steps |
| **Custom plugin management** | Lightweight alternative to Oh My Zsh bloat | Medium | Reduces startup time. Manual management or minimal frameworks (Zinit, zplug) |

## Anti-Features

Features to explicitly NOT build. Common over-engineering traps in dotfiles.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Oh My Zsh (without cleanup)** | Adds 0.5-1.0s startup time with unnecessary bloat | Use minimal plugin manager (Zinit) with only needed plugins, or manual management |
| **Aliasing core commands** | Dangerous to override `ls`, `grep`, etc. Can break scripts | Use distinct names like `cgrep` instead of redefining `grep` |
| **Monolithic .zshrc** | 1000+ line files are unmaintainable | Split into sourced modules: aliases.zsh, functions.zsh, exports.zsh, plugins.zsh |
| **Committing secrets in plain text** | Catastrophic security exposure. Most common leak = GitHub API keys | Use .gitignore + separate secrets file, or encrypt with PGP+SOPS |
| **Manual symlink tracking** | Error-prone, hard to verify completeness | Use GNU Stow, chezmoi, yadm, or bare git method |
| **Platform-specific branches** | Merge conflicts, maintenance nightmare | Use conditional loading in single branch: `if [[ "$OSTYPE" == "darwin"* ]]` |
| **Copying entire configs from others** | May not suit your workflow, contains unknown behaviors | Understand each config before adopting. Build incrementally |
| **No idempotency** | Bootstrap breaks on re-run, can't safely update | Add existence checks: `if ! command -v tool &> /dev/null; then install; fi` |
| **Hardcoded absolute paths** | Breaks when username changes or sharing with others | Use `$HOME`, `$(pwd)`, relative paths |

## Feature Dependencies

```
Core Foundation
├── Git repository setup
├── Directory structure (~/dotfiles/)
└── .gitignore (for secrets)

Bootstrap Layer
├── Idempotency checks → Safe re-execution
├── Package manager detection → Package installation
└── OS/host detection → Platform-specific config

Configuration Layer
├── Symlink management → Config deployment
├── Template generation → Host-specific values
└── Modular sourcing → Maintainable configs

Security Layer
├── Secret detection → .gitignore enforcement
└── Encryption setup → Secure secret storage
```

**Critical path:**
1. Git repo + directory structure (foundational)
2. Bootstrap script with idempotency (enables safe iteration)
3. Symlink management (deploys configs)
4. Secret handling (prevents disasters)
5. Everything else (optimizations)

## Feature Categories by Use Case

### Minimal Viable Dotfiles (1-2 hours setup)
**Goal:** Basic portability for 1-2 machines

Must have:
- Git repo with .gitignore
- Manual symlinks or simple script
- .zshrc with aliases
- .gitconfig
- Basic bootstrap.sh (install packages, create symlinks)
- Secrets in .gitignore'd file

Skip:
- Advanced tools (Stow, chezmoi)
- Modular organization
- Encryption

### Professional Dotfiles (1 day setup)
**Goal:** Production-ready for 3-5 machines, team sharing

Must have:
- GNU Stow or chezmoi for symlink management
- Idempotent bootstrap script
- Modular config organization (by tool)
- Separate alias files by category
- Template generation for host-specific values
- Basic host detection
- README with installation instructions

Nice to have:
- Dead symlink cleanup
- Encrypted secrets (PGP+SOPS)

### Power User Dotfiles (ongoing refinement)
**Goal:** Maximum efficiency, shared publicly

All professional features plus:
- Async/lazy plugin loading for <0.1s startup
- CI testing (GitHub Actions)
- Bootstrap hooks system (bootstrap.d/)
- Comprehensive alias organization (10+ category files)
- Password manager integration
- Backup verification script
- WSL-specific optimizations (if applicable)
- Performance monitoring

## WSL2-Specific Features

For dotfiles targeting WSL2 Ubuntu:

| Feature | Purpose | Priority |
|---------|---------|----------|
| `.wslconfig` management | Control memory/CPU allocation to WSL2 | High |
| Windows Terminal settings | Integrate WSL shell into Windows Terminal | Medium |
| Windows PATH integration | Access Windows tools from WSL | Medium |
| systemd configuration | Enable systemd in WSL2 (if needed) | Low |
| Docker Desktop integration | Share Docker daemon between Windows/WSL | Medium |
| Windows-Linux symlinks | Link to Windows directories safely | Low |
| Git credential sharing | Use Windows credential manager from WSL | High |

**Common pattern:** Detect WSL with `if grep -qi microsoft /proc/version; then`

## Zsh Configuration Features

For well-organized .zshrc (targeting 308-line aliases file):

### Organization Strategy
```
~/.zshrc                    # Main config, sources others
~/.zsh/
├── exports.zsh            # Environment variables, PATH
├── aliases/
│   ├── git.zsh           # Git aliases (30-50 aliases)
│   ├── docker.zsh        # Docker/container aliases
│   ├── navigation.zsh    # cd shortcuts, directory aliases
│   ├── utilities.zsh     # General system utilities
│   └── dev.zsh           # Development tools (nvm, bun, uv)
├── functions.zsh          # Shell functions (complex logic)
├── plugins.zsh            # Plugin loading (minimal set)
└── local.zsh             # Machine-specific (gitignored)
```

### Essential Zsh Features
| Feature | Why | Implementation |
|---------|-----|----------------|
| **Plugin management** | Async loading, performance | Zinit (fastest) or manual sourcing |
| **Autosuggestions** | Command history suggestions | zsh-autosuggestions plugin |
| **Syntax highlighting** | Visual feedback on commands | zsh-syntax-highlighting plugin |
| **fzf integration** | Fuzzy command/file search | fzf + key bindings |
| **zoxide integration** | Smart cd replacement | eval "$(zoxide init zsh)" |
| **Command history tuning** | Large history, deduplication | HISTSIZE=50000, HISTDUP=erase |
| **Completion system** | Fast, cached completions | compinit with cache |

### Alias Organization Best Practices
For managing 308 aliases:

1. **Categorize by domain** (7-10 files, 20-50 aliases each)
2. **Document complex aliases** with inline comments
3. **Use functions for interpolation** (when args not at end)
4. **Avoid overriding core commands** (use prefixes: g=git, d=docker)
5. **Keep simple, memorable** (optimize for typing frequency)

Example structure for 308 aliases:
```
git.zsh       (~60 aliases) - g, ga, gc, gp, gst, etc.
docker.zsh    (~40 aliases) - d, dps, drm, dex, etc.
navigation.zsh (~30 aliases) - .., ..., project shortcuts
utilities.zsh  (~50 aliases) - ls variants, grep, find
dev.zsh       (~40 aliases) - npm, node, python, bun
kubernetes.zsh (~30 aliases) - k, kgp, kgn, etc.
system.zsh    (~30 aliases) - systemctl, package managers
misc.zsh      (~28 aliases) - everything else
```

## Secret Management Patterns

For handling API keys, tokens, credentials:

### Approach 1: Local Env File (Simplest)
```bash
# .zshrc
[ -f ~/.secrets ] && source ~/.secrets

# .gitignore
.secrets

# ~/.secrets (gitignored)
export GITHUB_TOKEN="ghp_xxx"
export OPENAI_API_KEY="sk-xxx"
```
**Pros:** Simple, fast
**Cons:** No backup, manual sync across machines

### Approach 2: Encrypted in Repo (Recommended)
```bash
# Use PGP + SOPS
# .secrets.enc (committed)
# Decrypt during bootstrap or shell init
```
**Pros:** Backed up, synced, secure
**Cons:** Setup complexity, requires GPG key

### Approach 3: Password Manager Integration
```bash
# Use op (1Password CLI), pass, or macOS Keychain
export GITHUB_TOKEN=$(op read "op://Personal/GitHub/token")
```
**Pros:** Centralized secret management
**Cons:** Requires external tool, slower startup

### Approach 4: Runtime Injection (Advanced)
```bash
# Secrets injected via CI/CD variables or external secrets manager
# Dotfiles contain NO secrets, even encrypted
```
**Pros:** Maximum security
**Cons:** Requires infrastructure

**Recommendation for solo dev:** Start with Approach 1, upgrade to Approach 2 when ready to make repo public.

## Bootstrap Script Features

Essential capabilities for bootstrap.sh:

| Feature | Why | Implementation Example |
|---------|-----|----------------------|
| **Idempotency checks** | Safe re-runs | `if ! command -v brew &> /dev/null; then install; fi` |
| **OS detection** | Platform-specific installs | `case "$OSTYPE" in darwin*) brew install;; esac` |
| **Package manager bootstrap** | Install package manager if missing | Install Homebrew on macOS, apt on Ubuntu |
| **Tool installation** | Install core tools | nvm, bun, uv, fzf, zoxide, tmux, gh |
| **Symlink creation** | Deploy configs | GNU Stow or manual ln -sf |
| **Git config setup** | Prompt for name/email | sed templates to create .gitconfig.local |
| **Directory creation** | Ensure expected dirs exist | mkdir -p ~/projects ~/.config |
| **Backup existing configs** | Don't overwrite silently | mv existing to .backup/ |
| **Verification** | Confirm successful setup | Check each tool installed correctly |
| **Error handling** | Fail gracefully | set -e, check exit codes |

**Structure for complex bootstrap:**
```
script/
├── bootstrap              # Main entry point
├── install               # Package installation
├── symlink               # Symlink creation (calls Stow)
└── configure             # Post-install config (git user, secrets)
```

## MVP Recommendation

For a WSL2 Ubuntu dotfiles repo with 308 aliases, prioritize:

**Phase 1: Foundation (Day 1)**
1. Git repo with proper .gitignore
2. Modular .zshrc structure (split aliases into 6-8 files)
3. Basic idempotent bootstrap.sh
4. Secret handling (local .secrets file, gitignored)
5. Manual or GNU Stow symlinks

**Phase 2: Automation (Day 2)**
6. Template generation for host-specific configs
7. Tool installation automation (nvm, bun, uv, fzf, zoxide, tmux, gh)
8. WSL2-specific config (.wslconfig, Windows Terminal)

**Phase 3: Polish (Ongoing)**
9. Async plugin loading for performance
10. Dead symlink cleanup
11. Encrypted secrets (PGP+SOPS)
12. Bootstrap verification script

**Defer to post-MVP:**
- CI/CD testing (low value for personal dotfiles)
- Complex host detection (handle manually initially)
- Password manager integration (unless already using)
- Public sharing features (until proven stable)

## Sources

**Dotfiles Best Practices:**
- [Atlassian: How to Store Dotfiles](https://www.atlassian.com/git/tutorials/dotfiles)
- [Daytona: Ultimate Guide to Dotfiles](https://www.daytona.io/dotfiles/ultimate-guide-to-dotfiles)
- [GitHub: awesome-dotfiles](https://github.com/webpro/awesome-dotfiles)
- [dotfiles.github.io](https://dotfiles.github.io/)
- [ArchWiki: Dotfiles](https://wiki.archlinux.org/title/Dotfiles)

**Bootstrap Automation:**
- [dotfiles.github.io: Bootstrap repositories](https://dotfiles.github.io/bootstrap/)
- [GitHub: holman/dotfiles bootstrap](https://github.com/holman/dotfiles/blob/master/script/bootstrap)
- [GitHub: Xe0n0/dotfiles - Idempotent bootstrap](https://github.com/Xe0n0/dotfiles)
- [yadm: Bootstrap documentation](https://yadm.io/docs/bootstrap)

**Zsh Configuration:**
- [Scott Spence: My Updated ZSH Config 2025](https://scottspence.com/posts/my-updated-zsh-config-2025)
- [SitePoint: 10 Zsh Tips & Tricks](https://www.sitepoint.com/zsh-tips-tricks/)
- [FreeCodeCamp: How Do Zsh Configuration Files Work?](https://www.freecodecamp.org/news/how-do-zsh-configuration-files-work/)

**Secret Management:**
- [Medium: Organizing your dotfiles - managing secrets](https://medium.com/@htoopyaelwin/organizing-your-dotfiles-managing-secrets-8fd33f06f9bf)
- [ArjanCodes: Environment Variables & Dotfiles for Secure Projects](https://arjancodes.com/blog/secure-configuration-management-using-environment-variables-and-dotfiles/)
- [Manage Sensitive API Keys in Public Dotfiles Using PGP and SOPS](https://blog.shaishav.kr/2024/09/11/manage-sensitive-api-keys-in-public-dotfiles-using-pgp-and-sops/)

**WSL2 Configuration:**
- [Microsoft Learn: Advanced settings configuration in WSL](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)
- [GitHub: Alex-D/dotfiles - Windows + WSL 2](https://github.com/Alex-D/dotfiles)
- [GitHub: wsl-home-guide](https://github.com/0-mostafa-rezaee-0/wsl-home-guide)

**Alias Management:**
- [nixCraft: 30 Handy Bash Shell Aliases](https://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)
- [Network World: How to best set up command aliases on Linux](https://www.networkworld.com/article/969860/how-to-best-set-up-command-aliases-on-linux.html)
