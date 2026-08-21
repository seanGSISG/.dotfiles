# dotfiles

Cross-platform dev environment managed by chezmoi. Supports **WSL2 Ubuntu**, **Windows 11**, and **DGX Spark** (GB10 Blackwell ARM64). One command sets up everything.

> **Windows Note:** Includes PowerShell 7 configs and auto-installs CaskaydiaCove Nerd Font. See `packages/winget-packages.txt`.
> **DGX Spark Note:** Includes CUDA/vLLM environment, model serving aliases, and GPU tooling. DGX-specific files deploy only on DGX systems (detected via `/etc/dgx-release`).

## What Gets Installed

- **Shell:** zsh (default) with antidote plugins, Starship prompt, 100k history with dedup
- **Tools:** fzf, zoxide, atuin (shell history), uv (Python), Node.js 24 LTS, bun (JS runtime)
- **Modern CLI:** lsd/eza (ls), bat (cat), dust (du), btop (top), nvim (vim) — conditional aliases
- **Configs:** git (templated), tmux (TPM, XDG paths), Starship (Pure-style, SSH hostname)
- **Dev tools:** basedpyright, pre-commit, detect-secrets, just, virtualenv
- **System:** GitHub CLI, PowerShell, age encryption, 34 curated apt packages
- **DGX Spark:** CUDA paths, vLLM/Blackwell env vars, model serving aliases, cf-sync, GPU monitoring

## Quick Start

### WSL2 / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/seanGSISG/.dotfiles/main/bootstrap.sh | bash
```

### Windows 11

```powershell
irm https://raw.githubusercontent.com/seanGSISG/.dotfiles/main/bootstrap.ps1 | iex
```

That's it. The script clones the repo, installs everything, and deploys configs. It's idempotent — safe to re-run. It will skip anything already installed.

**WSL2/Linux:** You'll be prompted for your sudo password and age encryption key (from Bitwarden).  
**Windows:** You'll be prompted for your age encryption key (from Bitwarden). Winget may prompt for package agreements.

### What It Does (WSL2/Linux)

1. Configures WSL2 (`/etc/wsl.conf` with systemd)
2. Adds APT repos (GitHub CLI, PowerShell, Charm) and installs 34 system packages
3. Installs chezmoi and clones this repo
4. Installs binary tools (Starship, fzf, uv, bun, age)
5. Installs plugin managers (antidote for zsh, TPM for tmux)
6. Installs Python tools via uv and Node.js 24 LTS (official tarball → ~/.local/node)
7. Backs up existing dotfiles to `~/.dotfiles-backup/<timestamp>/`
8. Deploys all configs via `chezmoi apply`
9. Changes default shell to zsh

### What It Does (Windows)

1. Installs chezmoi via winget
2. Clones this repo to `~\.dotfiles`
3. Installs packages from `packages\winget-packages.txt` (PowerShell 7, Windows Terminal, Git, GitHub CLI, dev tools, etc.)
4. Auto-installs CaskaydiaCove Nerd Font for Windows Terminal (via chezmoi run_once script)
5. Backs up existing dotfiles to `~\.dotfiles-backup\<timestamp>\`
6. Deploys PowerShell configs, Windows Terminal settings, and cross-platform configs via `chezmoi apply`

### Post-Install Checklist

After bootstrap completes, it prints a checklist. Key items:

1. **Restart terminal** — Load new configurations
2. **Age key** — If skipped during setup, retrieve from Bitwarden, save to `~/.config/age/keys.txt` (Linux/WSL) or `~\.config\age\keys.txt` (Windows), then run `chezmoi apply`
3. **Tmux plugins** (WSL/Linux only) — Open tmux, press `prefix + I`
4. **SSH verify** — `ssh -T git@github.com`
5. **WSL restart** (WSL only) — `wsl.exe --shutdown` from PowerShell (enables systemd)
6. **PowerShell Modules** (Windows) — `Install-Module PSFzf -Scope CurrentUser`

## Secrets & Encryption

Secrets are stored in `~/.secrets.env`, encrypted in the repo as `encrypted_dot_secrets.env.age`. The age key (`~/.config/age/keys.txt`) lives in Bitwarden, never in git.

```bash
# Edit secrets (opens decrypted in $EDITOR)
chezmoi edit ~/.secrets.env

# Apply (re-encrypts)
chezmoi apply --verbose
```

On a new machine, retrieve the age key from Bitwarden and save to `~/.config/age/keys.txt` before running `chezmoi apply` to decrypt secrets.

## Multi-Machine Support

Chezmoi template variables control what deploys where:

| Variable | Detection | Effect |
|---|---|---|
| `is_dgx_spark` | `/etc/dgx-release` exists | Deploys CUDA env, model aliases, dgx.sh, cf-sync |
| `is_wsl` | `kernel.osrelease` contains "microsoft" | Deploys GNOME Keyring, dbus, WezTerm OSC 7 |

DGX-specific files are excluded via `.chezmoiignore` on non-DGX systems. WSL-specific files are excluded on non-WSL systems. General improvements (keybindings, modern CLI aliases, extract, atuin) deploy everywhere.

### First Apply on a New Machine

The `run_once_before_install-tools.sh` script auto-installs CLI tools (starship, zoxide, eza, bat, atuin) on first `chezmoi apply`. The `run_once_create-workspace-dirs.sh` script creates standard workspace directories (`~/projects`, `~/labs`, `~/tools`, `~/tmp`).

## Shell Configuration

Zsh is the primary shell with a modular config structure:

```
~/.config/zsh/
├── exports.zsh          # PATH, env vars, history, SSH stty guard
├── plugins.zsh          # antidote + completion system
├── tools.zsh            # node, fzf, zoxide, direnv, atuin, cargo
├── functions.zsh        # alias-help, mkcd, extract(), auto-ls
├── keybindings.zsh      # Ctrl/Alt+Arrow, Home/End, word deletion
├── dgx.zsh              # DGX Spark: CUDA, vLLM, HF env (conditional)
├── wsl.zsh              # WSL2: GNOME Keyring, dbus, WezTerm (conditional)
├── .zsh_plugins.txt     # antidote plugin list
└── aliases/
    ├── aliases-navigation.zsh   # j() workspace jumps, cd shortcuts
    ├── aliases-git.zsh
    ├── aliases-docker.zsh
    ├── aliases-dev.zsh
    ├── aliases-dgx.zsh         # DGX: model serving, GPU monitoring (conditional)
    ├── aliases-utilities.zsh    # lsd/eza/bat/dust/btop conditional replacements
    └── aliases-system.zsh
```

Load order: exports → plugins → tools → functions → aliases → dgx (conditional) → wsl (conditional) → secrets → keybindings → Starship.

`.zshrc` is a pure sourcer — it only sources these files. Run `halp` or `?` for categorized alias help.

Bash is a minimal fallback that sources the same alias files and shows a hint to use zsh.

## Directory Structure

```
~/.dotfiles/                       # chezmoi source (this repo)
├── bootstrap.sh                   # Idempotent installer script (WSL2/Linux)
├── bootstrap.ps1                  # Idempotent installer script (Windows 11)
├── verify.sh                      # Post-install environment validation
├── run_once_before_install-tools.sh.tmpl  # Auto-install CLI tools (Linux)
├── run_once_create-workspace-dirs.sh     # Create ~/projects, ~/labs, etc.
├── run_once_install-nerdfonts.ps1.tmpl   # Auto-install Nerd Font (Windows)
├── dot_bashrc.tmpl                # .bashrc template (DGX/WSL conditional)
├── dot_config/
│   ├── starship.toml              # Starship prompt (SSH hostname support)
│   ├── tmux/tmux.conf             # tmux config (XDG path)
│   ├── zsh/                       # Modular zsh config + aliases
│   └── powershell/                # PowerShell 7 config (Windows)
├── bin/executable_cf-sync         # Cloudflare tunnel sync (DGX only)
├── private_dot_dgxspark/          # DGX Spark utilities (DGX only)
├── Documents/PowerShell/          # PowerShell profile (Windows)
├── AppData/                       # Windows Terminal settings (Windows)
├── dot_ssh/                       # SSH keys (age-encrypted)
├── encrypted_dot_secrets.env.age  # Encrypted secrets
├── packages/
│   ├── apt-packages.txt           # System packages manifest (Linux)
│   ├── winget-packages.txt        # System packages manifest (Windows)
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

- [chezmoi](https://www.chezmoi.io/) | [age](https://github.com/FiloSottile/age) | [Starship](https://starship.rs/) | [antidote](https://getantidote.github.io/) | [Node.js](https://nodejs.org/)
