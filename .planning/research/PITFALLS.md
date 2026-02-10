# Domain Pitfalls: Dotfiles & Shell Migration

**Domain:** Dotfiles management and bash-to-zsh migration on WSL2
**Researched:** 2026-02-10
**Confidence:** HIGH (verified with multiple authoritative sources and community consensus)

---

## Critical Pitfalls

Mistakes that cause data loss, system breakage, or major rewrites.

### Pitfall 1: Clobbering Existing Configuration Files

**What goes wrong:** During initial dotfile checkout or symlink creation, existing configuration files in `$HOME` get overwritten without backup, causing permanent data loss of system-specific customizations.

**Why it happens:** Git checkout or symlink scripts don't check for existing files. When migrating a 308-line aliases file, you're particularly vulnerable to losing existing `.zshrc`, `.bashrc`, or other shell configs.

**Consequences:**
- Permanent loss of existing configurations
- Loss of machine-specific environment variables
- WSL2-specific tweaks get destroyed
- No recovery path if migration fails

**Prevention:**
```bash
# BEFORE any checkout or symlink operation:
# 1. Create timestamped backup directory
backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"

# 2. Backup ALL existing dotfiles
for file in .zshrc .bashrc .bash_profile .profile .zshenv .aliases; do
    if [ -f "$HOME/$file" ]; then
        cp "$HOME/$file" "$backup_dir/"
        echo "Backed up: $file"
    fi
done

# 3. With GNU Stow, leverage built-in safety
# Stow FAILS if file already exists - this is GOOD
# Don't use --override or --adopt on first run
stow --no-folding dotfiles  # Fails safely on conflict

# 4. With bare Git repo method
# Identify conflicts BEFORE checkout
git checkout 2>&1 | grep -E "error: The following untracked working tree files" | \
    awk '{print $NF}' | while read file; do
    mkdir -p "$backup_dir/$(dirname "$file")"
    mv "$HOME/$file" "$backup_dir/$file"
done
```

**Detection:**
- Pre-flight check: Run `ls -la ~/.*rc ~/.*profile` to see what exists
- Test in VM or container first
- Check for "would be overwritten by checkout" Git errors

**Phase mapping:** Phase 1 (Bootstrap) must include backup strategy before any file operations.

---

### Pitfall 2: Secrets Committed to Git History

**What goes wrong:** API keys, tokens, passwords, or SSH keys embedded in dotfiles get committed to Git and pushed to public repositories. Even after removal, they remain in Git history forever.

**Why it happens:**
- Inline secrets in shell configs (e.g., `export AWS_KEY="AKIAIOSFODNN7EXAMPLE"`)
- Copying entire `.ssh/` directory
- Including `.env` files with credentials
- Not using `.gitignore` properly

**Consequences:**
- Permanent secret exposure (rotating is only mitigation)
- Security breach if tokens are valid
- Compliance violations
- Secrets remain in Git history even after "removal"

**Prevention:**
```bash
# 1. BEFORE initial commit - set up .gitignore
cat >> .gitignore <<'EOF'
# Secrets - NEVER commit these
.env
.env.*
*_secrets
*_credentials
*.pem
*.key
*.p12
*.pfx
.ssh/id_*
.ssh/known_hosts
.aws/credentials
.docker/config.json

# WSL2 specific
.wsl*
EOF

# 2. Install git-secrets globally (AWS Labs tool)
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
sudo make install
cd .. && rm -rf git-secrets

# Configure globally for all repos
git secrets --register-aws --global
git secrets --install ~/.git-templates/git-secrets
git config --global init.templateDir ~/.git-templates/git-secrets

# 3. Use pre-commit framework (better - more tools)
pip install pre-commit

# Create .pre-commit-config.yaml in dotfiles repo
cat > .pre-commit-config.yaml <<'EOF'
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']

  - repo: https://github.com/zricethezav/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
EOF

pre-commit install

# 4. Externalize secrets to files NOT in Git
# In .zshrc:
if [ -f "$HOME/.secrets" ]; then
    source "$HOME/.secrets"
fi

# Then .secrets contains:
# export API_KEY="actual-key-here"
# This file is gitignored and must be manually copied per machine
```

**Detection:**
- Run `git secrets --scan` on existing repo
- Use `detect-secrets scan` to find existing secrets
- Check with `git log -S "password" -p` to search history
- Review `.gitignore` before first commit

**If already committed:**
```bash
# History is poisoned - must rewrite (DESTRUCTIVE)
git filter-repo --path-match "path/to/secret/file" --invert-paths
# Then rotate ALL exposed secrets immediately
```

**Phase mapping:**
- Phase 1: Set up git-secrets BEFORE any commits
- Phase 2: Secret extraction from existing 308-line aliases file
- All phases: Never skip pre-commit hooks

---

### Pitfall 3: Non-Idempotent Bootstrap Script

**What goes wrong:** Bootstrap script fails on second run, or creates duplicate PATH entries, double-sources files, or installs packages multiple times, breaking the environment or causing slowdowns.

**Why it happens:**
- Using `>>` (append) instead of checking if entry exists
- Running `apt install` without checking if installed
- Symlinking without checking for existing links
- No guard clauses for repeat execution

**Consequences:**
- `$PATH` pollution with duplicate entries (causes wrong binary execution)
- Shell startup slows down exponentially (sourcing same file 10+ times)
- Package manager conflicts or errors
- Can't use bootstrap to "repair" broken state

**Prevention:**
```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# IDEMPOTENT PATTERN: Check before action

# 1. IDEMPOTENT: Add to PATH
add_to_path() {
    local new_path="$1"
    # Only add if not already present
    if [[ ":$PATH:" != *":$new_path:"* ]]; then
        export PATH="$new_path:$PATH"
        echo "Added $new_path to PATH"
    fi
}

# 2. IDEMPOTENT: Append to file (like .zshrc)
append_if_missing() {
    local file="$1"
    local line="$2"
    local marker="$3"  # Unique marker to check

    if ! grep -qF "$marker" "$file" 2>/dev/null; then
        echo "$line" >> "$file"
        echo "Added to $file: $marker"
    else
        echo "Already present in $file: $marker"
    fi
}

# Usage:
append_if_missing "$HOME/.zshrc" \
    "source ~/.aliases" \
    "source ~/.aliases"

# 3. IDEMPOTENT: Install package
install_if_missing() {
    local package="$1"
    if ! dpkg -l | grep -q "^ii  $package "; then
        sudo apt-get install -y "$package"
        echo "Installed: $package"
    else
        echo "Already installed: $package"
    fi
}

# 4. IDEMPOTENT: Create symlink
create_symlink() {
    local source="$1"
    local target="$2"

    if [ -L "$target" ]; then
        # Is symlink - check if points to correct location
        if [ "$(readlink "$target")" = "$source" ]; then
            echo "Symlink already correct: $target -> $source"
            return 0
        else
            echo "Symlink exists but wrong target, fixing..."
            rm "$target"
        fi
    elif [ -e "$target" ]; then
        echo "ERROR: $target exists but is not a symlink"
        return 1
    fi

    ln -s "$source" "$target"
    echo "Created symlink: $target -> $source"
}

# 5. IDEMPOTENT: Oh My Zsh installation
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh already installed"
fi

# 6. TEST IDEMPOTENCY: Run bootstrap twice
# ./bootstrap.sh
# ./bootstrap.sh  # Should be safe, no errors, no duplicates
```

**Detection:**
- Run bootstrap script twice in test environment
- Check `echo $PATH | tr ':' '\n'` for duplicates
- Look for exponential startup time on repeated runs
- Check for error messages on second run

**Phase mapping:**
- Phase 1: Bootstrap script must be idempotent from day one
- Phase 3+: Any additions to bootstrap must maintain idempotency

---

### Pitfall 4: Bash-to-Zsh Array Indexing Trap

**What goes wrong:** Scripts or aliases using array indexing break silently or return wrong elements because Bash arrays start at index 0, Zsh arrays start at index 1.

**Why it happens:** Direct copy-paste of Bash array logic into Zsh environment without adjusting for different indexing conventions.

**Consequences:**
- Off-by-one errors in scripts
- Silent failures (wrong array element accessed)
- Complex aliases in 308-line file may break
- Function logic produces unexpected results

**Prevention:**
```bash
# BASH BEHAVIOR (0-indexed):
arr=(first second third)
echo ${arr[0]}  # "first"
echo ${arr[1]}  # "second"

# ZSH BEHAVIOR (1-indexed):
arr=(first second third)
echo ${arr[1]}  # "first"  <-- DIFFERENT!
echo ${arr[2]}  # "second"

# SOLUTION 1: Use @ or * for whole array (works in both)
for item in "${arr[@]}"; do
    echo "$item"  # Works identically in both shells
done

# SOLUTION 2: Emulate sh for specific scripts
#!/usr/bin/env zsh
emulate sh  # Makes zsh behave like bash for compatibility

# SOLUTION 3: Use parameter expansion instead of indexing
first=${arr[1]}   # zsh-style
first=${arr[@]:0:1}  # Works in both (though awkward)

# SOLUTION 4: Set KSH_ARRAYS option for 0-indexing
# In .zshrc:
setopt KSH_ARRAYS  # Makes zsh use 0-indexing like bash
# BUT: This breaks zsh plugins expecting 1-indexing!

# BEST PRACTICE: Avoid numeric indexing, use iteration
```

**Detection:**
- Search aliases file for: `\[\d+\]` (array indexing)
- Test each alias after migration
- Look for `${var[0]}` patterns in scripts

**Phase mapping:**
- Phase 2: Audit all 308 aliases for array usage BEFORE migration
- Include test suite for critical aliases

---

## Moderate Pitfalls

Mistakes that cause delays, annoyance, or technical debt.

### Pitfall 5: PATH Ordering Catastrophes

**What goes wrong:** Wrong binary gets executed because PATH search order is incorrect. System commands shadowed by user scripts, or vice versa.

**Why it happens:**
- Prepending vs appending confusion
- Multiple shell config files all modifying PATH
- WSL2 Windows PATH mixed with Linux PATH
- NVM, Homebrew, pyenv all fighting for precedence

**Consequences:**
- `python` runs wrong version
- `node` not found even though installed
- Security risk: malicious `ls` in current directory executed first
- Debug nightmare: "works for me" but not in cron/scripts

**Prevention:**
```bash
# PRINCIPLE: Directories are searched LEFT to RIGHT

# BAD: Current directory first (SECURITY RISK)
export PATH=".:$PATH"  # NEVER DO THIS
# Risk: ./ls could shadow /bin/ls

# GOOD: User bins first, then system
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin"

# PRIORITY ORDER (prepend = higher priority):
# 1. User-specific binaries (override everything)
export PATH="$HOME/.local/bin:$PATH"

# 2. Version managers (need to intercept before system)
# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 3. Language-specific (pyenv, rbenv)
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"

# 4. System comes last
# Already in $PATH

# WSL2 SPECIFIC: Windows PATH pollution
# In /etc/wsl.conf:
[interop]
appendWindowsPath = false  # Prevents Windows PATH contamination

# Then manually add needed Windows tools in .zshrc:
export PATH="$PATH:/mnt/c/Windows/System32"  # Append only what you need

# DEBUGGING PATH ISSUES:
# Show PATH with one entry per line
echo $PATH | tr ':' '\n' | nl

# Find which binary will execute
which -a python  # Shows ALL matches in PATH order
type python      # Shows what will actually execute
```

**Detection:**
- Run `which -a <command>` to see all matches
- Check `echo $PATH | tr ':' '\n' | sort | uniq -d` for duplicates
- Test in clean shell: `env -i HOME=$HOME zsh -l`

**Phase mapping:**
- Phase 2: Consolidate PATH logic into single location (.zshenv recommended)
- Document priority order in comments

---

### Pitfall 6: Oh My Zsh Startup Performance Collapse

**What goes wrong:** Shell startup time balloons from <1s to 5-10+ seconds, making terminal usage painful.

**Why it happens:**
- Too many plugins enabled (each adds startup time)
- NVM sourced synchronously (300-500ms+ hit)
- Compinit runs on every shell (should be cached)
- Theme re-renders Git status for every prompt

**Consequences:**
- Developer frustration
- Workflow interruption
- Temptation to remove OMZ entirely
- Productivity loss

**Prevention:**
```bash
# MEASURE FIRST: Add to top of .zshrc
zmodload zsh/zprof

# ... rest of config ...

# At bottom of .zshrc
zprof  # Shows timing breakdown

# 1. LAZY LOAD NVM (biggest win - 70x faster!)
# DON'T do this:
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# DO this instead:
export NVM_DIR="$HOME/.nvm"
# Lazy load nvm
nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm "$@"
}

# Or use zsh-nvm plugin with lazy load:
# In .zshrc before OMZ:
export NVM_LAZY_LOAD=true

# 2. OPTIMIZE COMPINIT (cache completion)
# In .zshrc BEFORE sourcing oh-my-zsh.sh:
autoload -Uz compinit
# Only check once per day
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# 3. MINIMIZE PLUGINS (each adds cost)
# BAD:
plugins=(
    git docker kubectl helm terraform aws gcloud azure
    python pip poetry virtualenv pyenv
    node npm yarn nvm
    rust cargo
    # ... 20 more plugins
)

# GOOD: Only what you actually use daily
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# 4. DISABLE AUTO-UPDATE CHECK
# In .zshrc before sourcing oh-my-zsh:
zstyle ':omz:update' mode disabled

# 5. USE OPTIMIZED THEME
# Powerlevel10k is faster than Powerlevel9k
ZSH_THEME="powerlevel10k/powerlevel10k"
# Run p10k configure for instant prompt

# 6. ENABLE INSTANT PROMPT (Powerlevel10k feature)
# Should be at TOP of .zshrc:
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# TARGET: Startup time < 1 second
# Measure with: time zsh -i -c exit
```

**Detection:**
- Run `time zsh -i -c exit` (should be <1s)
- Add `zprof` to .zshrc to profile
- Check plugin count in .zshrc

**Phase mapping:**
- Phase 3: Performance optimization after basic setup works
- Include in bootstrap: instant prompt setup

---

### Pitfall 7: WSL2 Windows PATH Interop Chaos

**What goes wrong:** Linux commands find Windows executables instead of Linux versions, or vice versa. Environment variables from Windows pollute Linux shell. `python` runs Windows Python instead of WSL Python.

**Why it happens:**
- WSL2 appends Windows PATH by default
- Windows and Linux both have: python, node, git, docker, etc.
- Case sensitivity issues (Windows is case-insensitive)
- WSLENV variable misconfiguration

**Consequences:**
- `python` runs wrong interpreter
- Scripts fail with Windows line endings
- Performance degradation (WSL->Windows binary = slow)
- `which python` shows `/mnt/c/...` instead of `/usr/bin/...`

**Prevention:**
```bash
# OPTION 1: Disable Windows PATH entirely (recommended for dev)
# Edit /etc/wsl.conf:
[interop]
enabled = true  # Still allow .exe execution
appendWindowsPath = false  # Don't auto-add Windows PATH

# Then manually add only needed Windows tools in .zshrc:
# Add VS Code
export PATH="$PATH:/mnt/c/Users/YourName/AppData/Local/Programs/Microsoft VS Code/bin"
# Add Windows tools you actually use
export PATH="$PATH:/mnt/c/Windows/System32"

# OPTION 2: Filter Windows PATH (more complex)
# In .zshrc/.zshenv:
# Remove Windows paths, keeping only Linux
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "/mnt/c" | tr '\n' ':' | sed 's/:$//')
# Then selectively add back needed Windows paths

# OPTION 3: Ensure Linux binaries come first
# Prepend Linux paths (overrides Windows)
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

# WSL2 SPECIFIC CHECKS:
# Verify which binary will run:
which -a python  # Should show /usr/bin/python FIRST
which -a node    # Should show WSL node FIRST, not /mnt/c/...

# FIX: If wrong binary executes
# Check your PATH order:
echo $PATH | tr ':' '\n' | nl
# Ensure /usr/local/bin, /usr/bin, /bin appear BEFORE /mnt/c/...

# WSLENV for passing environment variables (optional)
# Only needed if you want Windows to see Linux env vars
export WSLENV="SOME_VAR/p:OTHER_VAR"  # /p = translate paths
```

**Detection:**
- Run `which -a python node git docker` - look for `/mnt/c/` paths
- Check `echo $PATH | grep mnt/c`
- Test script execution: does it use Windows or Linux binary?

**Phase mapping:**
- Phase 1: Configure /etc/wsl.conf BEFORE installing anything
- Phase 2: PATH configuration in .zshenv

---

### Pitfall 8: Symlink Direction Confusion

**What goes wrong:** Symlinks point the wrong direction, causing dotfiles repo to get modified instead of home directory, or symlinks create circular references.

**Why it happens:**
- `ln -s` argument order confusion: `ln -s TARGET LINK_NAME`
- Using relative paths that break when PWD changes
- Symlinking entire directories when only files should be linked

**Consequences:**
- "Too many levels of symbolic links" error
- Editing config modifies repo instead of deployed file
- Symlinks break when repo moves
- Git status shows modified files unexpectedly

**Prevention:**
```bash
# CORRECT SYMLINK SYNTAX:
ln -s [TARGET/SOURCE] [LINK_NAME/DESTINATION]
ln -s /path/to/actual/file /path/to/symlink

# EXAMPLE: Link dotfiles repo to home
DOTFILES="$HOME/dotfiles"

# CORRECT:
ln -s "$DOTFILES/.zshrc" "$HOME/.zshrc"
# Result: ~/.zshrc -> ~/dotfiles/.zshrc (GOOD)
# Editing ~/.zshrc modifies ~/dotfiles/.zshrc

# WRONG:
ln -s "$HOME/.zshrc" "$DOTFILES/.zshrc"  # BACKWARDS!
# Result: ~/dotfiles/.zshrc -> ~/.zshrc
# This means dotfiles/.zshrc points to (nonexistent) ~/.zshrc

# USE ABSOLUTE PATHS (safer):
# BAD (relative):
cd ~/dotfiles
ln -s .zshrc ~/.zshrc  # Fragile - breaks if PWD changes

# GOOD (absolute):
ln -s "$HOME/dotfiles/.zshrc" "$HOME/.zshrc"

# VERIFY SYMLINKS:
ls -la ~/.zshrc
# Should show: .zshrc -> /home/user/dotfiles/.zshrc

readlink ~/.zshrc
# Should show: /home/user/dotfiles/.zshrc

# USE GNU STOW (eliminates confusion):
cd ~/dotfiles
stow -t ~ zsh  # Stows contents of zsh/ to ~/
# Stow handles symlink direction correctly

# DIRECTORY SYMLINKS (be careful):
# Don't symlink entire .ssh/ (security risk)
# DO symlink individual config files:
ln -s "$DOTFILES/.ssh/config" "$HOME/.ssh/config"
```

**Detection:**
- Run `find ~ -maxdepth 1 -type l -ls` to see all symlinks
- Check `readlink ~/.zshrc` - should point to repo
- Test: Edit config file, check `git status` in dotfiles repo

**Phase mapping:**
- Phase 1: Document symlink strategy (Stow vs manual vs script)
- Use absolute paths in bootstrap script

---

### Pitfall 9: Oh My Zsh Plugin Conflicts

**What goes wrong:** Two plugins provide same functionality, causing completion conflicts, command shadowing, or shell errors.

**Why it happens:**
- Overlapping plugin functionality (e.g., docker + kubectl both provide completions)
- Plugin load order matters but isn't documented
- Plugins overwrite each other's aliases
- Syntax highlighting + autosuggestions interaction bugs

**Consequences:**
- Completions don't work
- Aliases execute wrong command
- Shell errors on startup
- Performance degradation (duplicate functionality)

**Prevention:**
```bash
# COMMON CONFLICTS:

# 1. zsh-autosuggestions + bracketed-paste
# Fix: Set ignore widgets
ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=(bracketed-paste)

# 2. Multiple completion sources (OMZ plugin + manual)
# Only enable ONE:
# EITHER: plugins=(docker)
# OR: Manual completion, NOT both

# 3. Plugin load order MATTERS:
plugins=(
    # Core plugins first
    git

    # Completion plugins before syntax
    zsh-autosuggestions

    # Syntax highlighting MUST be last
    zsh-syntax-highlighting
)

# 4. Check for alias conflicts:
# After sourcing OMZ, check:
alias | grep -E "^(ls|cd|git)" | sort
# Look for unexpected overrides

# 5. Minimal plugin set:
# Start with bare minimum, add incrementally
plugins=(
    git  # Only if you use git aliases
    zsh-autosuggestions
    zsh-syntax-highlighting
)
# DON'T add plugins "just in case"

# 6. Test plugins in isolation:
# Temporarily disable all plugins:
# plugins=()
# source $ZSH/oh-my-zsh.sh
# Then add one at a time until you find conflict
```

**Detection:**
- Disable all plugins, enable one at a time
- Check `alias` output for conflicts
- Watch for shell errors on startup

**Phase mapping:**
- Phase 3: Plugin selection and testing
- Document why each plugin is included

---

### Pitfall 10: NVM Not Found in Zsh

**What goes wrong:** `nvm: command not found` even though NVM installed. Node version switching doesn't work.

**Why it happens:**
- NVM not sourced in .zshrc (was in .bashrc only)
- Sourcing happens after OMZ, but OMZ sets completion before NVM loads
- `.nvmrc` files not automatically detected
- Lazy loading breaks auto-switching

**Consequences:**
- Can't switch Node versions
- Scripts fail that depend on specific Node version
- `.nvmrc` files ignored

**Prevention:**
```bash
# CORRECT NVM SETUP FOR ZSH:

# Option 1: Standard (slow - 300-500ms startup cost)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Loads nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/bash_completion"  # Loads completion

# Option 2: OMZ plugin zsh-nvm (better)
# Install: git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
# In .zshrc BEFORE plugins=():
export NVM_LAZY_LOAD=true  # 70x faster startup!
export NVM_AUTO_USE=true   # Auto-switch based on .nvmrc

plugins=(
    zsh-nvm  # Add to plugins list
    # ... other plugins
)

# AUTO-SWITCH NODE VERSION ON CD (without plugin):
# Add to .zshrc AFTER nvm is loaded:
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# FIX: "N/A -> N/A" error with lts/*
# Zsh aggressively globs *, need to escape:
nvm install 'lts/*'  # Single quotes prevent globbing
nvm alias default 'lts/*'

# VERIFY NVM WORKS:
command -v nvm  # Should output: nvm
nvm --version   # Should show version number
```

**Detection:**
- Run `command -v nvm` (should output "nvm")
- Test `.nvmrc` auto-switching: cd to project with .nvmrc
- Check startup time: `time zsh -i -c exit`

**Phase mapping:**
- Phase 2: NVM setup with lazy loading
- Phase 3: Test .nvmrc auto-switching

---

## Minor Pitfalls

Mistakes that cause annoyance but are easily fixable.

### Pitfall 11: Compinit Insecure Directories Warning

**What goes wrong:** Oh My Zsh startup shows: "zsh compinit: insecure directories, run compaudit for list"

**Why it happens:**
- Homebrew creates world-writable completion directories
- Wrong ownership on ZSH directories
- Group-writable permissions on completion files

**Prevention:**
```bash
# Quick fix: Disable security check (NOT RECOMMENDED for production)
# In .zshrc BEFORE sourcing oh-my-zsh:
ZSH_DISABLE_COMPFIX=true

# Proper fix: Fix permissions
compaudit | xargs chmod g-w,o-w  # Remove group/other write

# Or use -u flag to skip checks:
autoload -Uz compinit && compinit -u

# For Homebrew completions specifically:
chmod -R go-w "$(brew --prefix)/share"
```

**Phase mapping:** Phase 2 - after installing Homebrew/OMZ

---

### Pitfall 12: Powerlevel10k Unicode Display Issues

**What goes wrong:** P10k prompt shows question marks or boxes instead of powerline symbols.

**Why it happens:**
- Terminal doesn't support Nerd Font
- Font not installed in Windows Terminal settings for WSL
- Wrong font configured

**Prevention:**
```bash
# 1. Install Nerd Font
# Download from: https://www.nerdfonts.com/
# Recommended: MesloLGS NF (P10k recommendation)

# 2. Configure Windows Terminal (settings.json):
{
    "profiles": {
        "defaults": {},
        "list": [
            {
                "name": "Ubuntu (WSL2)",
                "fontFace": "MesloLGS NF",
                "fontSize": 10
            }
        ]
    }
}

# 3. Run P10k configuration wizard:
p10k configure
# Choose options with icon previews

# Verify: Prompt should show Git icons, folder icons correctly
```

**Phase mapping:** Phase 3 - theming and visual setup

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation | Priority |
|-------------|---------------|------------|----------|
| **Phase 1: Bootstrap** | File clobbering | Implement backup-before-checkout | CRITICAL |
| **Phase 1: Bootstrap** | Non-idempotent script | Use check-before-action pattern | CRITICAL |
| **Phase 1: Git Setup** | Secret leaks | Install git-secrets before first commit | CRITICAL |
| **Phase 2: Zsh Migration** | Array indexing breaks aliases | Audit aliases for `[0]` syntax | HIGH |
| **Phase 2: PATH Setup** | Wrong binary execution | Document PATH priority order | HIGH |
| **Phase 2: WSL2 Config** | Windows PATH pollution | Configure /etc/wsl.conf first | MEDIUM |
| **Phase 3: OMZ Install** | Startup performance collapse | Enable lazy loading, minimize plugins | MEDIUM |
| **Phase 3: NVM Setup** | Command not found | Use zsh-nvm plugin with lazy load | MEDIUM |
| **Phase 4: Symlinks** | Wrong direction | Use GNU Stow or absolute paths | LOW |
| **Phase 4: Compinit** | Insecure directories warning | Run chmod -R go-w on completion dirs | LOW |

---

## Research Confidence Assessment

| Area | Confidence | Basis |
|------|-----------|-------|
| Bash→Zsh migration | HIGH | Multiple authoritative sources, known issues documented |
| Secret prevention | HIGH | AWS git-secrets docs, pre-commit framework docs |
| WSL2 issues | HIGH | Microsoft WSL GitHub issues, recent 2025 reports |
| OMZ performance | HIGH | Multiple blog posts with profiling, consistent findings |
| Symlink patterns | HIGH | GNU Stow docs, dotfiles community consensus |
| NVM+Zsh integration | MEDIUM | Plugin docs, but some edge cases underdocumented |
| PATH ordering | HIGH | Shell fundamentals, security advisories |
| Idempotency | HIGH | Dotfiles community best practices, multiple examples |

---

## Sources

### Bash to Zsh Migration
- [The right way to migrate your bash_profile to zsh](https://carlosroso.com/the-right-way-to-migrate-your-bash-profile-to-zsh/)
- [Moving to zsh – Scripting OS X](https://scriptingosx.com/2019/06/moving-to-zsh/)
- [Zsh vs. Bash | Better Stack Community](https://betterstack.com/community/guides/linux/zsh-vs-bash/)
- [Bash vs Zsh Array Behavior - codestudy.net](https://www.codestudy.net/blog/behavior-of-arrays-in-bash-scripting-and-zsh-shell-start-index-0-or-1/)

### Symlink Best Practices
- [Using GNU Stow to Manage Symbolic Links for Your Dotfiles - System Crafters](https://systemcrafters.net/managing-your-dotfiles/using-gnu-stow/)
- [Manage Your Dotfiles Like a Superhero](https://www.jakewiesler.com/blog/managing-dotfiles)
- [dotfiles - ArchWiki](https://wiki.archlinux.org/title/Dotfiles)

### Bootstrap & Idempotency
- [GitHub - anishathalye/dotbot](https://github.com/anishathalye/dotbot)
- [Bootstrap - yadm](https://yadm.io/docs/bootstrap)
- [GitHub - Xe0n0/dotfiles - Idempotent bootstrap script](https://github.com/Xe0n0/dotfiles)

### Secret Detection & Prevention
- [Dotfiles Security: How to Stop Leaking Secrets on GitHub](https://instatunnel.my/blog/why-your-public-dotfiles-are-a-security-minefield)
- [8 Effective Ways to Prevent Secrets from Being Committed to Git Repositories](https://medium.com/@bronya.korolyova/8-effective-ways-to-prevent-secrets-from-being-committed-to-git-repositories-eda149bec431)
- [GitHub - awslabs/git-secrets](https://github.com/awslabs/git-secrets)
- [Git Hooks: Prevent Secrets Exposure](https://orca.security/resources/blog/git-hooks-prevent-secrets/)

### WSL2 Issues
- [Troubleshooting Windows Subsystem for Linux | Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/troubleshooting)
- [WSL2 systemd interop issues - Issue #13449](https://github.com/microsoft/WSL/issues/13449)
- [Advanced settings configuration in WSL | Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)

### PATH Configuration
- [How to Fix "Command Not Found" PATH Errors](https://oneuptime.com/blog/post/2026-01-24-fix-command-not-found-path-errors/view)
- [What's wrong with having '.' in your $PATH?](https://cets.seas.upenn.edu/answers/dot-path.html)
- [What the heck is my PATH?](https://astrobiomike.github.io/unix/modifying_your_path)

### Oh My Zsh Performance
- [Speeding Up My Shell (Oh My Zsh)](https://blog.mattclemente.com/2020/06/26/oh-my-zsh-slow-to-load/)
- [Speeding Up My ZSH Shell - Scott Spence](https://scottspence.com/posts/speeding-up-my-zsh-shell)
- [oh-my-zsh very slow - Issue #5327](https://github.com/ohmyzsh/ohmyzsh/issues/5327)
- [why does zsh start so slowly?](https://pickard.cc/posts/why-does-zsh-start-slowly/)

### NVM + Zsh
- [GitHub - nvm-sh/nvm](https://github.com/nvm-sh/nvm)
- [GitHub - lukechilds/zsh-nvm](https://github.com/lukechilds/zsh-nvm)
- [nvm Error: 'N/A: version "N/A -> N/A" is not yet installed'](https://www.codegenes.net/blog/nvm-n-a-version-n-a-n-a-is-not-yet-installed/)
- [How to Use and Tips for nvm](https://2coffee.dev/en/articles/how-to-use-and-tips-for-nvm-node-version-manager)

### File Clobbering Prevention
- [How to Store Dotfiles - A Bare Git Repository | Atlassian](https://www.atlassian.com/git/tutorials/dotfiles)
- [How I manage dotfiles with Stow - Bytes & Bobs](https://bytesandbobs.net/how-i-manage-dotfiles/)

### Compinit & Permissions
- ["zsh compinit: insecure files" Prompt on oh-my-zsh](https://sonykey2003.medium.com/zsh-compinit-insecure-files-prompt-on-oh-my-zsh-f227bc5eb6dd)
- [Fix Oh My Zsh "Insecure completion-dependent directories detected"](https://osxdaily.com/2021/12/29/fix-oh-my-zsh-insecure-completion-dependent-directories-detected/)
- [Fixing Zsh Completion Security Warnings on macOS](https://www.hyokualexkwon.com/posts/fixing-zsh-completion-security-warnings-macos/)
