# dotfiles

WSL2 Ubuntu dev environment managed by chezmoi. One command sets up everything.

## What Gets Installed

**Shell:** zsh (default) with antidote plugins, Starship prompt, 100k history with dedup
**Tools:** fnm (Node.js), fzf (fuzzy finder), zoxide (smart cd), uv (Python), bun (JS runtime)
**Configs:** git (templated), tmux (TPM, XDG paths), Starship (Pure-style theme)
**Dev tools:** basedpyright, pre-commit, detect-secrets, just, virtualenv, Claude Code
**System:** GitHub CLI, PowerShell, age encryption, 34 curated apt packages

## Quick Start (New Machine)

```bash
# Clone and run bootstrap
git clone https://github.com/seanGSISG/.dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

Or from an existing clone:

```bash
~/.dotfiles/bootstrap.sh
```

The bootstrap script is idempotent — safe to re-run. It will skip anything already installed.

### What Bootstrap Does

1. Configures WSL2 (`/etc/wsl.conf` with systemd)
2. Adds APT repos (GitHub CLI, PowerShell) and installs system packages
3. Installs binary tools (Starship, fnm, fzf, uv, bun, age)
4. Installs antidote (zsh plugin manager)
5. Installs Python tools via uv and Node.js 22 LTS via fnm
6. Backs up existing dotfiles to `~/.dotfiles-backup/<timestamp>/`
7. Deploys all configs via `chezmoi init --apply`
8. Changes default shell to zsh
9. Copies SSH keys (interactive, skippable)

### Post-Install Checklist

After bootstrap completes, it prints this checklist:

1. **Age key** — Retrieve from Bitwarden, save to `~/.config/age/keys.txt`, run `chezmoi apply`
2. **GitHub auth** — `gh auth login`
3. **Tmux plugins** — Open tmux, press `prefix + I`
4. **Claude Code** — `claude login`
5. **SSH verify** — `ssh -T git@github.com`
6. **WSL restart** — `wsl.exe --shutdown` from PowerShell (enables systemd)

## Secrets & Encryption

Secrets are stored in `~/.secrets.env`, encrypted in the repo as `encrypted_dot_secrets.env.age`. The age key (`~/.config/age/keys.txt`) lives in Bitwarden, never in git.

```bash
# Edit secrets (opens decrypted in $EDITOR)
chezmoi edit ~/.secrets.env

# Apply (re-encrypts)
chezmoi apply --verbose
```

On a new machine, retrieve the age key from Bitwarden and save to `~/.config/age/keys.txt` before running `chezmoi apply` to decrypt secrets.

## Shell Configuration

Zsh is the primary shell with a modular config structure:

```
~/.config/zsh/
├── exports.zsh          # PATH, env vars, history settings
├── plugins.zsh          # antidote + completion system
├── tools.zsh            # fnm, fzf, zoxide integrations
├── wsl.zsh              # GNOME Keyring, dbus, WezTerm OSC 7
├── functions.zsh        # alias-help system, reload, mkcd
├── .zsh_plugins.txt     # antidote plugin list
└── aliases/
    ├── aliases-navigation.zsh
    ├── aliases-git.zsh
    ├── aliases-docker.zsh
    ├── aliases-dev.zsh
    ├── aliases-utilities.zsh
    └── aliases-system.zsh
```

`.zshrc` is a pure sourcer — it only sources these files. Run `halp` or `?` for categorized alias help.

Bash is a minimal fallback that sources the same alias files and shows a hint to use zsh.

## Directory Structure

```
~/.dotfiles/                       # chezmoi source (this repo)
├── bootstrap.sh                   # Idempotent installer script
├── dot_zshrc.tmpl                 # .zshrc template
├── dot_bashrc.tmpl                # .bashrc template
├── dot_profile                    # .profile
├── dot_gitconfig.tmpl             # .gitconfig template
├── dot_config/
│   ├── starship.toml              # Starship prompt config
│   ├── tmux/tmux.conf             # tmux config (XDG path)
│   └── zsh/                       # All zsh config modules + aliases
├── encrypted_dot_secrets.env.age  # Encrypted secrets
├── packages/
│   ├── apt-packages.txt           # System packages manifest
│   ├── uv-tools.txt               # Python tools manifest
│   └── binary-installs.txt        # Binary tools reference
└── .planning/                     # Project planning docs
```

## Day-to-Day Usage

```bash
chezmoi status              # View current status
chezmoi diff                # Dry-run — see what would change
chezmoi edit ~/.bashrc      # Edit a managed file
chezmoi edit ~/.secrets.env # Edit encrypted secrets
chezmoi apply --verbose     # Apply changes
chezmoi add ~/.config/foo   # Add a new file to chezmoi
chezmoi add --encrypt ~/.keys  # Add encrypted file
```

## Safety

- **Pre-commit hooks** scan for plaintext secrets via detect-secrets
- **Age encryption** ensures only `.age` files are committed, never plaintext
- Always `chezmoi diff` before `chezmoi apply`
- Edit managed files via `chezmoi edit`, not directly

## References

- [chezmoi](https://www.chezmoi.io/) | [age](https://github.com/FiloSottile/age) | [Starship](https://starship.rs/) | [antidote](https://getantidote.github.io/) | [fnm](https://github.com/Schniz/fnm)
