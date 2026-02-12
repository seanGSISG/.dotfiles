adminuser@GSI-LPF4GWYG7:~$ curl -fsSL https://raw.githubusercontent.com/seanGSISG/.dotfiles/main/bootstrap.sh | bash

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           WSL2 Dev Environment Bootstrap                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝


▶ Logging to: /home/adminuser/.dotfiles-bootstrap-20260212_101811.log


═══════════════════════════════════════════════════════
  Checking Prerequisites
═══════════════════════════════════════════════════════

✓ curl available
✓ git available
✓ sudo available
✓ All prerequisites available

═══════════════════════════════════════════════════════
  WSL2 Configuration
═══════════════════════════════════════════════════════

⊘ WSL2 already configured with systemd (skipped)

═══════════════════════════════════════════════════════
  APT Repository Setup
═══════════════════════════════════════════════════════

⊘ GitHub CLI repository already configured (skipped)
⊘ PowerShell repository already configured or PowerShell already installed (skipped)
▶ Adding Charm repository (for glow)...
✓ Charm repository added
▶ Updating package cache...
✓ Package cache updated

═══════════════════════════════════════════════════════
  Chezmoi Installation
═══════════════════════════════════════════════════════

⊘ chezmoi already installed (skipped)
⊘ Dotfiles repo already exists (skipped)

═══════════════════════════════════════════════════════
  Installing System Packages
═══════════════════════════════════════════════════════

⊘ build-essential already installed (skipped)
⊘ ca-certificates already installed (skipped)
⊘ git already installed (skipped)
⊘ zsh already installed (skipped)
⊘ bash-completion already installed (skipped)
⊘ bat already installed (skipped)
⊘ eza already installed (skipped)
⊘ ripgrep already installed (skipped)
⊘ jq already installed (skipped)
⊘ tree already installed (skipped)
⊘ file already installed (skipped)
⊘ findutils already installed (skipped)
▶ Installing glow...
✓ glow installed
⊘ htop already installed (skipped)
⊘ zoxide already installed (skipped)
⊘ curl already installed (skipped)
⊘ wget already installed (skipped)
⊘ zip already installed (skipped)
⊘ unzip already installed (skipped)
⊘ python3 already installed (skipped)
⊘ python3-pip already installed (skipped)
⊘ python3.12 already installed (skipped)
⊘ python3.12-venv already installed (skipped)
⊘ gnome-keyring already installed (skipped)
⊘ gnupg2 already installed (skipped)
⊘ libsecret-1-0 already installed (skipped)
⊘ libsecret-1-dev already installed (skipped)
⊘ libsecret-tools already installed (skipped)
⊘ libfuse2t64 already installed (skipped)
⊘ fuse already installed (skipped)
⊘ libattr1 already installed (skipped)
⊘ wslu already installed (skipped)
⊘ powershell already installed (skipped)
⊘ gh already installed (skipped)

✓ APT packages: 1 installed, 33 skipped

═══════════════════════════════════════════════════════
  Binary Tools
═══════════════════════════════════════════════════════

▶ Installing Starship...
curl: (23) Failure writing output to destination
✗ Starship installation failed
▶ Installing fnm...
✓ fnm installed
▶ Installing fzf...
⊘ fzf directory already exists (skipped)
⊘ uv already installed (skipped)
▶ Installing bun...
✓ bun installed
⊘ age already installed (skipped)

═══════════════════════════════════════════════════════
  Plugin Managers
═══════════════════════════════════════════════════════

⊘ antidote already installed (skipped)
▶ TPM (Tmux Plugin Manager) will be installed via chezmoi .chezmoiexternal.toml

═══════════════════════════════════════════════════════
  Python Tools
═══════════════════════════════════════════════════════

▶ Installing basedpyright...
✓ basedpyright installed
▶ Installing detect-secrets...
✓ detect-secrets installed
▶ Installing just...
✓ just installed
▶ Installing pre-commit...
✓ pre-commit installed
▶ Installing virtualenv...
✓ virtualenv installed

✓ Python tools: 5 installed, 0 skipped

═══════════════════════════════════════════════════════
  Node.js & JavaScript Tools
═══════════════════════════════════════════════════════

✗ fnm not found - Node.js tools installation skipped
✗ Node.js Tools failed
⊘ Claude Code already installed (skipped)

═══════════════════════════════════════════════════════
  Dotfile Backup
═══════════════════════════════════════════════════════

▶ Backing up existing dotfiles to /home/adminuser/.dotfiles-backup/20260212_101828...
▶ Backed up: .zshrc
▶ Backed up: .bashrc
▶ Backed up: .profile
▶ Backed up: .gitconfig
▶ Backed up: .config/zsh
▶ Backed up: .config/tmux
✓ Dotfiles backed up to /home/adminuser/.dotfiles-backup/20260212_101828

═══════════════════════════════════════════════════════
  Age Encryption Key
═══════════════════════════════════════════════════════

⊘ Age key already exists (skipped)

═══════════════════════════════════════════════════════
  Chezmoi Apply
═══════════════════════════════════════════════════════

▶ Applying chezmoi configurations...
✓ chezmoi configurations applied

═══════════════════════════════════════════════════════
  GitHub Authentication
═══════════════════════════════════════════════════════

k✗ GitHub auth failed
▶ Authenticate manually: gh auth login

═══════════════════════════════════════════════════════
  Default Shell
═══════════════════════════════════════════════════════

▶ Changing default shell to zsh...
✓ Default shell changed to zsh (takes effect on next login)

═══════════════════════════════════════════════════════
  Bootstrap Complete!
═══════════════════════════════════════════════════════

Installed:
  ✓ glow
  ✓ fnm
  ✓ bun
  ✓ basedpyright
  ✓ detect-secrets
  ✓ just
  ✓ pre-commit
  ✓ virtualenv
  ✓ Dotfile backup
  ✓ chezmoi apply
  ✓ zsh as default shell

Skipped (already installed):
  ⊘ WSL2 configuration
  ⊘ chezmoi
  ⊘ dotfiles clone
  ⊘ build-essential
  ⊘ ca-certificates
  ⊘ git
  ⊘ zsh
  ⊘ bash-completion
  ⊘ bat
  ⊘ eza
  ⊘ ripgrep
  ⊘ jq
  ⊘ tree
  ⊘ file
  ⊘ findutils
  ⊘ htop
  ⊘ zoxide
  ⊘ curl
  ⊘ wget
  ⊘ zip
  ⊘ unzip
  ⊘ python3
  ⊘ python3-pip
  ⊘ python3.12
  ⊘ python3.12-venv
  ⊘ gnome-keyring
  ⊘ gnupg2
  ⊘ libsecret-1-0
  ⊘ libsecret-1-dev
  ⊘ libsecret-tools
  ⊘ libfuse2t64
  ⊘ fuse
  ⊘ libattr1
  ⊘ wslu
  ⊘ powershell
  ⊘ gh
  ⊘ fzf
  ⊘ uv
  ⊘ age
  ⊘ antidote
  ⊘ Claude Code
  ⊘ Age key

Failed:
  ✗ Starship
  ✗ Node.js tools (fnm required)
  ✗ Node.js Tools
  ✗ GitHub auth

Post-Install Checklist:

  1. Age Encryption Key
     If skipped during setup, retrieve from Bitwarden and save to:
     ~/.config/age/keys.txt
     Then run: chezmoi apply

  2. Tmux Plugins
     Open tmux and press: prefix + I (Install plugins)

  3. Claude Code Authentication
     Run: claude login

  4. SSH Verification
     Test SSH keys: ssh -T git@github.com

  5. WSL Restart
     From PowerShell, run: wsl.exe --shutdown
     Then restart WSL to enable systemd

Log file: /home/adminuser/.dotfiles-bootstrap-20260212_101811.log


═══════════════════════════════════════════════════════
  Some steps failed. See above for details.
═══════════════════════════════════════════════════════

Re-run this script to retry failed steps.
adminuser@GSI-LPF4GWYG7:~$