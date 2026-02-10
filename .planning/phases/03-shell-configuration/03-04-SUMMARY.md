---
phase: 03-shell-configuration
plan: 04
subsystem: shell
tags: [zshrc, bashrc, profile, chezmoi-templates, starship, shell-entry-points]

# Dependency graph
requires:
  - phase: 03-01
    provides: exports.zsh, plugins.zsh, .zsh_plugins.txt
  - phase: 03-02
    provides: tools.zsh, wsl.zsh.tmpl
  - phase: 03-03
    provides: aliases/ (6 files), functions.zsh
provides:
  - Shell entry points (.zshrc, .bashrc, .profile)
  - Modular zsh configuration fully wired
  - Bash fallback with shared aliases
affects: [04-tool-configs, 05-bootstrap-implementation]

# Tech tracking
tech-stack:
  added: []
  patterns: [pure-sourcer-zshrc, bash-fallback-with-banner, chezmoi-conditional-templates]

key-files:
  created:
    - dot_zshrc.tmpl
    - dot_bashrc.tmpl
    - dot_profile
  modified: []

key-decisions:
  - "Fixed missing sourceDir in .chezmoi.toml.tmpl during verification"

patterns-established:
  - "Pure sourcer pattern: .zshrc contains only source commands"
  - "Shared alias pattern: bash sources same alias files from ~/.config/zsh/aliases/"

# Metrics
duration: 2min
completed: 2026-02-10
---

# Phase 3 Plan 04: Shell Entry Points Summary

**Pure sourcer .zshrc wiring all modular files, bash fallback with zsh hint banner, and minimal .profile**

## Performance

- **Duration:** 2 min
- **Tasks:** 3 auto + 1 checkpoint (human-verify)
- **Files created:** 3

## Accomplishments
- .zshrc is a pure sourcer loading exports, plugins, tools, functions, aliases, WSL2 config, and Starship in explicit order
- .bashrc provides functional fallback with colored banner, PATH, secrets, fnm, fzf, zoxide, shared aliases, and Starship
- .profile is minimal (7 lines) — only sources .bashrc for bash login shells
- Fixed missing sourceDir in chezmoi config template during human verification
- All configs deployed via chezmoi apply and verified working

## Task Commits

1. **Task 1: Create dot_zshrc.tmpl** - `fedde9a` (feat)
2. **Task 2: Create dot_bashrc.tmpl** - `69832c3` (feat)
3. **Task 3: Create dot_profile** - `d58e813` (feat)
4. **Task 4: Human verification** - approved, chezmoi apply confirmed working

**Orchestrator fix:** `235d8cf` (fix: add sourceDir to chezmoi config template)

## Files Created/Modified
- `dot_zshrc.tmpl` - Pure sourcer, 39 lines, chezmoi template for WSL2 conditional
- `dot_bashrc.tmpl` - Bash fallback, 84 lines, chezmoi template for WSL2 conditional
- `dot_profile` - Minimal profile, 7 lines, sources .bashrc if bash

## Decisions Made
- Fixed sourceDir missing from .chezmoi.toml.tmpl — chezmoi init was resetting source to default path

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added sourceDir to chezmoi config template**
- **Found during:** Human verification checkpoint
- **Issue:** `chezmoi init` reset source directory to default ~/.local/share/chezmoi because .chezmoi.toml.tmpl lacked sourceDir setting
- **Fix:** Added `sourceDir = "~/.dotfiles"` to config template
- **Files modified:** .chezmoi.toml.tmpl
- **Verification:** `chezmoi source-path` returns /home/vscode/.dotfiles
- **Committed in:** 235d8cf

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Essential fix for chezmoi to work after re-initialization. No scope creep.

## Issues Encountered
None beyond the sourceDir fix.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All shell configuration files deployed and verified
- Phase 3 complete, ready for Phase 4 (Tool Configs)

---
*Phase: 03-shell-configuration*
*Completed: 2026-02-10*
