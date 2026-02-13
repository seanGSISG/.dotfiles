# .dotfiles

WSL2 Ubuntu dev environment managed by **chezmoi** with age encryption. Source dir: `~/.dotfiles`.

## Commands

```bash
# Chezmoi workflow (always use these, never edit deployed files directly)
chezmoi edit <target>          # Edit source file (e.g., chezmoi edit ~/.zshrc)
chezmoi edit ~/.secrets.env    # Edit encrypted secrets
chezmoi diff                   # Preview changes before applying
chezmoi apply --verbose        # Deploy changes
chezmoi add <file>             # Track a new file
chezmoi add --encrypt <file>   # Track with age encryption

# Scripts
./bootstrap.sh                 # Full environment setup (idempotent)
./verify.sh                    # Post-install validation (8 sections, 40+ checks)
```

## Chezmoi Naming Conventions

Files in this repo use chezmoi's naming scheme. Know these prefixes:

| Prefix/suffix | Meaning | Example |
|---|---|---|
| `dot_` | Deployed with `.` prefix | `dot_zshrc` → `~/.zshrc` |
| `private_` | Mode 0600 | `private_dot_ssh/` → `~/.ssh/` |
| `.tmpl` | Chezmoi template (Go text/template) | `dot_gitconfig.tmpl` |
| `encrypted_*.age` | Age-encrypted file | `encrypted_dot_secrets.env.age` |
| `run_onchange_after_` | Chezmoi script hook | Runs after apply when source changes |

## File Structure

```
dot_config/zsh/              # Zsh config modules (ZDOTDIR = ~/.config/zsh)
  dot_zshrc.tmpl             # Main .zshrc (pure sourcer, defines load order)
  exports.zsh                # PATH, env vars, history (100k lines, dedup)
  plugins.zsh                # Antidote plugin manager + completion system
  tools.zsh                  # fnm, fzf, zoxide integrations
  functions.zsh              # Custom functions (halp, mkcd, reload, cheat, az-*)
  wsl.zsh.tmpl               # WSL2: GNOME Keyring, dbus, WezTerm OSC 7
  private_dot_zsh_plugins.txt  # Antidote plugin manifest
  aliases/                   # One file per category (git, docker, dev, nav, system, utils)
dot_config/tmux/tmux.conf    # Tmux (TPM plugins, Dracula theme, XDG path)
dot_config/starship.toml     # Starship prompt (Pure-style theme)
dot_gitconfig.tmpl           # Git config (uses chezmoi data variables)
dot_zshenv                   # Sets ZDOTDIR, skips system compinit
dot_bashrc.tmpl              # Minimal bash fallback (shares alias files with zsh)
packages/
  apt-packages.txt           # APT manifest (34 packages, documented)
  uv-tools.txt               # Python tools via uv (basedpyright, pre-commit, etc.)
  binary-installs.txt        # Reference for manually-installed binaries
dot_claude/                  # Claude Code hooks, settings, learning system
private_dot_ssh/             # SSH keys (age-encrypted)
encrypted_dot_secrets.env.age  # Secrets (age-encrypted → ~/.secrets.env)
```

## Zsh Load Order

The `.zshrc` sources files in this exact order — order matters:

1. `exports.zsh` — PATH, env vars, history config
2. `plugins.zsh` — Antidote + compinit (24h cache)
3. `tools.zsh` — fnm, fzf, zoxide
4. `functions.zsh` — Shell functions and alias-help system
5. `aliases/*.zsh` — All alias files (loop)
6. `wsl.zsh` — WSL2-specific (conditional via chezmoi template)
7. `~/.secrets.env` — Decrypted secrets
8. Starship init — Prompt (must be last, modifies precmd)

## Conventions

- **Commits:** Conventional format — `fix:`, `feat:`, `docs:`, `chore:` prefixes. Descriptive messages explaining "why".
- **Shell scripts:** Use `set -euo pipefail` where appropriate. Color-coded output (check bootstrap.sh patterns).
- **New aliases:** Add to the appropriate category file in `dot_config/zsh/aliases/`. Each alias should have an inline comment.
- **New tools:** Add integration to `tools.zsh` with graceful degradation (`command -v` check). Add package to the relevant manifest in `packages/`.
- **Templates:** Use chezmoi template syntax (`{{ .chezmoi.os }}`, `{{ .variable }}`) for machine-specific behavior. Test with `chezmoi execute-template`.

## Important Warnings

- **Never edit deployed files** (`~/.zshrc`, `~/.gitconfig`, etc.) — changes get overwritten by `chezmoi apply`. Always edit the source in `~/.dotfiles/` via `chezmoi edit`.
- **Never commit plaintext secrets.** Use `chezmoi add --encrypt` for sensitive files. Pre-commit hooks (detect-secrets) scan for leaks.
- **`.chezmoiignore` matters** — Files listed there (README.md, packages/, bootstrap.sh, verify.sh, .planning/) are NOT deployed by chezmoi. They exist only in the repo.
- **ZDOTDIR architecture** — `~/.zshenv` sets `ZDOTDIR=~/.config/zsh` so all zsh config lives under XDG. The root `~/.zshrc` is a stub.
- **Age encryption key** — Lives at `~/.config/age/keys.txt`, sourced from Bitwarden. Never committed to git.
- **`skip_global_compinit=1`** — Set in `.zshenv` to prevent system compinit. Custom compinit runs in `plugins.zsh` with caching.
