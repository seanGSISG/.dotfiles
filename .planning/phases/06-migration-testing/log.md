adminuser@GSI-LPF4GWYG7:~$ curl -fsSL https://raw.githubusercontent.com/seanGSISG/.dotfiles/main/bootstrap.sh | bash

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           WSL2 Dev Environment Bootstrap                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝


▶ Logging to: /home/adminuser/.dotfiles-bootstrap-20260212_100120.log


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
▶ Updating package cache...
[sudo] password for adminuser:
✓ Package cache updated

═══════════════════════════════════════════════════════
  Chezmoi Installation
═══════════════════════════════════════════════════════

▶ Installing chezmoi...
✓ chezmoi installed
▶ Cloning dotfiles repo from GitHub...
✓ Dotfiles repo cloned

═══════════════════════════════════════════════════════
  Installing System Packages
═══════════════════════════════════════════════════════

▶ Installing build-essential...
✓ build-essential installed
⊘ ca-certificates already installed (skipped)
⊘ git already installed (skipped)
▶ Installing zsh...
✓ zsh installed
⊘ bash-completion already installed (skipped)
▶ Installing bat...
✓ bat installed
▶ Installing eza...
✓ eza installed
▶ Installing ripgrep...
✓ ripgrep installed
▶ Installing jq...
✓ jq installed
▶ Installing tree...
✓ tree installed
⊘ file already installed (skipped)
⊘ findutils already installed (skipped)
▶ Installing glow...
✗ glow installation failed
▶ Installing htop...
✓ htop installed
▶ Installing zoxide...
✓ zoxide installed
⊘ curl already installed (skipped)
⊘ wget already installed (skipped)
▶ Installing zip...
✓ zip installed
⊘ unzip already installed (skipped)
⊘ python3 already installed (skipped)
▶ Installing python3-pip...
✓ python3-pip installed
⊘ python3.12 already installed (skipped)
▶ Installing python3.12-venv...
✓ python3.12-venv installed
▶ Installing gnome-keyring...
✓ gnome-keyring installed
▶ Installing gnupg2...
✓ gnupg2 installed
⊘ libsecret-1-0 already installed (skipped)
▶ Installing libsecret-1-dev...
✓ libsecret-1-dev installed
▶ Installing libsecret-tools...
✓ libsecret-tools installed
▶ Installing libfuse2t64...
✓ libfuse2t64 installed
▶ Installing fuse...
✓ fuse installed
⊘ libattr1 already installed (skipped)
▶ Installing wslu...
✓ wslu installed
▶ Installing powershell...
✓ powershell installed
▶ Installing gh...
✓ gh installed

✓ APT packages: 21 installed, 12 skipped

═══════════════════════════════════════════════════════
  Binary Tools
═══════════════════════════════════════════════════════

▶ Installing Starship...
✗ Starship installation failed
▶ Installing fnm...
✓ fnm installed
▶ Installing fzf...
✓ fzf installed
⊘ uv already installed (skipped)
▶ Installing bun...
✓ bun installed
⊘ age already installed (skipped)

═══════════════════════════════════════════════════════
  Plugin Managers
═══════════════════════════════════════════════════════

▶ Installing antidote...
✓ antidote installed
▶ TPM (Tmux Plugin Manager) will be installed via chezmoi .chezmoiexternal.toml

═══════════════════════════════════════════════════════
  Python Tools
═══════════════════════════════════════════════════════

▶ Installing basedpyright # Python type checker (actively maintained Pyright fork)...
✗ basedpyright # Python type checker (actively maintained Pyright fork) installation failed
▶ Installing detect-secrets # Pre-commit hook for secret scanning...
✗ detect-secrets # Pre-commit hook for secret scanning installation failed
▶ Installing just # Command runner (Makefile alternative, Rust-based)...
✗ just # Command runner (Makefile alternative, Rust-based) installation failed
▶ Installing pre-commit # Git hook framework for code quality...
✗ pre-commit # Git hook framework for code quality installation failed
▶ Installing virtualenv # Virtual environment creation (used by pre-commit internally)...
✗ virtualenv # Virtual environment creation (used by pre-commit internally) installation failed

✓ Python tools: 0 installed, 0 skipped

═══════════════════════════════════════════════════════
  Node.js & JavaScript Tools
═══════════════════════════════════════════════════════

✗ fnm not found - Node.js tools installation skipped
✗ Node.js Tools failed
⊘ Claude Code already installed (skipped)

═══════════════════════════════════════════════════════
  Dotfile Backup
═══════════════════════════════════════════════════════

▶ Backing up existing dotfiles to /home/adminuser/.dotfiles-backup/20260212_100249...
▶ Backed up: .bashrc
▶ Backed up: .profile
✓ Dotfiles backed up to /home/adminuser/.dotfiles-backup/20260212_100249

═══════════════════════════════════════════════════════
  Age Encryption Key
═══════════════════════════════════════════════════════


Age encryption key is required to decrypt secrets and SSH keys.
Your age key is stored in Bitwarden (search: 'age encryption key')

Paste your age secret key (starts with AGE-SECRET-KEY-1...)
or press Enter to skip:
AGE-SECRET-KEY-10Y0VRTAYFJ59TXRNEDMQTGWCWGYHRHU95WPKP0S5QF9U3LTH2XNS9YEN6M
▶ Saving age key to ~/.config/age/keys.txt...
✓ Age encryption key saved

═══════════════════════════════════════════════════════
  Chezmoi Apply
═══════════════════════════════════════════════════════

▶ Applying chezmoi configurations...
✓ chezmoi configurations applied

═══════════════════════════════════════════════════════
  GitHub Authentication
═══════════════════════════════════════════════════════

✗ GitHub auth failed
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
  ✓ chezmoi
  ✓ dotfiles clone
  ✓ build-essential
  ✓ zsh
  ✓ bat
  ✓ eza
  ✓ ripgrep
  ✓ jq
  ✓ tree
  ✓ htop
  ✓ zoxide
  ✓ zip
  ✓ python3-pip
  ✓ python3.12-venv
  ✓ gnome-keyring
  ✓ gnupg2
  ✓ libsecret-1-dev
  ✓ libsecret-tools
  ✓ libfuse2t64
  ✓ fuse
  ✓ wslu
  ✓ powershell
  ✓ gh
  ✓ fnm
  ✓ fzf
  ✓ bun
  ✓ antidote
  ✓ Dotfile backup
  ✓ Age key
  ✓ chezmoi apply
  ✓ zsh as default shell

Skipped (already installed):
  ⊘ WSL2 configuration
  ⊘ ca-certificates
  ⊘ git
  ⊘ bash-completion
  ⊘ file
  ⊘ findutils
  ⊘ curl
  ⊘ wget
  ⊘ unzip
  ⊘ python3
  ⊘ python3.12
  ⊘ libsecret-1-0
  ⊘ libattr1
  ⊘ uv
  ⊘ age
  ⊘ Claude Code

Failed:
  ✗ apt package: glow
  ✗ Starship
  ✗ Python tool: basedpyright # Python type checker (actively maintained Pyright fork)
  ✗ Python tool: detect-secrets # Pre-commit hook for secret scanning
  ✗ Python tool: just # Command runner (Makefile alternative, Rust-based)
  ✗ Python tool: pre-commit # Git hook framework for code quality
  ✗ Python tool: virtualenv # Virtual environment creation (used by pre-commit internally)
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

Log file: /home/adminuser/.dotfiles-bootstrap-20260212_100120.log


═══════════════════════════════════════════════════════
  Some steps failed. See above for details.
═══════════════════════════════════════════════════════

Re-run this script to retry failed steps.
adminuser@GSI-LPF4GWYG7:~$