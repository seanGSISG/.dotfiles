---
phase: 04-tool-configs
plan: 02
subsystem: terminal-config
tags: [tmux, starship, tpm, prompt, xdg, chezmoi]

# Dependency graph
requires:
  - phase: 03-shell-configuration
    provides: Shell configs with Starship init and conditional tool loading
provides:
  - XDG-compliant tmux configuration with TPM auto-install
  - Starship prompt config matching P10k Pure aesthetic
  - Chezmoi external resources pattern for plugin managers
affects: [05-bootstrap, future-shell-customization]

# Tech tracking
tech-stack:
  added: [TPM (Tmux Plugin Manager), tmux-yank, Dracula theme for tmux]
  patterns: [XDG-compliant config paths, chezmoi external resources for git repos, two-line prompt layout]

key-files:
  created:
    - dot_config/tmux/tmux.conf
    - dot_config/starship.toml
    - .chezmoiexternal.toml
  modified: []

key-decisions:
  - "Use XDG-compliant paths for tmux (~/.config/tmux/ instead of ~/.tmux/)"
  - "Auto-clone TPM via .chezmoiexternal.toml (not manual git clone)"
  - "Show only virtualenv name in Python module, not version (reduce noise)"
  - "5-second threshold for cmd_duration (matches P10k default)"
  - "Disable package and time modules in Starship (reduce noise)"

patterns-established:
  - "Pattern: Chezmoi external resources for plugin manager repos"
  - "Pattern: Organized tmux config with clear sections (General, Window/Pane, Key Bindings, Copy/Paste, Plugins, Theme, TPM Init)"
  - "Pattern: Two-line prompt layout for breathing room (info line + character line)"

# Metrics
duration: 2min
completed: 2026-02-10
---

# Phase 4 Plan 02: Tool Configs - Tmux & Starship Summary

**XDG-compliant tmux config with TPM auto-install and Starship prompt matching P10k Pure aesthetic (clean two-line layout, git/virtualenv/node/duration modules)**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-11T00:15:52Z
- **Completed:** 2026-02-11T00:17:48Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Tmux config migrated to XDG-compliant path with cleaned-up organization
- TPM auto-cloned via chezmoi external resources (no manual git clone steps)
- Starship prompt configured with all required modules (git_branch, git_status, python, nodejs, cmd_duration)
- Two-line prompt layout matching P10k Pure aesthetic
- No hardcoded paths anywhere (CONF-03 satisfied)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create tmux config and TPM external resource** - `1158e47` (feat)
2. **Task 2: Create Starship prompt configuration** - `0f9c402` (feat)

## Files Created/Modified
- `dot_config/tmux/tmux.conf` - XDG-compliant tmux config with TPM, Dracula theme, mouse support, organized sections
- `dot_config/starship.toml` - P10k Pure-style prompt config with git, python, nodejs, cmd_duration modules
- `.chezmoiexternal.toml` - Auto-clone TPM via chezmoi external resources

## Decisions Made

**1. Use XDG-compliant paths for tmux**
- Modern tmux 3.1+ supports `~/.config/tmux/tmux.conf` automatically
- Cleaner home directory, better for containerization
- TPM updated to `~/.config/tmux/plugins/tpm/tpm`

**2. Auto-clone TPM via .chezmoiexternal.toml**
- Chezmoi handles initial clone and updates (refreshPeriod = 168h)
- Consistent across machines, no manual git clone steps
- Pattern established for future plugin manager needs

**3. Show only virtualenv name in Python module, not version**
- Python version is too noisy (changes frequently, not always relevant)
- Virtualenv name is what matters for context (which project/env)
- Reduces prompt clutter while maintaining essential info

**4. 5-second threshold for cmd_duration**
- Matches Powerlevel10k default threshold
- Shows slow commands without overwhelming with sub-second noise
- Helps identify performance issues

**5. Disable package and time modules in Starship**
- Package version appears in every project (too noisy)
- Time is visible in terminal title bar (redundant)
- Clean, minimal prompt focuses on essential context

**6. Two-line prompt layout**
- Info line (directory, git, tools) + separate character line
- Matches P10k Pure aesthetic
- Breathing room, easier to read long paths

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - straightforward configuration file creation and chezmoi apply.

## Next Phase Readiness

**Ready for Phase 5 (Bootstrap):**
- Tmux config deployed and ready for use
- Starship config deployed (Starship binary installation handled in Phase 5)
- TPM auto-clones on chezmoi apply
- All configs use XDG-compliant paths
- No hardcoded paths to prevent multi-machine issues

**Testing checklist for Phase 5:**
- Verify TPM auto-clones on fresh machine after chezmoi apply
- Verify tmux loads config from ~/.config/tmux/tmux.conf
- Verify Starship reads ~/.config/starship.toml after installation
- Test tmux plugin installation with `prefix + I` after TPM clone

**No blockers or concerns.**

---
*Phase: 04-tool-configs*
*Completed: 2026-02-10*
