# Phase 4: Tool Configs - Research

**Researched:** 2026-02-10
**Domain:** Terminal tool configuration (git, tmux, Starship prompt)
**Confidence:** HIGH

## Summary

Phase 4 focuses on migrating and templating three core terminal tool configurations: git, tmux, and Starship prompt. This phase depends on Phase 3 (shell configs) which already sources Starship in both `.zshrc` and `.bashrc`.

The standard approach for this phase is:
1. **Git**: Use chezmoi templates (`.tmpl` suffix) with `[data]` section variables for user-specific values (name, email). The existing `.gitconfig` already uses `gh auth` as credential helper, which should be preserved.
2. **Tmux**: Modern practice is to use `~/.config/tmux/tmux.conf` (XDG-compliant path, tmux 3.1+). Use TPM (Tmux Plugin Manager) for plugin management. Current config uses TPM with Dracula theme and tmux-yank.
3. **Starship**: Install via package manager, configure in `~/.config/starship.toml`. Use modules for git, virtualenv, nodejs, and cmd_duration. Starship has built-in presets that can match or exceed P10k's Pure-style aesthetic.

**Primary recommendation:** Use chezmoi's template system for machine-specific values, XDG-compliant paths where supported, and leverage existing plugin managers (TPM for tmux) rather than hand-rolling solutions.

## Standard Stack

### Core Tools

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| chezmoi | 2.x+ | Dotfile manager with templating | Industry standard for multi-machine dotfiles, built-in secrets management, Go templates |
| Starship | 1.x+ (latest) | Cross-shell prompt | Actively maintained (unlike P10k), Rust-based speed, universal shell support, rich modules |
| tmux | 3.1+ | Terminal multiplexer | XDG-compliant path support, stable API, session persistence |
| TPM | latest | Tmux Plugin Manager | De facto standard for tmux plugins, simple git-based management |
| git | 2.x+ | Version control | Universal, gh CLI integration for credentials |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| age | latest | Encryption for secrets | Already used in Phase 1 for `.secrets.env` |
| gh CLI | latest | GitHub authentication | Git credential helper (already configured) |
| Nerd Fonts | latest | Icon glyphs for Starship | Required for Starship symbols/icons |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Starship | Powerlevel10k | P10k is on life support (unmaintained since 2024), zsh-only, harder to customize |
| TPM | Manual plugin management | TPM standardizes plugin installation/updates, no benefit to manual approach |
| chezmoi templates | Hardcoded paths | Templates enable multi-machine support, secrets separation |

**Installation:**

Starship is already available via package managers:
```bash
# Linux (curl)
curl -sS https://starship.rs/install.sh | sh

# Or via cargo
cargo install starship --locked

# Or via apt/brew
brew install starship  # macOS/Linux
```

TPM is installed via git clone:
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Or in XDG path:
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

With chezmoi, use `.chezmoiexternal.toml` to automate TPM installation.

## Architecture Patterns

### Recommended Project Structure

```
~/.dotfiles/                           # chezmoi source directory
├── .chezmoi.toml.tmpl                # Template variables (hostname, username)
├── dot_gitconfig.tmpl                # Templated git config
├── dot_tmux.conf                     # Tmux config (or use XDG path below)
├── dot_config/
│   ├── starship.toml                 # Starship prompt config
│   └── tmux/
│       └── tmux.conf                 # Modern XDG-compliant tmux config
└── .chezmoiexternal.toml             # TPM auto-installation

After chezmoi apply:
~/.config/
├── chezmoi/
│   └── chezmoi.toml                  # Processed template with [data]
├── starship.toml                     # Starship config
└── tmux/
    ├── tmux.conf                     # Tmux config
    └── plugins/
        └── tpm/                      # Auto-cloned by chezmoi
```

### Pattern 1: Chezmoi Template Variables for Machine-Specific Values

**What:** Use `[data]` section in `chezmoi.toml` to store machine-specific values, reference in `.tmpl` files.

**When to use:** Any config file with machine-specific values (username, email, paths, hostnames).

**Example:**
```toml
# ~/.config/chezmoi/chezmoi.toml (generated from .chezmoi.toml.tmpl)
[data]
hostname = "{{ .chezmoi.hostname }}"
username = "{{ .chezmoi.username }}"
git_name = "Your Name"
git_email = "you@example.com"
```

```gitconfig
# ~/.dotfiles/dot_gitconfig.tmpl
[user]
    name = {{ .git_name | quote }}
    email = {{ .git_email | quote }}

[credential "https://github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
```

**Source:** https://chezmoi.io/user-guide/manage-machine-to-machine-differences/

### Pattern 2: XDG-Compliant Configuration Paths

**What:** Use `~/.config/<tool>/` paths instead of `~/.<tool>` dotfiles where supported.

**When to use:** Modern tools that support XDG Base Directory spec (tmux 3.1+, starship, etc).

**Example:**
```bash
# Old approach (deprecated):
~/.tmux.conf
~/.tmux/plugins/tpm

# XDG approach (modern):
~/.config/tmux/tmux.conf
~/.config/tmux/plugins/tpm
```

**Benefits:**
- Cleaner home directory
- Standardized config location
- Better for containerization
- TPM auto-detects `~/.config/tmux/` and uses it

**Source:** Multiple sources confirm tmux 3.1+ supports XDG paths automatically.

### Pattern 3: TPM Plugin Declaration

**What:** Declare tmux plugins in `tmux.conf` with `set -g @plugin`, then run TPM install.

**When to use:** All tmux plugin installations.

**Example:**
```tmux
# ~/.config/tmux/tmux.conf
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'dracula/tmux'

# Dracula theme customization
set -g @dracula-plugins "battery"
set -g @dracula-show-left-icon session
set -g @dracula-show-timezone false

# Initialize TPM (keep at bottom)
run '~/.config/tmux/plugins/tpm/tpm'
```

**Install plugins:** `prefix + I` (capital I) or `~/.config/tmux/plugins/tpm/bin/install_plugins`

**Source:** https://github.com/tmux-plugins/tpm

### Pattern 4: Starship Module Configuration

**What:** Configure Starship modules in `~/.config/starship.toml` to control what appears in prompt.

**When to use:** Customizing prompt appearance and behavior.

**Example:**
```toml
# ~/.config/starship.toml

# Minimal format - only show what matters
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$python\
$nodejs\
$cmd_duration\
$line_break\
$character"""

[character]
success_symbol = '[❯](bold magenta)'
error_symbol = '[❯](bold red)'

[git_branch]
symbol = ' '
format = 'on [$symbol$branch]($style) '
style = 'bold purple'

[git_status]
format = '([$all_status$ahead_behind]($style) )'
style = 'bold red'
conflicted = '🏳'
ahead = '⇡${count}'
behind = '⇣${count}'
diverged = '⇕⇡${ahead_count}⇣${behind_count}'
up_to_date = '✓'
untracked = '?'
stashed = '$'
modified = '!'
staged = '+'
renamed = '»'
deleted = '✘'

[python]
symbol = ' '
format = 'via [$symbol$virtualenv]($style) '
style = 'yellow bold'
detect_extensions = ['py']
detect_files = ['.python-version', 'Pipfile', 'pyproject.toml', 'requirements.txt']

[nodejs]
symbol = ' '
format = 'via [$symbol($version )]($style)'
style = 'bold green'
detect_files = ['package.json', '.node-version', '.nvmrc']
detect_folders = ['node_modules']

[cmd_duration]
min_time = 5_000  # 5 seconds
format = 'took [$duration]($style) '
style = 'bold yellow'

[directory]
style = 'bold blue'
truncation_length = 3
truncate_to_repo = true
```

**Source:** https://context7.com/starship/starship/llms.txt (Context7)

### Pattern 5: Chezmoi External Resources for Plugin Managers

**What:** Use `.chezmoiexternal.toml` to auto-clone git repositories (like TPM).

**When to use:** Tools that need external git repos cloned (plugin managers, themes).

**Example:**
```toml
# ~/.dotfiles/.chezmoiexternal.toml
[".config/tmux/plugins/tpm"]
    type = "git-repo"
    url = "https://github.com/tmux-plugins/tpm"
    refreshPeriod = "168h"  # 1 week
```

**Benefits:**
- chezmoi handles initial clone and updates
- Consistent across machines
- No manual git clone steps

**Source:** https://www.lorenzobettini.it/2025/04/installing-the-tmux-plugin-manager-tpm-with-chezmoi/

### Anti-Patterns to Avoid

- **Hardcoded paths with /home/username**: Use `$HOME`, `~`, or chezmoi template variables instead (violates CONF-03).
- **Storing secrets in plain .gitconfig**: Use chezmoi templates + encrypted data or reference external credential helpers.
- **Manual symlink management**: Defeats the purpose of chezmoi.
- **Mixing ~/.file and ~/.config/file paths**: Pick one convention (prefer XDG).
- **Ignoring Starship presets**: Start with a preset, then customize (faster than building from scratch).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tmux plugin management | Custom install/update scripts | TPM | Handles plugin dependencies, updates, loading order. Standard in community. |
| Git credential storage | Custom credential scripts | `gh auth` credential helper | Already configured, integrates with GitHub CLI, secure token management. |
| Prompt git status | Manual git commands in PS1 | Starship git modules | Optimized, async, handles edge cases (detached HEAD, submodules, etc). |
| Cross-machine config differences | Multiple git branches | chezmoi templates + [data] | Single source of truth, machine-specific values injected at apply time. |
| Starship theming | Writing TOML from scratch | Starship presets | `starship preset <name>` generates complete themes (pure-preset, pastel-powerline, tokyo-night, etc). |

**Key insight:** These tools have large communities and have solved edge cases (tmux plugin conflicts, git credential security, prompt async updates, multi-machine templating). Hand-rolled solutions will be less robust and harder to maintain.

## Common Pitfalls

### Pitfall 1: Not Using chezmoi Template Variables for Git Config

**What goes wrong:** Hardcoding name/email in `dot_gitconfig` defeats multi-machine purpose. Each machine requires manual editing.

**Why it happens:** Developers forget to add `[data]` section to `chezmoi.toml` or don't use `.tmpl` suffix.

**How to avoid:**
1. Use `dot_gitconfig.tmpl` (note `.tmpl` suffix)
2. Add git_name and git_email to `[data]` section in `.chezmoi.toml.tmpl`
3. Reference with `{{ .git_name | quote }}` syntax
4. On first machine setup, `chezmoi init` will prompt for values (or use `chezmoi edit-config`)

**Warning signs:** Seeing literal `{{ .git_name }}` in deployed `.gitconfig` (template not processed).

**Source:** https://chezmoi.io/user-guide/manage-machine-to-machine-differences/

### Pitfall 2: Wrong Starship Module Detection

**What goes wrong:** Starship modules don't appear when expected (nodejs doesn't show in node project).

**Why it happens:** Detection logic relies on specific files/folders. If `package.json` is in parent directory, nodejs module may not trigger.

**How to avoid:**
- Understand detect_files, detect_folders, detect_extensions per module
- Use `starship explain` to debug why modules aren't showing
- Test in actual project directories
- Consider adjusting `truncate_to_repo` for directory module

**Warning signs:** Modules missing in directories where they should appear.

**Source:** https://context7.com/starship/starship/llms.txt

### Pitfall 3: TPM Plugin Install Not Run

**What goes wrong:** Tmux config declares plugins, but they're not loaded. Tmux shows errors like "unknown option: @plugin".

**Why it happens:** TPM plugins declared but never installed. Need to run `prefix + I` after adding plugins.

**How to avoid:**
1. After modifying plugin list in `tmux.conf`, reload config: `tmux source-file ~/.config/tmux/tmux.conf`
2. Install new plugins: `prefix + I` (capital I) inside tmux
3. Or run manually: `~/.config/tmux/plugins/tpm/bin/install_plugins`

**Warning signs:** Error messages in tmux status line about unknown variables/options starting with `@`.

**Source:** TPM documentation and common user reports.

### Pitfall 4: Hardcoded /home/vscode Paths (CONF-03 Violation)

**What goes wrong:** Config works in current environment but breaks on different machines or when username changes.

**Why it happens:** Copy-pasting absolute paths instead of using home directory references.

**How to avoid:**
- Use `$HOME` or `~` in config files
- Use chezmoi template variables: `{{ .chezmoi.homeDir }}`
- Grep configs for hardcoded paths: `grep -r "/home/vscode" ~/.dotfiles/`
- In tmux.conf, paths like `~/.config/tmux/plugins/tpm/tpm` work across machines

**Warning signs:** Configs break when applied on new machine with different username.

**Example fix:**
```bash
# BAD:
run '/home/vscode/.tmux/plugins/tpm/tpm'

# GOOD:
run '~/.config/tmux/plugins/tpm/tpm'
```

### Pitfall 5: Starship Performance with Too Many Modules

**What goes wrong:** Prompt becomes sluggish, delays appear before showing prompt.

**Why it happens:** Every enabled module adds processing time. Scanning for language versions can be slow in large directories.

**How to avoid:**
- Only enable modules you actually use
- Set `min_time` for cmd_duration to avoid showing every command
- Use `detect_files` to limit when modules activate
- Consider disabling modules in specific directories via `.starship.toml` in project root
- Benchmark with `starship timings` command

**Warning signs:** Noticeable delay (>100ms) before prompt appears.

**Source:** Community best practices from Starship migration guides.

## Code Examples

Verified patterns from official sources:

### Templated Git Config with chezmoi

```gitconfig
# ~/.dotfiles/dot_gitconfig.tmpl
# Source: https://chezmoi.io/user-guide/templating/

[credential "https://github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential

[credential "https://gist.github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential

[user]
    name = {{ .git_name | quote }}
    email = {{ .git_email | quote }}

{{- if hasKey . "git_signing_key" }}
[gpg]
    format = ssh

[user]
    signingkey = {{ .git_signing_key | quote }}

[commit]
    gpgsign = true
{{- end }}

[core]
    editor = {{ .editor | default "code --wait" | quote }}
    autocrlf = input

[init]
    defaultBranch = main

[pull]
    rebase = false

[push]
    default = simple
    autoSetupRemote = true
```

### Starship Config Matching P10k Pure Style

```toml
# ~/.config/starship.toml
# Source: Context7 Starship documentation
# Emulates P10k Pure style: minimal, clean, informative

format = """
[](bold blue)\
$directory\
$git_branch\
$git_status\
$python\
$nodejs\
$cmd_duration\
$line_break\
$character"""

# Minimal prompt char (like Pure)
[character]
success_symbol = '[❯](bold magenta)'
error_symbol = '[❯](bold red)'

[directory]
style = 'bold blue'
truncation_length = 3
truncate_to_repo = true
format = '[$path]($style) '

# Git branch - clean style
[git_branch]
symbol = ''
format = 'on [$symbol$branch]($style) '
style = 'bold cyan'
truncation_length = 20

# Git status - show dirty state
[git_status]
format = '([$all_status$ahead_behind]($style) )'
style = 'bold red'
conflicted = '='
ahead = '⇡${count}'
behind = '⇣${count}'
diverged = '⇕'
untracked = '?'
stashed = '$'
modified = '!'
staged = '+'
renamed = '»'
deleted = '✘'

# Python virtualenv (grey, minimal)
[python]
symbol = ' '
format = 'via [$symbol$virtualenv]($style) '
style = 'dimmed yellow'
detect_extensions = ['py']
detect_files = ['.python-version', 'Pipfile', 'pyproject.toml', 'requirements.txt']
# Don't show Python version, just virtualenv name
python_binary = ['python3', 'python']
pyenv_version_name = false

# Node.js version (when in node project)
[nodejs]
symbol = ' '
format = 'via [$symbol($version )]($style)'
style = 'bold green'
detect_files = ['package.json', '.node-version', '.nvmrc']
detect_folders = ['node_modules']

# Command duration (only show if >= 5s, like P10k default)
[cmd_duration]
min_time = 5_000
format = 'took [$duration]($style) '
style = 'bold yellow'
show_milliseconds = false

# Hide unnecessary modules
[package]
disabled = true

[time]
disabled = true
```

### Modern Tmux Config with TPM

```tmux
# ~/.config/tmux/tmux.conf (or ~/.dotfiles/dot_config/tmux/tmux.conf for chezmoi)
# Source: Current .tmux.conf + XDG best practices

# Enable mouse
set -g mouse on

# Increase scrollback buffer
set -g history-limit 50000

# Enable activity alerts
setw -g monitor-activity on
set -g visual-activity on

# Start window/pane numbering at 1
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Reload config file easily
bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

# Better splitting (use current path)
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'dracula/tmux'

# Dracula theme customization
set -g @dracula-plugins "battery"
set -g @dracula-show-left-icon session
set -g @dracula-show-timezone false

# tmux-yank configuration
set -g @yank_action 'copy-pipe-and-cancel'
bind -T copy-mode C-c send -X copy-pipe-no-clear "xsel -i --clipboard"
bind -T copy-mode-vi C-c send -X copy-pipe-no-clear "xsel -i --clipboard"

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.config/tmux/plugins/tpm/tpm'
```

### Chezmoi External Resources for TPM

```toml
# ~/.dotfiles/.chezmoiexternal.toml
# Source: https://www.lorenzobettini.it/2025/04/installing-the-tmux-plugin-manager-tpm-with-chezmoi/

[".config/tmux/plugins/tpm"]
    type = "git-repo"
    url = "https://github.com/tmux-plugins/tpm"
    refreshPeriod = "168h"  # Update weekly
```

### Adding Git Variables to chezmoi Template

```toml
# ~/.dotfiles/.chezmoi.toml.tmpl
# Source: Existing file + git variable additions

sourceDir = "~/.dotfiles"

encryption = "age"
[age]
identity = "~/.config/age/keys.txt"
recipient = "age1jlfdynhp3lzz88evlm5dtnd70ndusz25cfudllgdyh8eka9lh5rq07kg3r"  # pragma: allowlist secret

[data]
hostname = "{{ .chezmoi.hostname }}"
username = "{{ .chezmoi.username }}"
# Add git-specific variables (will prompt on first run or set via chezmoi edit-config)
git_name = "Your Name"
git_email = "you@example.com"
editor = "code --wait"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Powerlevel10k prompt | Starship | 2024-2025 | P10k on life support (no active development). Starship is actively maintained, cross-shell, Rust performance. |
| ~/.tmux.conf | ~/.config/tmux/tmux.conf | tmux 3.1 (2020) | XDG compliance, cleaner home directory. TPM auto-detects new path. |
| Manual dotfile symlinks | chezmoi templating | 2019+ | Machine-specific values, secrets management, atomic apply. |
| git credential.helper store | gh auth git-credential | 2021+ | Secure token management, automatic refresh, GitHub CLI integration. |
| Manual plugin management | TPM/plugin managers | 2015+ | Standardized, handles updates, community plugins. |

**Deprecated/outdated:**
- **Powerlevel10k**: On life support since 2024. Developer explicitly stated no active maintenance. Still works but no new features/fixes.
- **~/.tmux.conf over ~/.config/tmux/tmux.conf**: Old path still works but not XDG-compliant.
- **git credential.helper store**: Stores credentials in plain text. Use secure helpers (gh, gcm, osxkeychain).
- **Hardcoded paths in configs**: Breaks multi-machine workflow. Use variables/templates.

## Open Questions

Things that couldn't be fully resolved:

1. **Should Starship be installed via chezmoi or assumed pre-installed?**
   - What we know: Phase 3 shell configs already source Starship with `command -v starship` check. Current environment doesn't have Starship installed yet.
   - What's unclear: Whether to add Starship to packages/install.sh or assume manual install.
   - Recommendation: Add to packages/install.sh for automation, keep the conditional check in shell configs for graceful degradation.

2. **Starship preset vs custom config?**
   - What we know: Starship has presets that can match P10k aesthetic. Current P10k uses "Pure" style (minimal, clean).
   - What's unclear: Whether to start with `starship preset pure-preset` or build custom config.
   - Recommendation: Start with pure-preset as base, customize specific modules (add nodejs, adjust cmd_duration threshold to match P10k's 5s).

3. **XDG path for all tools or mixed approach?**
   - What we know: tmux 3.1+ supports XDG. Git doesn't (must use ~/.gitconfig). Starship uses ~/.config/starship.toml.
   - What's unclear: Whether to force XDG everywhere via aliases/env vars.
   - Recommendation: Use XDG where natively supported (tmux, starship), keep standard paths for tools that don't support it (git).

4. **Nerd Font installation/requirement**
   - What we know: Starship icons require Nerd Fonts. P10k config shows "nerdfont-v3 + powerline" was configured.
   - What's unclear: Which Nerd Font to standardize on, how to ensure it's installed.
   - Recommendation: Document font requirement in README, don't enforce specific font (user's terminal preference). Starship has no-nerd-font preset as fallback.

## Sources

### Primary (HIGH confidence)

- Context7 /starship/starship - Starship configuration, modules, presets
- https://chezmoi.io/user-guide/manage-machine-to-machine-differences/ - chezmoi template patterns
- https://chezmoi.io/user-guide/templating/ - chezmoi template syntax
- https://github.com/tmux-plugins/tpm - TPM documentation

### Secondary (MEDIUM confidence)

- https://jpcaparas.medium.com/dotfiles-managing-machine-specific-gitconfig-with-chezmoi-user-defined-template-variables-400071f663c0 - chezmoi gitconfig templating patterns
- https://www.lorenzobettini.it/2025/04/installing-the-tmux-plugin-manager-tpm-with-chezmoi/ - TPM with chezmoi external resources
- https://nickjanetakis.com/blog/put-all-of-your-tmux-configs-and-plugins-in-a-config-tmux-directory - Modern tmux XDG path practices
- https://hashir.blog/2025/06/powerlevel10k-is-on-life-support-hello-starship - P10k deprecation, Starship migration rationale
- https://bulimov.me/post/2025/05/11/powerlevel10k-to-starship/ - P10k to Starship migration experience

### Tertiary (LOW confidence)

- https://dev.to/therubberduckiee/how-to-configure-starship-to-look-exactly-like-p10k-zsh-warp-h9h - Community Starship config examples
- https://raine.dev/blog/my-tmux-setup/ - Modern tmux workflow patterns (2026)
- https://dreamsofcode.io/blog/zen-tmux-configuration - Tmux configuration philosophy
- https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git - Git credential storage best practices

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Context7 verified Starship docs, official chezmoi docs, established tools (git, tmux, TPM)
- Architecture: HIGH - Patterns verified from official documentation and established community practices
- Pitfalls: MEDIUM-HIGH - Based on common user issues and official troubleshooting, some from community experience

**Research date:** 2026-02-10
**Valid until:** 2026-03-10 (30 days - stable tooling domain)

**Key findings:**
- Starship is the modern replacement for P10k (actively maintained, cross-shell compatible)
- chezmoi templates solve CONF-02 requirement (git user templating) and CONF-03 (no hardcoded paths)
- XDG-compliant paths are standard for tmux 3.1+ and Starship
- TPM is de facto standard for tmux plugin management, integrates with chezmoi via .chezmoiexternal.toml
- Current P10k config uses "Pure" style - Starship has equivalent pure-preset as starting point
- Phase 3 already configured shell to source Starship, this phase focuses on configuration files
