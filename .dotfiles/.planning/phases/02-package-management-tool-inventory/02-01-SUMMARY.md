---
phase: 02-package-management-tool-inventory
plan: 01
subsystem: infra
tags: [apt, packages, system-dependencies, bootstrap, wsl2]

# Dependency graph
requires:
  - phase: 01-repository-foundation-safety
    provides: "Chezmoi repo initialized and ready for package manifests"
provides:
  - "Curated apt-packages.txt with 34 essential system packages for WSL2 dev environment"
  - "Package manifest ready for bootstrap.sh consumption"
affects: [05-bootstrap-script, package-management, system-setup]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Package manifest as plain text for bootstrap automation"]

key-files:
  created: ["~/.local/share/chezmoi/apt-packages.txt"]
  modified: ["~/.local/share/chezmoi/.chezmoiignore"]

key-decisions:
  - "Curated from 101 to 34 packages by removing GUI/desktop and base system packages"
  - "Grouped packages by purpose (build tools, shell, file utils, Python, security, WSL integration)"
  - "Annotated every package with inline comments explaining purpose"
  - "Marked gh as requiring external repo and manual authentication"
  - "Set git version constraint to >=2.40 for modern features"

patterns-established:
  - "Package manifests stored in chezmoi repo but excluded from apply (repo-only files)"
  - "One package per line with # comments for readability and maintainability"
  - "Version constraints specified where modern features are required"
  - "External repo packages annotated with repo source and auth requirements"

# Metrics
duration: 1 min
completed: 2026-02-10
---

# Phase 2 Plan 1: Apt Package Inventory Summary

**34 essential system packages curated from 101 raw apt-mark output, organized by purpose with inline annotations for bootstrap consumption**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-10T19:22:33Z
- **Completed:** 2026-02-10T19:23:35Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Auto-discovered 101 manually-installed apt packages from current system
- Curated down to 34 essential packages by removing GUI/desktop, transitional, and base packages
- Organized into 11 purpose-based sections (Build Tools, Version Control, Shell, File Utils, Python, Security, WSL Integration, etc.)
- Every package annotated with inline comment explaining its purpose
- git marked with version constraint (>=2.40) for modern features
- gh marked with repo source annotation and auth requirement
- Added apt-packages.txt to .chezmoiignore (repo-only file, not deployed by chezmoi apply)

## Task Commits

Each task was committed atomically:

1. **Task 1: Auto-discover and curate apt package list** - `0492fc1` (feat)
2. **Task 2: Add apt-packages.txt to chezmoi and commit** - `d7204fc` (chore)

_All commits include pre-commit hook execution (detect-secrets passed)_

## Files Created/Modified
- `~/.local/share/chezmoi/apt-packages.txt` - Curated system package list (68 lines, 11 sections, 34 packages)
- `~/.local/share/chezmoi/.chezmoiignore` - Added apt-packages.txt to prevent deployment

## Decisions Made

**Curation strategy:**
- Removed GUI/desktop packages (google-chrome-stable, libgtk, libx11, libwayland, libcairo, etc.) — not needed for WSL2 dev
- Removed transitional/meta packages (ubuntu-minimal, ubuntu-wsl) — pull in base packages automatically
- Removed base system packages (bash, coreutils, grep, gzip, etc.) — part of Ubuntu base install
- Removed experimental tools (crystal, ne, acli) — not in project requirements
- Removed pipx — being replaced by uv tool in Phase 2
- Kept libsecret and gnome-keyring — needed for credential storage with git/gh on WSL2
- Kept libfuse2t64 and fuse — needed for AppImage support
- Kept powershell and wslu — useful for Windows/WSL2 interop
- Kept Python 3 (python3, python3-pip, python3.12, python3.12-venv) — needed for uv and Python dev

**Package count rationale:**
- 34 packages is the minimal essential set for the target dev environment
- Does NOT include tools installed via binary-installs.txt (chezmoi, fnm, bun, starship, age, antidote, uv)
- Does NOT include tools installed via uv-tools.txt (basedpyright, pre-commit, detect-secrets, virtualenv, just)

**Annotation strategy:**
- Every package has inline comment explaining purpose (no bare package names)
- External repo packages (gh) annotated with repo source
- Auth-required packages (gh) annotated with manual auth step
- Version-constrained packages (git>=2.40) annotated with reason

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- apt-packages.txt is ready for bootstrap.sh consumption
- Next: Create binary-installs.txt for direct binary downloads (02-02)
- Next: Create uv-tools.txt for Python tools installed via uv (02-03)
- Phase 2 continues with remaining package manifests

---
*Phase: 02-package-management-tool-inventory*
*Completed: 2026-02-10*
