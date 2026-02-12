# dotfiles

WSL2 Ubuntu dev environment managed by chezmoi. One command sets up everything.

## What Gets Installed

- **Shell:** zsh (default) with antidote plugins, Starship prompt, 100k history with dedup
- **Tools:** fnm (Node.js), fzf (fuzzy finder), zoxide (smart cd), uv (Python), bun (JS runtime)
- **Configs:** git (templated), tmux (TPM, XDG paths), Starship (Pure-style theme)
- **Dev tools:** basedpyright, pre-commit, detect-secrets, just, virtualenv, Claude Code
- **System:** GitHub CLI, PowerShell, age encryption, 34 curated apt packages

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/seanGSISG/.dotfiles/main/bootstrap.sh | bash
```

That's it. The script clones the repo, installs everything, and deploys configs. It's idempotent — safe to re-run. It will skip anything already installed.

You'll be prompted for your sudo password and age encryption key (from Bitwarden).

### What It Does

1. Configures WSL2 (`/etc/wsl.conf` with systemd)
2. Adds APT repos (GitHub CLI, PowerShell, Charm) and installs 34 system packages
3. Installs chezmoi and clones this repo
4. Installs binary tools (Starship, fnm, fzf, uv, bun, age)
5. Installs plugin managers (antidote for zsh, TPM for tmux)
6. Installs Python tools via uv and Node.js 22 LTS via fnm
7. Installs Claude Code via official installer
8. Backs up existing dotfiles to `~/.dotfiles-backup/<timestamp>/`
9. Deploys all configs via `chezmoi apply`
10. Changes default shell to zsh

### Post-Install Checklist

After bootstrap completes, it prints this checklist:

1. **Age key** — If skipped during setup, retrieve from Bitwarden, save to `~/.config/age/keys.txt`, then run `chezmoi apply`
2. **Tmux plugins** — Open tmux, press `prefix + I`
3. **Claude Code** — `claude login`
4. **SSH verify** — `ssh -T git@github.com`
5. **WSL restart** — `wsl.exe --shutdown` from PowerShell (enables systemd)

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
├── verify.sh                      # Post-install environment validation
├── dot_zshrc.tmpl                 # .zshrc template
├── dot_bashrc.tmpl                # .bashrc template
├── dot_profile                    # .profile
├── dot_gitconfig.tmpl             # .gitconfig template
├── dot_config/
│   ├── starship.toml              # Starship prompt config
│   ├── tmux/tmux.conf             # tmux config (XDG path)
│   └── zsh/                       # All zsh config modules + aliases
├── dot_claude/                    # Claude Code configs
├── dot_ssh/                       # SSH keys (age-encrypted)
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
chezmoi apply               # Apply changes
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
