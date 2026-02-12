# Phase 6: Migration & Testing - Context

**Gathered:** 2026-02-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Deploy complete dotfiles environment to a fresh WSL2 Ubuntu machine (user `adminuser`) and validate all functionality works end-to-end. This includes adding SSH keys to the chezmoi repo (encrypted), adding bootstrap logging, creating a standalone verification script, and running the full deployment on the target machine.

</domain>

<decisions>
## Implementation Decisions

### Target machine setup
- Fresh WSL2 Ubuntu install — no prior customization, default packages only
- Username is `adminuser` (different from dev machine `vscode`) — configs must handle this via chezmoi templates
- Bootstrap delivered via `curl` from GitHub raw URL (no git clone required first)
- Full internet access from the start — no proxy or air-gap concerns

### Validation strategy
- Standalone `verify.sh` script (not built into bootstrap.sh)
- Checks that tools exist on PATH and config files are deployed — not deep functional tests
- Pass/fail per check with summary (checkmark/X per item, total passed/failed at end)

### Failure handling
- Keep current continue-on-failure behavior in bootstrap.sh (collect errors, keep going, show summary)
- Add `tee` logging — output goes to screen AND a log file for post-mortem debugging
- Recovery approach: fix the issue, re-run bootstrap (idempotent by design)
- No pre-flight checks — errors surface naturally
- No changes to bootstrap's error handling logic

### Secrets & SSH keys
- Age encryption key: bootstrap prompts user to paste it if `~/.config/age/keys.txt` not found
- SSH keys: add entire `~/.ssh/` directory to chezmoi repo, age-encrypted
- All SSH private keys encrypted via `chezmoi add --encrypt`
- Keys deploy automatically on `chezmoi apply` (after age key is in place)

### Claude's Discretion
- Log file location and naming convention
- verify.sh check ordering and grouping
- Exact curl command for bootstrap delivery
- How to handle chezmoi template differences for adminuser vs vscode

</decisions>

<specifics>
## Specific Ideas

- User wants SSH keys in the repo so they download automatically — no manual SCP step
- Bootstrap should prompt for age key paste if not found (interactive step during setup)
- verify.sh is reusable — can run anytime after bootstrap, not just during initial setup

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-migration-testing*
*Context gathered: 2026-02-12*
