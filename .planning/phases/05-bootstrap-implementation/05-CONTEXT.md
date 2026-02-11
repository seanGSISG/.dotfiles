# Phase 5: Bootstrap Implementation - Context

**Gathered:** 2026-02-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Build an idempotent bootstrap.sh that takes a fresh WSL2 Ubuntu machine from zero to fully configured dev environment. Installs all apt packages, binary tools (Starship, fnm, fzf, zoxide, uv, bun, antidote, TPM), sets zsh as default shell, configures WSL2 (/etc/wsl.conf), handles SSH key copying, backs up existing dotfiles, and deploys all chezmoi configs. Single script, invoked via curl|bash.

</domain>

<decisions>
## Implementation Decisions

### Invocation & entry point
- curl|bash invocation: `curl -fsSL https://raw.githubusercontent.com/.../bootstrap.sh | bash`
- Single monolithic file — all logic self-contained, no sourcing helper scripts
- Prerequisites assumed: curl, git, sudo already available on fresh WSL2 Ubuntu
- Script lives at repo root: `~/.dotfiles/bootstrap.sh`

### Output & progress
- Section headers only — print a line per major step, suppress tool output (apt, curl, etc.)
- Color + emoji output style (green checkmarks, red errors, section dividers)
- Show skipped items on re-runs: "Starship already installed, skipping" — confirms idempotency visually
- Full summary at the end listing every tool installed, config applied, and status (installed/skipped/failed)

### Error handling & recovery
- Continue on failure + report — log failures, continue remaining steps, show all failures in final summary
- Auto backup existing dotfiles to ~/.dotfiles-backup/[timestamp] before applying, no prompt
- Minimal prompts during execution — only prompt for things that can't have defaults (chsh password, SSH source path)
- Let chsh prompt naturally for password — user enters when asked

### Post-bootstrap experience
- Print numbered checklist of remaining manual steps after completion (age key from Bitwarden, gh auth login, tmux prefix+I, claude login)
- Auto-start zsh via `exec zsh` at the end — user lands in new environment immediately
- SSH key setup is part of bootstrap — script prompts for source path (e.g., /mnt/c/Users/.ssh/) and copies with correct permissions (700/600)
- Automatically configure /etc/wsl.conf (systemd=true, interop settings) with sudo

### Claude's Discretion
- Exact section header formatting and emoji choices
- Order of installation steps (dependency resolution)
- How to detect already-installed tools (command -v, dpkg, etc.)
- Temp file handling during downloads
- Whether to use functions internally or linear flow

</decisions>

<specifics>
## Specific Ideas

- curl|bash is the gold standard entry point — should work with zero setup on a fresh machine
- The script should feel like a polished installer, not a raw shell dump — section headers, clear progress, professional output
- Idempotency is critical — running it twice should produce identical results with "skipped" messages on the second run
- SSH key copying prompts for the Windows-side path since this is WSL2 (e.g., /mnt/c/Users/username/.ssh/)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-bootstrap-implementation*
*Context gathered: 2026-02-10*
