
~
❯ curl -fsSL https://raw.githubusercontent.com/seanGSISG/.dotfiles/main/bootstrap.sh | bash

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           WSL2 Dev Environment Bootstrap                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝


▶ Logging to: /home/adminuser/.dotfiles-bootstrap-20260212_115703.log


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
⊘ Charm repository already configured (skipped)
▶ Updating package cache...
[sudo] password for adminuser:
✓ Package cache updated

═══════════════════════════════════════════════════════
  Chezmoi Installation
═══════════════════════════════════════════════════════

⊘ chezmoi already installed (skipped)
▶ Updating dotfiles repo...
✓ Dotfiles repo updated

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
⊘ glow already installed (skipped)
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

✓ APT packages: 0 installed, 34 skipped

═══════════════════════════════════════════════════════
  Binary Tools
═══════════════════════════════════════════════════════

⊘ Starship already installed (skipped)
⊘ fnm already installed (skipped)
⊘ fzf already installed (skipped)
⊘ uv already installed (skipped)
⊘ bun already installed (skipped)
⊘ age already installed (skipped)

═══════════════════════════════════════════════════════
  Plugin Managers
═══════════════════════════════════════════════════════

⊘ antidote already installed (skipped)
⊘ TPM already installed (skipped)

═══════════════════════════════════════════════════════
  Python Tools
═══════════════════════════════════════════════════════

⊘ basedpyright already installed (skipped)
⊘ detect-secrets already installed (skipped)
⊘ just already installed (skipped)
⊘ pre-commit already installed (skipped)
⊘ virtualenv already installed (skipped)

✓ Python tools: 0 installed, 5 skipped

═══════════════════════════════════════════════════════
  Node.js & JavaScript Tools
═══════════════════════════════════════════════════════

⊘ Node.js 22 (LTS) already installed (skipped)
⊘ Claude Code already installed (skipped)

═══════════════════════════════════════════════════════
  Dotfile Backup
═══════════════════════════════════════════════════════

▶ Backing up existing dotfiles to /home/adminuser/.dotfiles-backup/20260212_115709...
▶ Backed up: .zshrc
▶ Backed up: .bashrc
▶ Backed up: .profile
▶ Backed up: .gitconfig
▶ Backed up: .config/zsh
▶ Backed up: .config/tmux
✓ Dotfiles backed up to /home/adminuser/.dotfiles-backup/20260212_115709

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
  Default Shell
═══════════════════════════════════════════════════════

⊘ Shell already set to zsh (skipped)

═══════════════════════════════════════════════════════
  Bootstrap Complete!
═══════════════════════════════════════════════════════

Installed:
  ✓ dotfiles update
  ✓ Dotfile backup
  ✓ chezmoi apply

Skipped (already installed):
  ⊘ WSL2 configuration
  ⊘ chezmoi
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
  ⊘ glow
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
  ⊘ Starship
  ⊘ fnm
  ⊘ fzf
  ⊘ uv
  ⊘ bun
  ⊘ age
  ⊘ antidote
  ⊘ TPM
  ⊘ basedpyright
  ⊘ detect-secrets
  ⊘ just
  ⊘ pre-commit
  ⊘ virtualenv
  ⊘ Node.js 22
  ⊘ Claude Code
  ⊘ Age key
  ⊘ Shell change

Post-Install Checklist:

  1. Age Encryption Key
     If skipped during setup, retrieve from Bitwarden and save to:   <--- remove this, the bootstrap now prompts for the password so this will never be needed
     ~/.config/age/keys.txt
     Then run: chezmoi apply

  2. Tmux Plugins													<--- How do i open tmux?  what is the prefix key combo?
     Open tmux and press: prefix + I (Install plugins)

  3. Claude Code Authentication
     Run: claude login

  4. SSH Verification
     Test SSH keys: ssh -T git@github.com  							<-----  what does this do?  why does it fail (see below)

  5. WSL Restart
     From PowerShell, run: wsl.exe --shutdown
     Then restart WSL to enable systemd

Log file: /home/adminuser/.dotfiles-bootstrap-20260212_115703.log


Starting new zsh shell...

~ took 7s
❯ ssh -T git@github.com
git@github.com: Permission denied (publickey).

~
❯


We shoul add in the post-install checklist a copy paste command to run the verify.sh script