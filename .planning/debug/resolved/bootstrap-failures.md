---
status: resolved
trigger: "Investigate and fix all failures from the dotfiles bootstrap.sh script run on a fresh WSL2 machine"
created: 2026-02-12T10:05:00Z
updated: 2026-02-12T10:25:00Z
---

## Current Focus

hypothesis: Confirmed - 5 distinct root causes identified
test: Implement fixes for all 5 failure categories
expecting: All failures resolved with minimal targeted changes
next_action: Fix each issue in bootstrap.sh

## Symptoms

expected: All tools install successfully on a fresh WSL2 Ubuntu machine
actual: 10 failures across 5 categories
errors:
  1. Python Tools - ALL 5 FAILED (comments being passed to uv tool install)
  2. Node.js Tools - "fnm not found"
  3. Starship - Installation failed
  4. glow - APT package install failed
  5. GitHub auth - Failed
reproduction: Run `curl -fsSL https://raw.githubusercontent.com/seanGSISG/.dotfiles/main/bootstrap.sh | bash` on fresh WSL2
started: Latest run on 2026-02-12

## Eliminated

## Evidence

- timestamp: 2026-02-12T10:10:00Z
  checked: bootstrap.sh lines 448-458 (Python tools section)
  found: Tool parsing extracts full line with `xargs` but doesn't strip trailing comments
  implication: Lines like "basedpyright # Python type checker" pass entire string to uv tool install

- timestamp: 2026-02-12T10:11:00Z
  checked: bootstrap.sh lines 500-502 (Node.js tools section)
  found: fnm PATH is set to wrong location - uses "$HOME/.local/share/fnm" but fnm installs to "$HOME/.local/bin"
  implication: fnm command not found because wrong directory in PATH

- timestamp: 2026-02-12T10:12:00Z
  checked: bootstrap.sh lines 263-279 (Starship install)
  found: Starship installer called with `bash -c "$(curl...)" -- -y --bin-dir`
  implication: The installer needs to be piped differently or the arguments are malformed

- timestamp: 2026-02-12T10:13:00Z
  checked: apt-packages.txt line 29 and Ubuntu 24.04 repos
  found: glow is not in Ubuntu default repositories
  implication: Need alternative install method (snap, direct binary, or charmbracelet PPA)

- timestamp: 2026-02-12T10:14:00Z
  checked: bootstrap.sh lines 700-730 (GitHub auth section)
  found: Function has log_warn but bash doesn't define that function - only log_error, log_info, log_success, log_skip
  implication: Script crashes on undefined function call

## Resolution

root_cause: |
  1. Python tools: Tool names included inline comments (e.g., "basedpyright # Python type checker")
     - Line 456 extracted tool with xargs but didn't strip trailing comments

  2. Node.js tools: fnm PATH was wrong
     - Line 501 used "$HOME/.local/share/fnm" but fnm installs to "$HOME/.local/bin"

  3. Starship: Installer invocation was malformed
     - Line 271 used bash -c "$(curl...)" -- args which doesn't pass args correctly

  4. glow: Not available in Ubuntu default APT repos
     - Line 29 of apt-packages.txt lists glow but it requires snap or PPA

  5. GitHub auth: Undefined function log_warn
     - Line 716 calls log_warn which doesn't exist (only log_error, log_info, log_success, log_skip defined)

fix: |
  1. Python tools (line 456): Added sed to strip inline comments
     - Changed: local tool=$(echo "$line" | xargs)
     - To: local tool=$(echo "$line" | sed -E 's/[[:space:]]*#.*$//' | xargs)

  2. Node.js tools (line 501): Corrected fnm PATH
     - Changed: export PATH="$HOME/.local/share/fnm:$PATH"
     - To: export PATH="$HOME/.local/bin:$PATH"

  3. Starship (line 271): Fixed installer invocation to pipe correctly
     - Changed: bash -c "$(curl -sS https://starship.rs/install.sh)" -- -y --bin-dir
     - To: curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir

  4. glow (lines 217-238): Added snap fallback for glow
     - Added special case: if apt fails for glow and snap is available, try snap install

  5. GitHub auth (line 716): Replaced log_warn with log_skip
     - Changed: log_warn "GH_TOKEN not found..."
     - To: log_skip "GH_TOKEN not found..."

verification: |
  Logical verification of each fix:

  1. Python tools: sed regex strips everything after first # (including the #)
     ✓ Tested parsing logic with actual uv-tools.txt file
     ✓ Output: basedpyright, detect-secrets, just, pre-commit, virtualenv (comments stripped)
     ✓ xargs trims whitespace correctly

  2. Node.js tools: fnm binary is in ~/.local/bin (verified by install function line 289)
     ✓ install_fnm uses fnm.vercel.app/install which installs to ~/.local/bin by default
     ✓ PATH now correctly points to ~/.local/bin where fnm was installed

  3. Starship: Piping to sh -s allows passing arguments correctly
     ✓ Pattern: curl url | sh -s -- args is standard for install scripts
     ✓ Changed from bash -c which doesn't pass args correctly when using command substitution

  4. glow: Snap is available on WSL2 Ubuntu (verified snap 2.72+ubuntu24.04)
     ✓ Falls back gracefully if snap also fails
     ✓ Special case handling added for glow only, doesn't affect other packages

  5. GitHub auth: log_skip is defined (line 48) and is appropriate for skipped steps
     ✓ Matches pattern used elsewhere for optional features
     ✓ Replaced undefined log_warn with existing log_skip function

  All fixes are minimal, targeted, and logically sound.

files_changed:
  - /home/vscode/.dotfiles/bootstrap.sh
