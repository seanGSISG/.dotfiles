# .dotfiles

Cross-platform dev environment managed by **chezmoi** with age encryption. Supports WSL2 Ubuntu, Windows 11, and DGX Spark (GB10 Blackwell ARM64).

Source dir: `~/.dotfiles` (symlinked to `~/projects/.dotfiles` on DGX Spark).

## Commands

```bash
# Chezmoi workflow (always use these, never edit deployed files directly)
chezmoi edit <target>          # Edit source file (e.g., chezmoi edit ~/.zshrc)
chezmoi edit ~/.secrets.env    # Edit encrypted secrets
chezmoi diff                   # Preview changes before applying
chezmoi apply --verbose        # Deploy changes
chezmoi add <file>             # Track a new file
chezmoi add --encrypt <file>   # Track with age encryption
chezmoi data                   # Show template variables (is_dgx_spark, is_wsl, etc.)
chezmoi execute-template < file.tmpl  # Test template rendering

# Scripts
./bootstrap.sh                 # Full environment setup (idempotent, WSL2/Linux)
./bootstrap.ps1                # Full environment setup (Windows)
./verify.sh                    # Post-install validation (7 sections, 30+ checks)
```

## Multi-Machine Conditional Deployment

Template variables in `.chezmoi.toml.tmpl` control per-machine behavior:

| Variable | Detection | Files affected |
|---|---|---|
| `is_dgx_spark` | `/etc/dgx-release` exists (via `stat`) | `dgx.zsh`, `aliases-dgx.zsh`, `.dgxspark/`, `bin/cf-sync` |
| `is_wsl` | `kernel.osrelease` contains "microsoft" | `wsl.zsh` |

**Coarse filter:** `.chezmoiignore` excludes entire files on non-matching machines.
**Fine filter:** `.tmpl` files use `{{ if .is_dgx_spark }}` / `{{ if .is_wsl }}` for inline conditionals.

## Chezmoi Naming Conventions

| Prefix/suffix | Meaning | Example |
|---|---|---|
| `dot_` | Deployed with `.` prefix | `dot_zshrc` → `~/.zshrc` |
| `private_` | Mode 0700 (dirs) / 0600 (files) | `private_dot_dgxspark/` → `~/.dgxspark/` |
| `executable_` | Sets executable bit | `executable_cf-sync` → `cf-sync` (+x) |
| `.tmpl` | Chezmoi template (Go text/template) | `dgx.zsh.tmpl` |
| `encrypted_*.age` | Age-encrypted file | `encrypted_dot_secrets.env.age` |
| `run_once_` | Runs once on first apply | `run_once_create-workspace-dirs.sh` |
| `run_once_before_` | Runs once, before other scripts | `run_once_before_install-tools.sh.tmpl` |
| `run_onchange_after_` | Runs after apply when source changes | `run_onchange_after_configure-claude-mcp.sh` |

## File Structure

```
dot_config/zsh/                # Zsh config modules (ZDOTDIR = ~/.config/zsh)
  dot_zshrc.tmpl               # Main .zshrc (pure sourcer, defines load order)
  exports.zsh                  # PATH, env vars, history, SSH stty guard, TERM fallback
  plugins.zsh                  # Antidote plugin manager + completion system (fpath additions go here, pre-compinit)
  tools.zsh                    # node, fzf, zoxide, direnv, atuin, cargo, bun, mise shims
  functions.zsh                # halp, mkcd, reload, cheat, az-*, extract(), auto-ls
  keybindings.zsh              # Ctrl/Alt+Arrow, Home/End, word deletion
  dgx.zsh.tmpl                 # DGX Spark: CUDA, vLLM, HF env vars (conditional)
  wsl.zsh.tmpl                 # WSL2: GNOME Keyring, dbus, WezTerm OSC 7 (conditional)
  private_dot_zsh_plugins.txt  # Antidote plugin manifest (sudo, colored-man-pages, etc.)
  aliases/                     # One file per category
    aliases-navigation.zsh     # j()/jc() workspace jumps (ccenter, projects, labs, models, dotfiles, config)
    aliases-git.zsh
    aliases-docker.zsh
    aliases-dev.zsh
    aliases-dgx.zsh            # DGX: model serving, GPU, stack management (conditional)
    aliases-utilities.zsh      # Modern CLI replacements (lsd/eza/bat/dust/btop/nvim)
    aliases-system.zsh
dot_config/tmux/tmux.conf      # Tmux (TPM plugins, Dracula theme, XDG path)
dot_config/starship.toml       # Starship prompt (Pure-style, SSH hostname module)
dot_gitconfig.tmpl             # Git config (uses chezmoi data variables)
dot_zshenv                     # Sets ZDOTDIR, skips system compinit
dot_bashrc.tmpl                # Bash fallback (DGX/WSL conditional blocks)
bin/executable_cf-sync         # Cloudflare tunnel sync script (DGX only)
private_dot_dgxspark/          # DGX Spark utilities (DGX only)
  scripts/lib/executable_dgx.sh  # Detection, preflight, system info
packages/
  apt-packages.txt             # APT manifest (34 packages, documented)
  uv-tools.txt                 # Python tools via uv
  binary-installs.txt          # Reference for manually-installed binaries
dot_claude/                    # Claude Code config — HAND-WRITTEN FILES ONLY
  CLAUDE.md                    # Global agent instructions (~/.claude/CLAUDE.md)
  encrypted_private_settings.json.age  # settings.json (holds Tavily/Honcho API keys)
  agents/                      # code-architect, code-explorer (the two not from GSD)
  commands/docs.md
  hooks/herdr-agent-state.sh
dot_codex/                     # Codex config — hand-written + CCG only
  private_config.toml, AGENTS.md, hooks.json
  agents/ccg-*.toml, hooks/ccg-workflow.py
dot_config/git/ignore          # Global gitignore
dot_config/gh/private_config.yml  # gh CLI prefs (hosts.yml is ignored — holds OAuth token)
dot_config/zed/private_settings.json
dot_config/herdr/symlink_config.toml.tmpl  # Symlink → ~/projects/herdr-control/config/
dot_config/cship.toml, dot_config/opencode/tui.jsonc, dot_config/private_toad/
private_dot_npmrc              # npm global prefix → ~/.local
private_dot_ssh/               # SSH keys (age-encrypted)
encrypted_dot_secrets.env.age  # Secrets (age-encrypted → ~/.secrets.env)
run_once_before_install-tools.sh.tmpl  # Auto-install CLI tools (starship, zoxide, etc.)
run_once_create-workspace-dirs.sh      # Create ~/projects, ~/labs, ~/tools, ~/tmp
run_onchange_after_configure-claude-mcp.sh  # Configure Claude MCP servers
```

## Zsh Load Order

The `.zshrc` sources files in this exact order — order matters:

1. `exports.zsh` — PATH, env vars, history config, SSH stty guard, TERM fallback
2. `plugins.zsh` — Antidote + compinit (24h cache)
3. `tools.zsh` — node, fzf, zoxide, direnv, atuin, cargo, bun, mise shims (re-prepended after exports.zsh)
4. `functions.zsh` — Shell functions, alias-help, extract(), auto-ls chpwd hook
5. `aliases/*.zsh` — All alias files (loop, includes DGX aliases on Spark)
6. `dgx.zsh` — DGX Spark env (conditional: `{{ if .is_dgx_spark }}`)
7. `wsl.zsh` — WSL2 integrations (conditional: `{{ if .is_wsl }}`)
8. `~/.secrets.env` — Decrypted secrets
9. `keybindings.zsh` — Terminal keybindings (emacs mode, word movement)
10. Starship init — Prompt (must be last, modifies precmd)

## Conventions

- **Commits:** Conventional format — `fix:`, `feat:`, `docs:`, `chore:` prefixes. Descriptive messages explaining "why".
- **Shell scripts:** Use `set -euo pipefail` where appropriate. Color-coded output (check bootstrap.sh patterns).
- **New aliases:** Add to the appropriate category file in `dot_config/zsh/aliases/`. Each alias should have an inline comment.
- **New tools:** Add integration to `tools.zsh` with graceful degradation (`command -v` check). Add package to the relevant manifest in `packages/`.
- **Templates:** Use chezmoi template syntax (`{{ .is_dgx_spark }}`, `{{ .is_wsl }}`, `{{ .chezmoi.os }}`) for machine-specific behavior. Test with `chezmoi execute-template`.
- **DGX-only files:** Use `.chezmoiignore` for coarse exclusion. Use `.tmpl` with `{{ if .is_dgx_spark }}` for inline conditionals.
- **Modern CLI aliases:** Use `command -v` guards so aliases degrade gracefully on machines without the tools.

## Important Warnings

- **Never edit deployed files** (`~/.zshrc`, `~/.gitconfig`, etc.) — changes get overwritten by `chezmoi apply`. Always edit the source in `~/.dotfiles/` via `chezmoi edit`.
- **Never commit plaintext secrets.** Use `chezmoi add --encrypt` for sensitive files. Pre-commit hooks (detect-secrets) scan for leaks.
- **`.chezmoiignore` matters** — Files listed there (README.md, packages/, bootstrap.sh, etc.) are NOT deployed by chezmoi. DGX/WSL conditional blocks exclude platform-specific files.
- **ZDOTDIR architecture** — `~/.zshenv` sets `ZDOTDIR=~/.config/zsh` so all zsh config lives under XDG.
- **Age encryption key** — Lives at `~/.config/age/keys.txt`, sourced from Bitwarden. Never committed to git.
- **Agent config is installer-owned — track only hand-written files.** The GSD installer owns 47 of
  49 `~/.claude/agents`, 26 of 31 `~/.claude/hooks`, and (via `gsd-core/bin/lib/codex-agent-toml.cjs`)
  the `gem-*` agents under `~/.codex`. It tracks them in `~/.claude/gsd-file-manifest.json`. If chezmoi
  also managed them, `apply` would revert GSD updates and GSD updates would read as permanent chezmoi
  drift. `.chezmoiignore` excludes them deliberately — do not `chezmoi add` those directories wholesale.
- **`~/.claude/settings.json` is written at runtime.** Claude Code rewrites it when you change settings
  in-app, so expect it to show as drift. Re-capture with `chezmoi re-add ~/.claude/settings.json`
  rather than letting `apply` clobber an in-app change. It is encrypted because it holds API keys.
- **Node resolves in two tiers.** `mise` shims come first on PATH (set in both `.zshenv` files and
  re-prepended in `tools.zsh` after `exports.zsh`), so a project's `mise.toml` wins inside that project.
  Outside one, the shims fall through to the Node 24 tarball at `~/.local/node` that
  `run_onchange_after_link-node.sh` symlinks into `~/.local/bin`. Both layers are intentional: the
  tarball is what serves scripts, cron, and agent subshells that never load a project config.
- **`skip_global_compinit=1`** — Set in `.zshenv` to prevent system compinit. Custom compinit runs in `plugins.zsh` with caching.
