# Phase 3: Shell Configuration - Context

**Gathered:** 2026-02-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Migrate zsh as primary shell with antidote plugin management, Starship prompt, and modular alias system. Bash becomes a functional fallback with shared aliases. Clean up .profile. All configs use chezmoi templates, no hardcoded paths.

</domain>

<decisions>
## Implementation Decisions

### Alias organization
- Split existing 308-line aliases into 6 category files: git, docker, navigation, utilities, dev, system
- Files named `aliases-{category}.zsh` (e.g., `aliases-git.zsh`)
- Located in `~/.config/zsh/aliases/`
- Alias help command (`?` / `halp`) outputs colorized table with category headers and alias → command columns

### Zshrc modularity
- `.zshrc` is purely a sourcer — no inline config, only source commands
- Sourced files live in `~/.config/zsh/` with explicit load order:
  - `exports.zsh` — PATH, env vars
  - `plugins.zsh` — antidote setup
  - `tools.zsh` — fnm, fzf, zoxide integrations
  - `functions.zsh` — custom functions
  - `aliases/` — 6 category files
  - `wsl.zsh` — WSL2-specific integrations (GNOME Keyring, dbus, WezTerm OSC 7), sourced conditionally via chezmoi template
- Machine-specific differences handled via chezmoi template variables (no gitignored local.zsh)

### Plugin selection
- Antidote plugins: zsh-autosuggestions, zsh-syntax-highlighting, fzf, zoxide, zsh-completions, zsh-history-substring-search
- Clean break from Oh My Zsh — no OMZ libs, themes, or plugins carried forward
- Plugin list managed in `.zsh_plugins.txt` in `~/.config/zsh/` (standard antidote convention)
- Emacs keybinding mode (zsh default)

### Bash fallback
- Functional fallback — PATH, secrets, fnm, basic prompt, core aliases
- Bash sources the same alias files from `~/.config/zsh/aliases/` (most aliases work in both shells)
- Noticeable colored banner on bash login: hint to run `zsh` for full dev environment
- `.profile` cleaned up — minimal, no secrets, no PATH duplication, sources .bashrc if bash

### Claude's Discretion
- Exact zsh history settings (HISTSIZE, dedup behavior)
- Completion system configuration details
- Specific prompt shown in bash fallback
- How to handle missing tools gracefully (e.g., fnm not installed yet)
- Load order optimization within each sourced file

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-shell-configuration*
*Context gathered: 2026-02-10*
