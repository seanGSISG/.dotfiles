# Phase 2: Package Management & Tool Inventory - Research

**Researched:** 2026-02-10
**Domain:** System package management, declarative dependency lists, dotfiles infrastructure
**Confidence:** HIGH

## Summary

Phase 2 creates declarative package lists that document all system packages, uv-managed tools, and binary installs needed for environment reproduction. The research confirms that the user's chosen approach (plain text lists, apt-mark showmanual for discovery, uv for Python tools, per-method file separation) aligns with established dotfiles practices and provides the simplest parsing surface for a bash bootstrap script.

Key findings:
- **apt-mark showmanual** is the standard way to extract manually-installed packages (excluding transitive dependencies)
- **uv tool** is now the Python ecosystem's recommended replacement for pipx, with built-in isolation
- **Plain text format** (.txt files with # comments) is universally parseable and aligns with dotfiles community standards
- **Binary install methods vary** by tool: official install scripts (fnm, bun, chezmoi) vs GitHub release binaries (gh, starship, age) — both are legitimate and should be chosen per-tool

The current system has 101 manually installed apt packages. Curation within Phase 2 (review and trim before committing) will reduce noise and prevent unnecessary dependencies from being enshrined in the "bill of materials."

**Primary recommendation:** Use the planned three-file structure (apt-packages.txt, uv-tools.txt, binary-installs.txt) with inline comments explaining purpose, version constraints where needed, and post-install annotations for shell integration or manual auth steps.

## Standard Stack

### Core Tools

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| apt-mark | Built-in | Package state management | Standard dpkg/apt tooling for tracking manual vs auto-installed packages |
| uv | Latest (v0.6.x+) | Python tool isolation | Rust-based pipx replacement, 10-100x faster, now industry standard for Python tools in 2026 |
| chezmoi | v2.69.3+ | Dotfiles management | Single binary, age encryption support, templating — installed via official script for latest version |
| age | Latest | File encryption | Modern alternative to GPG, simple key format, chezmoi has built-in support |
| detect-secrets | Latest (via pipx/uv) | Pre-commit secret scanning | Yelp's enterprise-standard tool, baseline workflow prevents false positives |

### Supporting Tools

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| fnm | Latest | Node.js version manager | 40x faster than nvm, Rust-based, official install script available |
| bun | v1.3.9+ | JavaScript runtime | All-in-one toolkit (runtime, bundler, test runner, package manager) |
| gh | Latest | GitHub CLI | Official GitHub tool, APT repo available but manual binary gives version control |
| starship | Latest | Shell prompt | Cross-shell, fast, maintained (p10k is unmaintained as of user's prior decision) |
| antidote | Latest (git clone) | Zsh plugin manager | Lightweight replacement for Oh My Zsh, supports selective loading |

### Installation Methods by Tool

| Tool | Method | Rationale |
|------|--------|-----------|
| chezmoi | Official install script | APT/Snap lag behind releases, single binary benefits from official installer |
| fnm | Official install script | curl -fsSL https://fnm.vercel.app/install, requires curl + unzip |
| bun | Official install script | curl -fsSL https://bun.sh/install, canonical install method |
| gh | Official APT repo | Actively maintained by GitHub CLI team, Snap discouraged due to runtime issues |
| starship | Official install script | curl -sS https://starship.rs/install.sh, cross-platform binary installer |
| age | Direct binary or APT | Available in modern Ubuntu repos, alternatively via GitHub releases |
| antidote | git clone | git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-$HOME}/.antidote |
| uv | Official installer | curl -LsSf https://astral.sh/uv/install.sh, Rust binary with no dependencies |

**Installation pattern:**
```bash
# Official install scripts (fnm, bun, chezmoi, starship, uv)
curl -fsSL [script-url] | bash

# APT with official repo (gh)
# Add repo, then apt install gh

# Git clone (antidote)
git clone --depth=1 [repo-url] [destination]

# Direct binary download (age, alternative for others)
# Download from GitHub releases, verify checksum, install to PATH
```

## Architecture Patterns

### Recommended File Structure

```
.dotfiles/
├── apt-packages.txt          # System packages (apt install)
├── uv-tools.txt              # Python CLI tools (uv tool install)
├── binary-installs.txt       # Direct binary/script installs
└── .chezmoiscripts/
    └── run_once_*.sh         # Bootstrap script consumes lists (Phase 5)
```

### Pattern 1: Auto-Discovery Then Curate

**What:** Generate package lists from current system, then manually review/trim before committing

**When to use:** Initial list creation to capture current state without missing tools

**Example:**
```bash
# Auto-discover apt packages
apt-mark showmanual > apt-packages.raw.txt

# Curate: remove unnecessary packages
# Keep: build-essential, git, curl, zsh, etc.
# Remove: game packages, GUI apps not needed, transitional packages

# Document with comments
cat > apt-packages.txt <<'EOF'
# === Build Tools ===
build-essential  # GCC, make, libc-dev for compiling
git>=2.40       # Version control (2.40+ for modern features)

# === Shell Utilities ===
zsh             # Primary shell (see STATE.md decision)
bat             # cat replacement with syntax highlighting
eza             # ls replacement with git integration
EOF
```

### Pattern 2: Annotated Package Lists

**What:** Plain text format with inline comments explaining why each package is needed

**When to use:** Every package list — makes curation easier and bootstrap script smarter

**Example:**
```txt
# === apt-packages.txt ===

# === Development Libraries ===
libssl-dev      # OpenSSL headers for building Python/Node modules
libffi-dev      # Foreign function interface for cryptography packages
# post-install: none required

# === CLI Tools ===
gh              # GitHub CLI for PR/issue management
# repo: https://cli.github.com/packages (official GitHub APT repo)
# auth: manual — run 'gh auth login' after install

# === uv-tools.txt ===

basedpyright    # Python type checker (Pyright fork, actively maintained)
# post-install: none (uv handles PATH)

detect-secrets  # Pre-commit hook for secret scanning
# post-install: create baseline with 'detect-secrets scan > .secrets.baseline'

# === binary-installs.txt ===

fnm|https://fnm.vercel.app/install|latest|script
# post-install: eval "$(fnm env --use-on-cd)" in .zshrc

chezmoi|https://get.chezmoi.io|v2.69.3+|script
# post-install: chezmoi init (handled by bootstrap)
```

### Pattern 3: Version Constraints

**What:** Specify minimum versions where features/fixes matter, no version otherwise

**When to use:** When a specific version introduced a breaking change or required feature

**Example:**
```txt
git>=2.40       # 2.40 added --orphan flag improvements
python3>=3.11   # 3.11 required for match statements in scripts
# Most packages: no version constraint (always get latest from repo)
```

### Anti-Patterns to Avoid

- **Don't pin exact versions** in apt-packages.txt unless absolutely necessary (prevents security updates)
- **Don't include transitive dependencies** — let apt/uv resolve them (only list what you explicitly need)
- **Don't use JSON/YAML** for package lists — plain text is easier to parse in bash and easier to diff
- **Don't skip comments** — future you won't remember why some obscure dev library was installed
- **Don't use apt-mark showauto** — that captures transitive dependencies, creating noise

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Listing installed packages | `dpkg -l` + custom parsing | `apt-mark showmanual` | Filters out transitive dependencies automatically, cleaner list |
| Python tool isolation | virtualenv + shell scripts | `uv tool install` | Built-in PATH management, 10-100x faster, unified tool list |
| Dotfile encryption | Custom GPG wrapper | age + chezmoi built-in | Simpler key format, chezmoi has native support, no GPG complexity |
| Secret scanning | Regex-based git hooks | detect-secrets | Baseline workflow prevents alert fatigue, actively maintained by Yelp |
| Package version tracking | Manual changelog review | `apt-cache policy` / `uv tool list` | Shows installed vs available versions automatically |

**Key insight:** System package management is a solved problem. Use standard tools (apt-mark, uv) rather than building custom package tracking. The value is in curation (deciding what to install), not in inventing new list formats.

## Common Pitfalls

### Pitfall 1: Including Transitive Dependencies

**What goes wrong:** Running `dpkg -l` or `apt list --installed` captures hundreds of packages you never explicitly installed, including libraries pulled in as dependencies.

**Why it happens:** These commands show *all* installed packages, not distinguishing between manual installs and automatic dependencies.

**How to avoid:** Use `apt-mark showmanual` which filters to only packages you explicitly installed with `apt install`.

**Warning signs:** Your apt-packages.txt has 300+ entries and includes things like `libxcb-xinerama0` that you definitely didn't install yourself.

### Pitfall 2: Skipping Version Constraints for Critical Tools

**What goes wrong:** Bootstrapping on a system with old repository mirrors installs git 2.25, but your scripts use `git switch` (added in 2.23) or other modern features — subtle breakage occurs.

**Why it happens:** Ubuntu LTS repos can lag behind current releases, and you assumed "git" means "recent git."

**How to avoid:** Add minimum version constraints for tools where you use modern features: `git>=2.40`, `python3>=3.11`.

**Warning signs:** Bootstrap succeeds but later scripts fail with "unknown option" errors.

### Pitfall 3: Not Annotating Post-Install Requirements

**What goes wrong:** Bootstrap script installs fnm, but shell integration never happens because you didn't document that `eval "$(fnm env)"` is required in .zshrc.

**Why it happens:** Many tools (fnm, starship, uv) require post-install shell setup, but package lists only track installation, not configuration.

**How to avoid:** Use comment annotations: `# post-install: eval "$(fnm env --use-on-cd)"` so Phase 5 bootstrap script knows what to automate.

**Warning signs:** Tools install but aren't in PATH or don't work until manual intervention.

### Pitfall 4: Mixing Package Manager Domains

**What goes wrong:** Installing Python tools via apt (apt install python3-pytest) creates conflicts with uv/pip-managed versions, leading to "externally-managed environment" errors.

**Why it happens:** Python 3.11+ enforces PEP 668 (externally-managed environments) to prevent apt and pip from stomping on each other.

**How to avoid:** Keep clear domain separation:
- System libraries → apt (libpython3-dev)
- Python CLI tools → uv tool install (basedpyright, detect-secrets)
- Never use apt for Python apps

**Warning signs:** Errors like "externally-managed-environment" or conflicts between system and user-installed Python packages.

### Pitfall 5: Not Curating Auto-Generated Lists

**What goes wrong:** Auto-generating from `apt-mark showmanual` captures every experiment and one-off package you installed months ago, enshrining junk in the "canonical" package list.

**Why it happens:** `apt-mark showmanual` is truthful — it shows everything you manually installed, including mistakes.

**How to avoid:** Treat auto-generated lists as a starting point, then curate:
1. Generate: `apt-mark showmanual > raw.txt`
2. Review: identify essential vs cruft
3. Curate: create clean list with only needed packages
4. Document: add comments explaining each package's purpose

**Warning signs:** Your package list includes packages you don't recognize or can't explain.

## Code Examples

Verified patterns from official sources:

### Discovering APT Packages

```bash
# Source: apt-mark(8) manpage
# List manually installed packages (excludes transitive dependencies)
apt-mark showmanual > apt-packages.raw.txt

# Check if a package is manual or auto
apt-mark showmanual git  # Exits 0 if manual, 1 if auto

# Verify package version before adding to list
apt-cache policy git
# Output shows installed version and available version
```

### Using uv for Python Tools

```bash
# Source: https://docs.astral.sh/uv/concepts/tools/
# Install a tool (replaces pipx install)
uv tool install basedpyright

# List installed tools
uv tool list
# Output:
# basedpyright v1.36.1
# - basedpyright
# - basedpyright-langserver

# Install specific version
uv tool install ruff@0.6.0

# Show tool installation directory
uv tool dir
```

### Generating Annotated Package Lists

```bash
# Source: Dotfiles community patterns (https://dotfiles.github.io/)
# Create annotated apt package list with sections

cat > apt-packages.txt <<'EOF'
# === Build Tools ===
build-essential  # GCC, make, libc-dev
pkg-config       # Helper tool for compiling applications

# === Version Control ===
git>=2.40        # Modern git features (switch, restore)

# === Shell Utilities ===
zsh              # Primary shell
bat              # cat with syntax highlighting
eza              # ls replacement with git awareness
fzf              # Fuzzy finder for shell history

# === Development Libraries ===
libssl-dev       # OpenSSL headers
libffi-dev       # FFI for Python cryptography
# post-install: none required

# === External Repos ===
gh               # GitHub CLI
# repo: https://cli.github.com/packages
# auth: manual — run 'gh auth login'
EOF
```

### Creating uv Tools List

```bash
# Source: https://docs.astral.sh/uv/concepts/tools/
# Auto-discover current uv tools
uv tool list | grep -E '^[a-z]' | awk '{print $1}' > uv-tools.raw.txt

# Create curated list
cat > uv-tools.txt <<'EOF'
# Python development tools managed by uv
# Install with: uv tool install <name>

basedpyright     # Python type checker (actively maintained Pyright fork)
pre-commit       # Git hook framework
virtualenv       # Virtual environment creation
just             # Command runner (Makefile alternative)
detect-secrets   # Secret scanning for pre-commit
# post-install: detect-secrets scan > .secrets.baseline
EOF
```

### Binary Install Tracking

```bash
# Format: name|source_url|version|method
# Method: script (curl|bash) or binary (direct download)

cat > binary-installs.txt <<'EOF'
# Tools installed via official installers or direct binaries
# Bootstrap script parses: name|source|version|method

chezmoi|https://get.chezmoi.io|v2.69.3+|script
# post-install: chezmoi init

fnm|https://fnm.vercel.app/install|latest|script
# post-install: eval "$(fnm env --use-on-cd)" in .zshrc

bun|https://bun.sh/install|v1.3.9+|script
# post-install: shell integration automatic

starship|https://starship.rs/install.sh|latest|script
# post-install: eval "$(starship init zsh)" in .zshrc

antidote|https://github.com/mattmc3/antidote|latest|git
# install: git clone --depth=1 to ~/.antidote
# post-install: source in .zshrc

age|github:FiloSottile/age|latest|binary
# install: download binary from releases, install to /usr/local/bin
EOF
```

### Checking Package Dependencies

```bash
# Source: apt-cache(8) manpage
# Before adding a package, check what it pulls in
apt-cache depends git
# Shows: Depends, Recommends, Suggests

# Simulate install to see what would be added
apt-get install -s git
# Shows all packages that would be installed

# Check if package is actually needed
apt-cache rdepends git
# Shows what depends on git (reverse dependencies)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| pipx for Python tools | uv tool install | 2024-2025 | 10-100x faster, unified with uv package management |
| Oh My Zsh | antidote | 2023-2024 | Lighter, faster, selective plugin loading vs monolithic framework |
| nvm for Node | fnm | 2021-2023 | 40x faster, Rust-based, better shell integration |
| GPG for dotfiles encryption | age | 2019-2023 | Simpler key format, modern crypto, chezmoi built-in support |
| Powerlevel10k prompt | Starship | 2024-2025 | p10k unmaintained, Starship actively developed and cross-shell |
| Homebrew on Linux | apt + direct binaries | Ongoing | Cleaner on Ubuntu/Debian, Homebrew adds unnecessary layer |

**Deprecated/outdated:**
- **pipx** → Replaced by `uv tool` in 2025-2026 Python ecosystem
- **nvm** → Still works but fnm is 40x faster and Rust eliminates bash overhead
- **Oh My Zsh** → Heavy and slow; antidote does same job with selective loading
- **GPG for secrets** → Still works but age is simpler and has better tooling integration
- **Snap for chezmoi** → Lags behind releases; official installer gets v2.69.3 immediately

## Open Questions

### 1. Handling PPA-sourced packages in apt-packages.txt

**What we know:** Some tools (gh) come from external APT repos, not main Ubuntu repos

**What's unclear:** Should bootstrap script auto-add PPAs, or should that be a separate step?

**Recommendation:** Annotate PPA packages with repo source in comments:
```txt
gh  # GitHub CLI
# repo: https://cli.github.com/packages
# bootstrap: add repo before apt install
```
Bootstrap script (Phase 5) detects these annotations and adds repos first.

### 2. Node.js LTS version specificity

**What we know:** User wants to document specific Node.js LTS version, not just "install fnm/bun"

**What's unclear:** Should binary-installs.txt specify Node version, or should that live in fnm config?

**Recommendation:** Document in binary-installs.txt as metadata:
```txt
fnm|https://fnm.vercel.app/install|latest|script
# post-install: fnm install 22.13.0 && fnm default 22.13.0 (Node LTS as of 2026-02-10)
```
This way bootstrap script can automate: install fnm → install specific Node → set default.

### 3. Bun vs Node priority

**What we know:** Both fnm (Node manager) and bun (all-in-one runtime) are being installed

**What's unclear:** Is bun the primary runtime (Node for compatibility only), or are they equal?

**Recommendation:** Document in binary-installs.txt comments:
```txt
bun|https://bun.sh/install|v1.3.9+|script
# Primary JS runtime for new projects

fnm|https://fnm.vercel.app/install|latest|script
# Node.js for compatibility (legacy projects, tools that require Node)
```

## Sources

### Primary (HIGH confidence)

- [uv official documentation](https://docs.astral.sh/uv/) - Tool installation, uv tool command usage
- Context7: /llmstxt/astral_sh_uv_llms_txt - uv tool management patterns
- [apt-mark Ubuntu manpage](https://manpages.ubuntu.com/manpages/bionic/man8/apt-mark.8.html) - Package state management
- [chezmoi age documentation](https://www.chezmoi.io/user-guide/encryption/age/) - Age encryption integration
- [detect-secrets GitHub repository](https://github.com/Yelp/detect-secrets) - Baseline workflow
- [fnm GitHub repository](https://github.com/Schniz/fnm) - Installation methods
- [starship installation documentation](https://starship.rs/installing/) - Official install script
- [GitHub CLI installation guide](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) - Official installation methods
- [antidote installation documentation](https://antidote.sh/install) - Git clone installation pattern

### Secondary (MEDIUM confidence)

- [dotfiles.github.io bootstrap patterns](https://dotfiles.github.io/bootstrap/) - Community best practices for package lists
- [Medium: Best Practices using Pre-commit and Detect-secrets](https://medium.com/@mabhijit1998/pre-commit-and-detect-secrets-best-practises-6223877f39e4) - Baseline workflow
- [Medium: The 2026 Golden Path Python Packages with uv](https://medium.com/@diwasb54/the-2026-golden-path-building-and-publishing-python-packages-with-a-single-tool-uv-b19675e02670) - uv as industry standard
- [Bun official site](https://bun.com/) - Installation methods and current version

### Tertiary (LOW confidence)

- Various blog posts and community discussions about minimal apt package lists
- WebSearch results about package management best practices (corroborated with official docs)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - uv, apt-mark, chezmoi, age all verified from official documentation
- Architecture: HIGH - Plain text list format is proven pattern in dotfiles community, examples from multiple sources
- Pitfalls: MEDIUM-HIGH - Transitive dependency and post-install issues verified from experience and documentation, PEP 668 is documented Python standard

**Research date:** 2026-02-10
**Valid until:** 2026-04-10 (60 days - relatively stable domain, tools evolve slowly)

**Notes:**
- User decisions from CONTEXT.md constrained research to chosen tools (uv, antidote, starship, fnm, chezmoi)
- Current system inspection (101 apt packages, uv tools present) validates feasibility
- All installation methods verified from official sources (no speculation about how tools install)
