---
phase: 05-bootstrap-implementation
plan: 01
subsystem: bootstrap
tags: [bash, shell-scripting, automation, idempotency, wsl2, package-management]

requires:
  - 02-01 # Package manifests (apt-packages.txt)
  - 02-02 # Tool manifests (uv-tools.txt, binary-installs.txt)

provides:
  - bootstrap.sh with scaffolding, system config, and all installation functions
  - Idempotent installation logic for all tools and packages
  - Colored output and error tracking infrastructure

affects:
  - 05-02 # Will add finalization (chezmoi, shell change, SSH, backup, summary)

tech-stack:
  added: []
  patterns:
    - Idempotent bash scripting with existence checks
    - Continue-on-failure error collection pattern
    - Colored terminal output with tput
    - Declarative package installation from manifest files

key-files:
  created:
    - bootstrap.sh
  modified: []

decisions:
  - title: "Use tput for colored output instead of raw ANSI codes"
    rationale: "tput is more portable across terminals and easier to maintain"
    phase: "05-01"

  - title: "Continue-on-failure pattern with error collection"
    rationale: "Bootstrap scripts should attempt all steps even if some fail, showing all errors at end rather than failing fast"
    phase: "05-01"

  - title: "Strip version constraints from apt-packages.txt during parsing"
    rationale: "apt handles version selection naturally, constraints like >=2.40 are documentation-only"
    phase: "05-01"

  - title: "Try apt install for age before GitHub releases fallback"
    rationale: "Simpler if available via apt, fallback ensures it works everywhere"
    phase: "05-01"

  - title: "Install fzf from git with --no-update-rc flags"
    rationale: "Shell integration already configured in zsh config, avoid duplicate configuration"
    phase: "05-01"

  - title: "Prefer bun over npm for Claude Code installation"
    rationale: "bun is faster and already being installed, npm is fallback for compatibility"
    phase: "05-01"

metrics:
  duration: 2.1
  completed: 2026-02-10
---

# Phase 05 Plan 01: Bootstrap Scaffolding & Installation Functions Summary

**One-liner:** Created idempotent bootstrap.sh with all installation functions — system config, apt packages, binary tools (Starship, fnm, fzf, uv, bun, age), plugin managers (antidote), Python tools (uv tool install), and Node tools (fnm + Claude Code).

## What Was Built

Created the core of the bootstrap script with 557 lines covering:

1. **Scaffolding infrastructure** (lines 1-74)
   - Shebang with `set -euo pipefail` for prerequisites section
   - Global configuration (`DOTFILES_DIR`)
   - Color setup using tput (RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, BOLD, RESET)
   - Logging functions (log_info, log_success, log_skip, log_error, section_header)
   - Error tracking arrays (FAILED_STEPS, INSTALLED, SKIPPED)
   - `run_step` wrapper function for continue-on-failure pattern

2. **Prerequisites check** (lines 77-100)
   - Verifies curl, git, sudo are available
   - Exits immediately if any missing (critical for bootstrap)

3. **System configuration** (lines 102-132)
   - `configure_wsl`: Sets up `/etc/wsl.conf` with `systemd=true` and interop settings
   - Idempotent: skips if already configured

4. **APT repository setup** (lines 134-175)
   - `setup_apt_repos`: Adds GitHub CLI and PowerShell repositories
   - Idempotent: checks for existing repo files before adding
   - Runs `apt-get update` only if repos were added

5. **APT package installation** (lines 177-229)
   - `install_apt_packages`: Reads from `packages/apt-packages.txt`
   - Strips comments, empty lines, version constraints (e.g., `git>=2.40` → `git`)
   - Idempotent: uses `dpkg-query` to check before installing
   - Tracks installed/skipped counts

6. **Binary tools installation** (lines 231-373)
   - `install_binary_tools`: Coordinates all binary installations
   - `install_starship`: Installs to `~/.local/bin` with `-y` flag
   - `install_fnm`: Uses `--skip-shell` (integration already in zsh config)
   - `install_fzf`: Clones from git, installs with `--no-update-rc` flags
   - `install_uv`: Installs Python package manager
   - `install_bun`: Installs JavaScript runtime
   - `install_age`: Tries apt first, falls back to GitHub releases (v1.2.1)
   - All use `command -v` for idempotency checks

7. **Plugin managers** (lines 375-403)
   - `install_plugin_managers`: Coordinates plugin manager setup
   - `install_antidote`: Clones to `~/.antidote` with `--depth=1`
   - TPM note: Documents that TPM is managed by chezmoi `.chezmoiexternal.toml`

8. **Python tools** (lines 405-451)
   - `install_python_tools`: Reads from `packages/uv-tools.txt`
   - Uses `uv tool list` for idempotency checks
   - Installs: basedpyright, detect-secrets, just, pre-commit, virtualenv

9. **Node.js and JavaScript tools** (lines 453-557)
   - `install_node_tools`: Sources fnm into current shell
   - Installs Node.js 22 (LTS) via `fnm install 22 && fnm default 22`
   - `install_claude_code`: Prefers bun, falls back to npm
   - Idempotency: checks `fnm list` for Node, `command -v` for Claude

## Decisions Made

### 1. Continue-on-failure pattern instead of set -e everywhere
**Context:** Bootstrap scripts traditionally use `set -e` to exit on first error, but this leaves systems half-configured.

**Decision:** Use `set -euo pipefail` only for critical prerequisites check, then disable it for main installation sections. Collect failures in `FAILED_STEPS` array and report all at end.

**Impact:** Users see all failures at once, can fix multiple issues before re-running. Script completes as much as possible even if some steps fail.

### 2. Strip version constraints from apt-packages.txt during parsing
**Context:** `apt-packages.txt` contains documentation like `git>=2.40` to indicate minimum version requirements.

**Decision:** Parse and strip version constraints (everything after `>=`) before passing to apt-get. apt handles version selection naturally based on repository configuration.

**Impact:** Simpler parsing logic, apt-get receives clean package names. Version constraints remain as documentation for humans.

### 3. Install age via apt first, GitHub releases as fallback
**Context:** age can be installed via apt on newer Ubuntu, but may not be available on all versions.

**Decision:** Try `apt-get install age` first, fall back to downloading v1.2.1 binary from GitHub releases if apt fails.

**Impact:** Simpler installation when apt package exists, guaranteed availability via fallback.

### 4. Use tput for colors instead of raw ANSI escape codes
**Context:** Colored output can use tput commands or hardcoded ANSI codes like `\033[31m`.

**Decision:** Use tput (e.g., `tput setaf 1` for red) for all color/formatting.

**Rationale:** tput is more portable across different terminals, handles terminal capabilities automatically, and is easier to maintain with named variables.

**Impact:** Consistent color support across different terminal types, clearer code.

### 5. Prefer bun over npm for Claude Code installation
**Context:** Claude Code can be installed via npm or bun, both are global package managers.

**Decision:** Check for bun first, use it if available, fall back to npm.

**Rationale:** bun is significantly faster and already being installed by the bootstrap script. npm is available via fnm if bun isn't present.

**Impact:** Faster Claude Code installation when bun is available, maintains compatibility via npm fallback.

## Deviations from Plan

None — plan executed exactly as written.

## Technical Insights

### Idempotency Pattern Implementation
Every installation function follows the same pattern:
1. Check if already installed (`command -v`, `dpkg-query`, directory check)
2. Skip with log message if exists → add to SKIPPED array
3. Install if missing
4. Log success → add to INSTALLED array
5. Log error on failure → add to FAILED_STEPS array

This pattern makes the script safe to re-run and provides clear visibility into what happened.

### Package Manifest Parsing
The apt package parsing handles multiple edge cases:
- Comments (lines starting with `#`)
- Inline comments (everything after `#` on a line)
- Version constraints (e.g., `git>=2.40` becomes `git`)
- Empty lines
- Leading/trailing whitespace

This allows the manifest files to be human-readable with documentation while the script extracts clean package names.

### Error Tracking Architecture
Three global arrays track execution state:
- `INSTALLED`: Successfully installed items (for summary)
- `SKIPPED`: Already-installed items (proves idempotency)
- `FAILED_STEPS`: Failed operations (for error reporting)

The `run_step` wrapper function automatically populates `FAILED_STEPS` for top-level sections, while individual install functions populate all three arrays for granular tracking.

### PATH Management
The script adds `~/.local/bin` to PATH early (`export PATH="$HOME/.local/bin:$PATH"`) to ensure:
- Newly installed binaries are immediately available
- Subsequent checks (`command -v`) find just-installed tools
- Tools can be used in later installation steps

## Next Phase Readiness

**Ready for Plan 02:** Yes

Plan 02 will add:
- `main()` function that calls all installation functions
- `backup_dotfiles()` function
- `setup_ssh_keys()` function with permission correction
- `change_shell()` function (chsh to zsh)
- `setup_chezmoi()` function (install + init --apply)
- `print_summary()` function with post-install checklist
- Error summary and execution at script end
- `exec zsh` to auto-start new shell

All installation functions are ready to be called by `main()`.

## Blockers/Concerns

None.

## Files Changed

**Created:**
- `bootstrap.sh` (557 lines)
  - Scaffolding and helper functions
  - System configuration (WSL2)
  - APT repository setup and package installation
  - Binary tools installation (Starship, fnm, fzf, uv, bun, age)
  - Plugin managers (antidote)
  - Python tools (uv tool install)
  - Node.js and JavaScript tools (fnm, Claude Code)

## Commands for Next Session

Plan 02 is ready to execute:
```bash
# Plan 02 will add finalization functions and main execution logic
claude /gsd:execute-plan 05-02
```

## Validation Results

All verification criteria passed:
- ✓ `bootstrap.sh` exists at repo root
- ✓ File is executable (`chmod +x`)
- ✓ `bash -n bootstrap.sh` passes syntax check
- ✓ All helper functions defined (log_info, log_success, log_skip, log_error, section_header)
- ✓ Error tracking exists (FAILED_STEPS, INSTALLED, SKIPPED)
- ✓ Reads from `packages/apt-packages.txt`
- ✓ Reads from `packages/uv-tools.txt`
- ✓ Every installation function has idempotency check
- ✓ Colored output via tput
- ✓ All 7 main installation functions defined
- ✓ Script contains 557 lines (exceeds 250 minimum)

## Commits

| Task | Commit | Files | Description |
|------|--------|-------|-------------|
| 1 | dd9d5b7 | bootstrap.sh | Create bootstrap scaffolding with system config and apt packages |
| 2 | 6c08814 | bootstrap.sh | Add binary tools, plugin managers, and Python/Node installation |
