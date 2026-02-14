# System Aliases
# System-level and tool-specific shortcuts

# Claude Code
function cc { & claude @args }                      # claude shorthand
function ccd { & claude --dangerously-skip-permissions @args }  # claude (skip perms)

# Azure Key Vault (GSI)
function az-login { & az login --tenant 07e978d3-49bb-4f6c-948d-2908f2e20014 }

# Windows Terminal pane management (replaces tmux shortcuts)
function tn { wt new-tab --title @args -- pwsh -NoLogo }  # new terminal tab
function ts { wt split-pane -H -- pwsh -NoLogo }          # split horizontal
function tv { wt split-pane -V -- pwsh -NoLogo }          # split vertical
