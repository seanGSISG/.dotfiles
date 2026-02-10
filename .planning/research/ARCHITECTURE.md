# Architecture Patterns: Dotfiles Repository

**Domain:** Dotfiles management for WSL2/Linux developer environment
**Researched:** 2026-02-10
**Confidence:** HIGH

## Recommended Architecture

A **symlink-based topic directory structure** with an **idempotent bootstrap script** and **modular shell configuration**.

```
~/.dotfiles/                           # Git repository root
├── bootstrap.sh                       # Main installer (idempotent)
├── install.conf.yaml                  # Optional: Dotbot config if using framework
├── README.md                          # Setup instructions
├── .gitignore                         # Ignore secrets, local overrides
│
├── zsh/                               # Topic: zsh configuration
│   ├── .zshrc                         # Main zsh config (loader)
│   ├── .zshenv                        # Environment variables
│   └── .zsh.d/                        # Modular config directory
│       ├── 00-exports.zsh             # Environment exports
│       ├── 05-paths.zsh               # PATH modifications
│       ├── 10-nvm.zsh                 # NVM setup
│       ├── 15-brew.zsh                # Homebrew setup
│       ├── 20-tools.zsh               # fzf, zoxide, etc.
│       ├── 30-aliases.zsh             # Aliases
│       ├── 40-functions.zsh           # Custom functions
│       └── 99-wsl.zsh                 # WSL-specific config
│
├── bash/                              # Topic: bash fallback
│   ├── .bashrc                        # Minimal bash config
│   └── .profile                       # Login shell setup
│
├── oh-my-zsh/                         # Topic: Oh My Zsh customization
│   └── custom/
│       ├── aliases.zsh                # Custom aliases for OMZ
│       ├── plugins/                   # Custom plugins directory
│       └── themes/                    # Custom themes if any
│
├── git/                               # Topic: git configuration
│   ├── .gitconfig                     # Main git config
│   └── .gitignore_global              # Global gitignore
│
├── tmux/                              # Topic: tmux configuration
│   └── .tmux.conf                     # Tmux config
│
├── packages/                          # Package lists for installers
│   ├── apt-packages.txt               # Debian/Ubuntu packages
│   ├── Brewfile                       # Homebrew bundle file
│   ├── uv-tools.txt                   # uv tool list
│   └── npm-global.txt                 # npm global packages
│
├── scripts/                           # Helper scripts
│   ├── install-brew.sh                # Homebrew installer
│   ├── install-omz.sh                 # Oh My Zsh installer
│   ├── install-packages.sh            # Package installer
│   ├── create-symlinks.sh             # Symlink creator
│   └── machine-detect.sh              # Platform detection
│
├── secrets/                           # Secret management
│   ├── .secrets.env.example           # Template for secrets
│   └── README.md                      # Instructions
│
└── local/                             # Machine-specific overrides
    ├── README.md                      # How to use local configs
    └── .gitignore                     # Ignore all local configs
```

## Component Boundaries

| Component | Responsibility | Communicates With | File Location |
|-----------|---------------|-------------------|---------------|
| **bootstrap.sh** | Orchestrates entire installation | All scripts/, creates symlinks | Root |
| **Modular .zshrc** | Loads all .zsh.d/ configs in order | .zsh.d/ modules | zsh/.zshrc |
| **.zsh.d/ modules** | Individual feature configs (NVM, brew, etc.) | Source by .zshrc | zsh/.zsh.d/*.zsh |
| **Package lists** | Declare tools to install | Read by install scripts | packages/*.txt |
| **Install scripts** | Install specific tool categories | Called by bootstrap.sh | scripts/install-*.sh |
| **Symlink script** | Create $HOME symlinks to dotfiles | All topic directories | scripts/create-symlinks.sh |
| **Machine detection** | Identify OS/platform for conditionals | All install scripts | scripts/machine-detect.sh |
| **Secrets template** | Provide example for .secrets.env | User creates real file | secrets/.secrets.env.example |
| **OMZ custom/** | Oh My Zsh extensions | Symlinked to ~/.oh-my-zsh/custom/ | oh-my-zsh/custom/ |

## Data Flow

### Installation Flow (First Run)

```
User runs: ./bootstrap.sh
    ↓
1. Machine detection (uname, platform checks)
    ↓
2. Backup existing dotfiles (~/.zshrc → ~/.zshrc.backup)
    ↓
3. Install dependencies
    ├── apt packages (apt-packages.txt)
    ├── Homebrew (install-brew.sh → Brewfile)
    ├── Oh My Zsh (install-omz.sh)
    ├── Zsh plugins (zsh-autosuggestions, zsh-syntax-highlighting)
    ├── Powerlevel10k theme
    ├── uv tools (uv-tools.txt)
    ├── NVM + Node (via NVM)
    └── Other tools (fzf, zoxide, tmux plugin manager, Claude Code)
    ↓
4. Create symlinks
    └── ~/.dotfiles/zsh/.zshrc → ~/.zshrc
    └── ~/.dotfiles/zsh/.zshenv → ~/.zshenv
    └── ~/.dotfiles/git/.gitconfig → ~/.gitconfig
    └── ~/.dotfiles/tmux/.tmux.conf → ~/.tmux.conf
    └── ~/.dotfiles/bash/.bashrc → ~/.bashrc
    └── ~/.dotfiles/bash/.profile → ~/.profile
    └── ~/.dotfiles/oh-my-zsh/custom/* → ~/.oh-my-zsh/custom/*
    ↓
5. Print post-install checklist
    └── Create ~/.secrets.env from template
    └── Run: gh auth login
    └── Set up SSH keys
    └── Open tmux and install plugins (prefix + I)
    └── Run: claude login
```

### Shell Loading Flow (Every Login)

```
Login → .zshenv (environment setup)
    ↓
Launch zsh → .zshrc (main loader)
    ↓
.zshrc sources .zsh.d/ in alphabetical order:
    ├── 00-exports.zsh (core environment variables)
    ├── 05-paths.zsh (PATH setup)
    ├── 10-nvm.zsh (NVM initialization)
    ├── 15-brew.zsh (Homebrew setup)
    ├── 20-tools.zsh (fzf, zoxide, etc.)
    ├── 30-aliases.zsh (command aliases)
    ├── 40-functions.zsh (shell functions)
    └── 99-wsl.zsh (WSL-specific configs if detected)
    ↓
Source ~/.secrets.env (if exists)
    ↓
Initialize Oh My Zsh (themes, plugins)
    ↓
Ready for user
```

### Update Flow (Subsequent Runs)

```
User runs: git pull && ./bootstrap.sh
    ↓
1. Detect existing installations (idempotency checks)
    ├── Skip if already installed
    └── Update if version changed
    ↓
2. Refresh symlinks (safe with -sfn flags)
    ↓
3. Install new packages (from updated lists)
    ↓
4. Print what changed
```

## Patterns to Follow

### Pattern 1: Topic-Based Directory Organization

**What:** Group related dotfiles in topic directories (zsh/, git/, tmux/) rather than flat structure.

**When:** Always — improves organization and enables selective stowing.

**Why:** Makes it easy to browse, maintain, and selectively deploy configs per machine.

**Example:**
```bash
# Good: Topic-based
~/.dotfiles/zsh/.zshrc
~/.dotfiles/git/.gitconfig
~/.dotfiles/tmux/.tmux.conf

# Avoid: Flat structure
~/.dotfiles/.zshrc
~/.dotfiles/.gitconfig
~/.dotfiles/.tmux.conf
```

### Pattern 2: Modular Shell Configuration

**What:** Split monolithic .zshrc into focused modules in .zsh.d/ directory.

**When:** Any shell config over ~50 lines.

**Why:** Prevents single-point-of-failure, easier to debug, cleaner git diffs.

**Example:**
```bash
# In .zshrc (loader only)
for config_file in $HOME/.zsh.d/*.zsh; do
  source "$config_file"
done

# Individual modules
# .zsh.d/10-nvm.zsh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# .zsh.d/20-tools.zsh
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
```

### Pattern 3: Idempotent Installation Checks

**What:** Check if tool/config already exists before installing.

**When:** Every installation step in bootstrap.sh.

**Why:** Makes script safe to re-run, enables updates without breaking.

**Example:**
```bash
# Check if Homebrew installed
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed, skipping."
fi

# Check if Oh My Zsh installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh already installed, skipping."
fi

# Check if file content exists before appending
if ! grep -qF "eval \"\$(brew shellenv)\"" "$HOME/.zshrc"; then
  echo 'eval "$(brew shellenv)"' >> "$HOME/.zshrc"
fi
```

### Pattern 4: Safe Symlink Creation

**What:** Use `ln -sfn` flags for safe, idempotent symlinks.

**When:** All symlink operations.

**Why:** `-s` creates symbolic link, `-f` removes existing targets, `-n` prevents nesting in directories.

**Example:**
```bash
# Safe symlink creation
ln -sfn "$HOME/.dotfiles/zsh/.zshrc" "$HOME/.zshrc"
ln -sfn "$HOME/.dotfiles/git/.gitconfig" "$HOME/.gitconfig"
ln -sfn "$HOME/.dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"

# Backup before symlinking (optional safety)
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"
fi
```

### Pattern 5: Platform Detection for Cross-Machine Portability

**What:** Detect OS/platform and conditionally load configs.

**When:** Any config that varies by platform (WSL vs Mac vs Linux).

**Why:** Enables single repo to work across multiple machines.

**Example:**
```bash
# In scripts/machine-detect.sh
detect_platform() {
  case "$(uname -s)" in
    Linux*)
      if grep -qi microsoft /proc/version; then
        echo "WSL"
      else
        echo "Linux"
      fi
      ;;
    Darwin*)
      echo "Mac"
      ;;
    *)
      echo "Unknown"
      ;;
  esac
}

# In .zsh.d/99-wsl.zsh
if [[ $(uname -r) =~ microsoft ]]; then
  # WSL-specific config
  export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
  # GNOME Keyring setup for WSL
  export $(gnome-keyring-daemon --start 2>/dev/null)
fi
```

### Pattern 6: Secrets Management with Template

**What:** Keep secrets in git-ignored `.secrets.env` with `.example` template.

**When:** Any sensitive data (API keys, tokens).

**Why:** Never commit secrets, but provide clear documentation of what's needed.

**Example:**
```bash
# In secrets/.secrets.env.example
# Copy this file to ~/.secrets.env and fill in your values
export GITHUB_PERSONAL_ACCESS_TOKEN="your_token_here"
export EXA_API_KEY="your_api_key_here"
export GREPTILE_API_KEY="your_api_key_here"

# In .zshrc (at end)
if [ -f "$HOME/.secrets.env" ]; then
  source "$HOME/.secrets.env"
fi

# In .gitignore
.secrets.env
```

### Pattern 7: Package List Management

**What:** Maintain declarative lists of packages to install.

**When:** Any tool installation beyond single binary.

**Why:** Version control your full tool stack, easier to review changes.

**Example:**
```bash
# packages/apt-packages.txt (one per line)
build-essential
curl
git
tmux
zsh
fzf
ripgrep
fd-find
bat

# packages/Brewfile (Homebrew bundle format)
brew "fzf"
brew "zoxide"
brew "gh"
brew "tmux"
brew "uv"

# In scripts/install-packages.sh
# Install apt packages
if [ -f "$DOTFILES/packages/apt-packages.txt" ]; then
  xargs sudo apt-get install -y < "$DOTFILES/packages/apt-packages.txt"
fi

# Install Homebrew packages
if [ -f "$DOTFILES/packages/Brewfile" ]; then
  brew bundle --file="$DOTFILES/packages/Brewfile"
fi
```

### Pattern 8: Oh My Zsh Custom Directory Integration

**What:** Symlink custom Oh My Zsh configs to `~/.oh-my-zsh/custom/`.

**When:** Using Oh My Zsh with custom aliases/plugins/themes.

**Why:** Keeps your customizations in dotfiles repo while respecting OMZ structure.

**Example:**
```bash
# Directory structure
~/.dotfiles/oh-my-zsh/custom/
└── aliases.zsh

# In create-symlinks.sh
ln -sfn "$HOME/.dotfiles/oh-my-zsh/custom/aliases.zsh" \
        "$HOME/.oh-my-zsh/custom/aliases.zsh"

# Oh My Zsh will automatically load ~/.oh-my-zsh/custom/*.zsh
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Hardcoded User Paths

**What:** Using `/home/vscode` instead of `$HOME` in configs.

**Why bad:** Breaks portability when username changes (vscode → adminuser).

**Instead:** Always use `$HOME`, `$USER`, or `~` expansion.

```bash
# Bad
export NVM_DIR="/home/vscode/.nvm"

# Good
export NVM_DIR="$HOME/.nvm"
```

### Anti-Pattern 2: Non-Idempotent Bootstrap

**What:** Installing without checking if already installed.

**Why bad:** Script fails on re-run, can't be used for updates.

**Instead:** Check existence before every installation step.

```bash
# Bad
apt-get install -y git

# Good
if ! command -v git &> /dev/null; then
  apt-get install -y git
fi
```

### Anti-Pattern 3: Monolithic .zshrc

**What:** Single 300+ line .zshrc with all config inline.

**Why bad:** Hard to debug, git diffs show entire file, single point of failure.

**Instead:** Use modular .zsh.d/ structure with focused files.

### Anti-Pattern 4: Secrets in Version Control

**What:** Committing API keys, tokens directly in shell configs.

**Why bad:** Security risk, can't share dotfiles publicly.

**Instead:** Use .secrets.env pattern with .gitignore.

### Anti-Pattern 5: No Backup Before Symlinking

**What:** Overwriting existing configs without backup.

**Why bad:** Data loss if user had important local configs.

**Instead:** Back up existing files before creating symlinks.

```bash
# Good pattern
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"
fi
```

### Anti-Pattern 6: Installing Tools in Random Order

**What:** Installing tools without considering dependencies.

**Why bad:** Later steps fail because dependencies not yet installed.

**Instead:** Install in dependency order:
1. System packages (apt)
2. Homebrew
3. Shell (Oh My Zsh)
4. Shell plugins
5. Language runtimes (NVM, uv)
6. Tools that depend on runtimes

### Anti-Pattern 7: Bare Git Repository for Beginners

**What:** Using `git init --bare` with special alias for dotfiles.

**Why bad:** Complex mental model, hard to debug, confusing for collaborators.

**Instead:** Use topic-based directory with symlinks — easier to understand and maintain.

## Scalability Considerations

| Concern | Single Machine | Multiple Machines (2-5) | Large Fleet (10+) |
|---------|---------------|------------------------|-------------------|
| **Symlink management** | Manual script | GNU Stow per topic | Ansible/Dotbot framework |
| **Secrets** | .secrets.env local | 1Password CLI / Bitwarden | HashiCorp Vault |
| **Machine-specific config** | if-statements in .zsh.d/ | local/ directory per host | Templates with variables |
| **Package sync** | Re-run bootstrap.sh | chezmoi update workflow | Configuration management (Chef/Puppet) |
| **Updates** | git pull + bootstrap | git pull + selective stow | Automated CI/CD deploys |

## File Dependency Order

What must exist before what (critical for bootstrap script ordering):

```
1. Git (to clone dotfiles repo)
   ↓
2. Curl (to download installers)
   ↓
3. System packages (apt-packages.txt)
   ↓
4. Homebrew (depends on curl)
   ↓
5. Zsh (shell itself)
   ↓
6. Oh My Zsh (depends on zsh, git, curl)
   ↓
7. Zsh plugins (depends on Oh My Zsh)
   ↓
8. Powerlevel10k (depends on Oh My Zsh)
   ↓
9. NVM (independent, but needed before Node)
   ↓
10. Node (depends on NVM)
    ↓
11. Other tools (fzf, zoxide, etc.) — mostly independent
    ↓
12. Symlinks (should be last to ensure all dependencies exist)
    ↓
13. Secrets file creation (manual post-install step)
```

## Suggested Build Order

When creating dotfiles repo from scratch, build in this order:

### Phase 1: Core Infrastructure (Day 1)
1. Create `.dotfiles/` directory structure
2. Write `.gitignore` (ignore .secrets.env, local/)
3. Create `secrets/.secrets.env.example` template
4. Write minimal `README.md` with setup instructions

### Phase 2: Shell Configuration (Day 1-2)
5. Create `zsh/.zshrc` as simple loader
6. Create `zsh/.zsh.d/00-exports.zsh` (core variables)
7. Create `zsh/.zsh.d/05-paths.zsh` (PATH setup)
8. Create `bash/.bashrc` (minimal fallback)
9. Create `bash/.profile` (login shell)

### Phase 3: Tool Configs (Day 2)
10. Create `git/.gitconfig`
11. Create `tmux/.tmux.conf`
12. Create `oh-my-zsh/custom/aliases.zsh` (migrate aliases)

### Phase 4: Package Lists (Day 2)
13. Generate `packages/apt-packages.txt` (from current system)
14. Generate `packages/Brewfile` (brew bundle dump)
15. Create `packages/uv-tools.txt`

### Phase 5: Helper Scripts (Day 3)
16. Write `scripts/machine-detect.sh`
17. Write `scripts/install-packages.sh`
18. Write `scripts/install-omz.sh`
19. Write `scripts/create-symlinks.sh`

### Phase 6: Bootstrap Orchestration (Day 3-4)
20. Write `bootstrap.sh` orchestrator (calls all helpers)
21. Test on current machine (should be idempotent)
22. Write post-install checklist

### Phase 7: Modular Zsh Expansion (Day 4)
23. Split remaining configs into `.zsh.d/` modules:
    - `10-nvm.zsh`
    - `15-brew.zsh`
    - `20-tools.zsh` (fzf, zoxide)
    - `30-aliases.zsh` (duplicate of OMZ custom if needed)
    - `40-functions.zsh`
    - `99-wsl.zsh` (platform-specific)

## Build Order Implications for Roadmap

**Early phases should focus on:**
- Creating directory structure (low risk, high clarity)
- Extracting secrets (security critical)
- Writing package lists (preserves current state)

**Middle phases should focus on:**
- Individual config files (git, tmux) — independent, low risk
- Shell config modularization — higher complexity, test thoroughly

**Late phases should focus on:**
- Bootstrap script — depends on everything else existing
- Testing on new machine — final validation

**Phases that need research flags:**
- Bootstrap error handling (how comprehensive to make it?)
- Oh My Zsh plugin installation (git clone vs oh-my-zsh installer?)
- Symlink strategy for Oh My Zsh custom/ (symlink directory vs individual files?)

## Alternative Architectures Considered

### 1. Bare Git Repository

**How it works:** Use `git init --bare ~/.dotfiles` with alias like `config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'`.

**Pros:**
- No symlinks needed
- Version control files at their actual locations
- Minimal setup once understood

**Cons:**
- Complex mental model for beginners
- Easy to accidentally track unwanted files
- Harder to collaborate (unique workflow)
- Can't easily have "per-topic" organization

**Why not recommended:** Too complex for this use case. Symlink approach is more maintainable.

### 2. Dotbot Framework

**How it works:** YAML-driven installation via `install.conf.yaml`, invoked by `./install` script.

**Pros:**
- Declarative configuration
- Built-in idempotency
- Plugin ecosystem
- Well-tested framework

**Cons:**
- Another dependency to learn
- Less transparent than bash scripts
- YAML can get verbose
- Requires Python

**Why not recommended:** For a 22-step installer, bash script is more transparent and flexible. Dotbot adds abstraction that's not needed here.

### 3. Chezmoi

**How it works:** Template-based dotfile manager with encryption, platform detection, and update workflow built-in.

**Pros:**
- Sophisticated cross-platform support
- Templating for machine-specific configs
- Encryption for secrets
- Automatic update workflow

**Cons:**
- Heavy framework (Go binary)
- Templating syntax to learn
- More abstraction than needed
- Overkill for single-user, WSL-focused setup

**Why not recommended:** Too feature-rich for this use case. Simple symlinks + .secrets.env is sufficient.

## Sources

### Directory Structure & Organization
- [How to Store Dotfiles - A Bare Git Repository | Atlassian Git Tutorial](https://www.atlassian.com/git/tutorials/dotfiles)
- [The Ultimate Guide to Mastering Dotfiles](https://www.daytona.io/dotfiles/ultimate-guide-to-dotfiles)
- [dotfiles - ArchWiki](https://wiki.archlinux.org/title/Dotfiles)
- [The best way to store your dotfiles: A bare Git repository **EXPLAINED** - Ackama](https://www.ackama.com/what-we-think/the-best-way-to-store-your-dotfiles-a-bare-git-repository-explained/)
- [GitHub does dotfiles - dotfiles.github.io](https://dotfiles.github.io/)
- [How to Manage Dotfiles With Git (Best Practices Explained)](https://www.control-escape.com/linux/dotfiles/)

### GNU Stow & Symlink Management
- [How I manage my dotfiles using GNU Stow](https://tamerlan.dev/how-i-manage-my-dotfiles-using-gnu-stow/)
- [Using GNU Stow to manage your dotfiles · GitHub](https://gist.github.com/andreibosco/cb8506780d0942a712fc)
- [Git, Symlinks, and GNU Stow: How To Manage Your Dotfiles | by Jack Smith | Medium](https://medium.com/@jacksmithxyz/git-symlinks-and-gnu-stow-how-to-manage-your-dotfiles-103c42cea485)
- [Using GNU Stow to Manage Symbolic Links for Your Dotfiles - System Crafters](https://systemcrafters.net/managing-your-dotfiles/using-gnu-stow/)
- [Stow - GNU Project - Free Software Foundation](https://www.gnu.org/software/stow/)

### Idempotent Bootstrap Scripts
- [GitHub - Xe0n0/dotfiles: Dot files with idempotent bootstrap script](https://github.com/Xe0n0/dotfiles)
- [Bootstrap repositories - dotfiles.github.io](https://dotfiles.github.io/bootstrap/)
- [GitHub - anishathalye/dotbot: A tool that bootstraps your dotfiles ⚡️](https://github.com/anishathalye/dotbot)
- [How to write idempotent Bash scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/)
- [GitHub - metaist/idempotent-bash: Make your bash scripts idempotent.](https://github.com/metaist/idempotent-bash)

### Modular Zsh Configuration
- [2 Step Defense in Depth for Dotfiles: Modularizing Your .zshrc - Carmelyne Thompson](https://carmelyne.com/modularizing-your-zshrc/)
- [GitHub - thoughtbot/dotfiles: A set of vim, zsh, git, and tmux configuration files.](https://github.com/thoughtbot/dotfiles)
- [How I Over-Engineered My Dotfiles](https://bananamafia.dev/post/dotfiles/)

### Cross-Platform & Machine-Specific Config
- [GitHub - fatso83/dotfiles: Cross-platform dotfiles shared by macOS and Linux (native and WSL2)](https://github.com/fatso83/dotfiles)
- [GitHub - StefanScherer/dotfiles: My dotfiles for Mac / Linux boxes and WSL](https://github.com/StefanScherer/dotfiles)
- [Cross-Platform Dotfiles – Calvin Bui](https://calvin.me/cross-platform-dotfiles/)
- [How I manage my dotfiles](https://mohundro.com/blog/2024-08-03-how-i-manage-my-dotfiles/)

### Package Management
- [Cross-Platform Dotfiles with Chezmoi, Nix, Brew, and Devpod · AlfonsoFortunato](https://alfonsofortunato.com/posts/dotfile/)
- [Dotfiles: automating macOS system configuration](https://kalis.me/dotfiles-automating-macos-system-configuration/)
- [General-purpose dotfiles utilities - dotfiles.github.io](https://dotfiles.github.io/utilities/)

### Sync & Update Workflows
- [GitHub - dotphiles/dotsync: Sync dotfiles between multiple machines from a git repo or push using rsync](https://github.com/dotphiles/dotsync)
- [Synchronizing my dotfiles](https://kevinjalbert.com/synchronizing-my-dotfiles/)

### Oh My Zsh Custom Directory
- [Customization](https://github.com/ohmyzsh/ohmyzsh/wiki/Customization)
- [How to install custom plugins and themes with Oh-My-ZSH](https://blog.larsbehrenberg.com/how-to-install-custom-plugins-and-themes-with-oh-my-zsh)
- [Best Oh My ZSH Plugins for 2026](https://www.bitdoze.com/best-oh-my-zsh-plugins/)
- [Customizing Your Terminal with Oh My Zsh Themes and Plugins](https://blog.openreplay.com/customizing-terminal-oh-my-zsh-themes-plugins/)
