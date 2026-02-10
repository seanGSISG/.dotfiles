---
phase: 02-package-management-tool-inventory
plan: 02
subsystem: tooling
tags: [uv, chezmoi, fnm, bun, starship, antidote, age, bootstrap, python, javascript]

# Dependency graph
requires:
  - phase: 01-repository-foundation-safety
    provides: chezmoi repository structure and initial commit
provides:
  - uv-tools.txt: Python CLI tool inventory for uv tool install
  - binary-installs.txt: Binary/script install inventory with sources and methods
  - Complete bill of materials for bootstrap script
affects: [03-shell-configuration, 05-bootstrap-script]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Structured tool manifests (uv-tools.txt, binary-installs.txt) for bootstrap consumption"
    - "Post-install annotations in tool lists for automated setup"

key-files:
  created:
    - ~/.local/share/chezmoi/uv-tools.txt
    - ~/.local/share/chezmoi/binary-installs.txt
  modified:
    - ~/.local/share/chezmoi/.chezmoiignore

key-decisions:
  - "Curate uv tools list - exclude experimental AI tools (amplifier, kimi, openhands)"
  - "Document Node.js LTS 22.x via fnm (not direct install)"
  - "Use structured format for binary-installs.txt: name|source|version|method"
  - "Annotate auth-required tools with # auth: manual"

patterns-established:
  - "Tool lists are repo-only files (excluded from chezmoi apply)"
  - "Post-install requirements inline as comments"
  - "Version specifications: 'latest' vs 'vX.Y.Z+' minimum"

# Metrics
duration: 1 min
completed: 2026-02-10
---

# Phase 2 Plan 2: uv Tools and Binary Installs Summary

**Curated Python CLI tools (uv-tools.txt) and binary install inventory (binary-installs.txt) documented with sources, versions, and post-install requirements**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-10T19:23:41Z
- **Completed:** 2026-02-10T19:25:12Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Created uv-tools.txt with 5 curated Python CLI tools (basedpyright, detect-secrets, just, pre-commit, virtualenv)
- Created binary-installs.txt with 8 tools (uv, chezmoi, fnm, bun, starship, antidote, age, claude-code)
- Each tool documented with source URL, version requirements, install method, and post-install annotations
- Node.js LTS 22.x documented via fnm installation
- Auth-required tools annotated (claude-code)
- Updated .chezmoiignore to exclude both tool lists from chezmoi apply

## Task Commits

Each task was committed atomically:

1. **Task 1: Create uv-tools.txt from system discovery** - `d1ef9de` (feat)
2. **Task 2: Create binary-installs.txt and commit both files** - `943dc81` (feat)

## Files Created/Modified

- `~/.local/share/chezmoi/uv-tools.txt` - Python CLI tool inventory for uv tool install (5 tools)
- `~/.local/share/chezmoi/binary-installs.txt` - Binary/script install inventory with structured format (8 tools)
- `~/.local/share/chezmoi/.chezmoiignore` - Updated to exclude uv-tools.txt and binary-installs.txt

## Decisions Made

1. **Curate uv tools list** - Excluded experimental AI tools (amplifier, kimi-cli, openhands, cli-agent-orchestrator) that were discovered on the system but not in requirements. Kept only essential dev tools: basedpyright, detect-secrets, just, pre-commit, virtualenv.

2. **Document Node via fnm** - Node.js LTS 22.x documented as fnm-managed, not a direct binary install. This maintains the fnm-as-version-manager pattern.

3. **Structured format for binary-installs.txt** - Used pipe-delimited format (name|source|version|method) for easy parsing by bootstrap script. Clearer than freeform comments.

4. **Post-install annotations inline** - Added post-install requirements as comments directly below each tool entry. Bootstrap script (Phase 5) will parse and execute these steps.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

PKG-02 requirement satisfied: uv-tools.txt and binary-installs.txt exist with complete tool documentation.

PKG-03 requirement partially satisfied: Lists exist and are committed. Full bootstrap consumption implementation happens in Phase 5.

With apt-packages.txt (from 02-01), uv-tools.txt, and binary-installs.txt, the complete bill of materials is now documented. Ready for shell configuration (Phase 3) and eventual bootstrap script (Phase 5).

---
*Phase: 02-package-management-tool-inventory*
*Completed: 2026-02-10*
