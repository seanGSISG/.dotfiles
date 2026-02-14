# Copilot Instructions for .dotfiles

This repository manages a WSL2 Ubuntu development environment using chezmoi with age encryption.

## Repository Structure & Chezmoi Conventions

### Chezmoi Naming Conventions
Files in this repository use chezmoi's naming scheme:
- `dot_` prefix → deploys with `.` prefix (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_` prefix → deploys with mode 0600 (e.g., `private_dot_ssh/`)
- `.tmpl` suffix → chezmoi template using Go text/template syntax
- `encrypted_*.age` → age-encrypted files
- `run_once_` prefix → script runs once per machine
- `run_onchange_after_` prefix → script runs after apply when source changes

### File Structure
- `dot_config/zsh/` - Zsh configuration modules (ZDOTDIR = ~/.config/zsh)
- `dot_config/tmux/` - Tmux configuration (XDG compliant)
- `dot_config/starship.toml` - Starship prompt configuration
- `packages/` - Package manifests (apt-packages.txt, uv-tools.txt, winget-packages.txt)
- `dot_claude/` - Claude Code configurations
- `private_dot_ssh/` - SSH keys (age-encrypted)
- `encrypted_dot_secrets.env.age` - Encrypted secrets file

## Build & Test Commands

### Bootstrap & Setup
```bash
./bootstrap.sh              # Full environment setup (idempotent, safe to re-run)
./verify.sh                 # Post-install validation (8 sections, 40+ checks)
```

### Chezmoi Workflow
```bash
chezmoi diff                # Preview changes before applying
chezmoi apply --verbose     # Deploy changes
chezmoi edit <target>       # Edit source file (e.g., chezmoi edit ~/.zshrc)
chezmoi add <file>          # Track a new file
chezmoi add --encrypt <file> # Track with age encryption
```

### Testing
- Run `./verify.sh` to validate the environment setup
- Test shell configurations by sourcing them: `source ~/.zshrc`
- Validate templates: `chezmoi execute-template < file.tmpl`

## Code Style & Standards

### Shell Scripts
- Use `set -euo pipefail` in bash scripts where appropriate
- Color-coded output using tput (see bootstrap.sh for patterns)
- Functions should have descriptive names and inline comments
- Error handling with proper exit codes and error messages

### Commits
- Use Conventional Commits format: `fix:`, `feat:`, `docs:`, `chore:` prefixes
- Write descriptive commit messages explaining "why", not just "what"
- Example: `feat: add fzf integration to zsh tools` not `add fzf`

### Comments
- Shell aliases should have inline comments explaining their purpose
- Complex functions should have header comments
- Templates should document available variables

## Zsh Configuration

### Load Order
The `.zshrc` sources files in this exact order (order matters):
1. `exports.zsh` - PATH, env vars, history config
2. `plugins.zsh` - Antidote + compinit (24h cache)
3. `tools.zsh` - fnm, fzf, zoxide integrations
4. `functions.zsh` - Shell functions and alias-help system
5. `aliases/*.zsh` - All alias files (loaded in a loop)
6. `wsl.zsh` - WSL2-specific (conditional via chezmoi template)
7. `~/.secrets.env` - Decrypted secrets
8. Starship init - Prompt (must be last, modifies precmd)

### Alias Organization
- Organize aliases by category in `dot_config/zsh/aliases/`
- Categories: git, docker, dev, navigation, system, utilities
- Each alias must have an inline comment
- Follow pattern: `alias shortcut='command' # Description`

### Functions
- Add custom functions to `functions.zsh`
- Use graceful degradation with `command -v` checks
- Support both interactive and non-interactive shells

## Security & Safety Rules

### Never Do This
- **Never edit deployed files** directly (`~/.zshrc`, `~/.gitconfig`, etc.) - changes get overwritten by `chezmoi apply`
- **Never commit plaintext secrets** - use `chezmoi add --encrypt` for sensitive files
- **Never hardcode user-specific paths** - use variables or chezmoi templates
- **Never commit the age encryption key** (`~/.config/age/keys.txt`) - it's sourced from Bitwarden
- **Never modify `.git/` or `.github/agents/` directories**

### Always Do This
- Always edit managed files via `chezmoi edit <file>`, not directly
- Always use `chezmoi diff` before `chezmoi apply`
- Always test templates with `chezmoi execute-template`
- Always check pre-commit hooks pass before committing
- Always validate changes with `./verify.sh` when modifying core functionality

### Encryption
- Secrets stored in `~/.secrets.env`, encrypted in repo as `encrypted_dot_secrets.env.age`
- Age key lives at `~/.config/age/keys.txt`, sourced from Bitwarden, never in git
- Pre-commit hooks (detect-secrets) scan for plaintext secrets
- Use `chezmoi edit ~/.secrets.env` to edit encrypted secrets

## Adding New Tools

When adding a new tool or package:
1. Add package to appropriate manifest in `packages/` directory:
   - `apt-packages.txt` for APT packages (Linux only)
   - `uv-tools.txt` for Python tools via uv
   - `binary-installs.txt` for manual binary installations (reference only)
   - `winget-packages.txt` for Windows packages
2. Add integration to `tools.zsh` with graceful degradation (`command -v` check)
3. Update documentation if the tool requires special configuration
4. Test with `./verify.sh` to ensure detection works

## Platform-Specific Code

### OS Conditionals
Use chezmoi templates for OS-specific behavior:
```
{{ if eq .chezmoi.os "linux" }}
# Linux-specific code
{{ else if eq .chezmoi.os "windows" }}
# Windows-specific code
{{ end }}
```

### .chezmoiignore
- Files in `.chezmoiignore` are NOT deployed by chezmoi
- Includes: README.md, packages/, bootstrap.sh, verify.sh, .planning/
- Uses template syntax for OS-conditional ignores
- Linux-only: apt-packages.txt, binary-installs.txt
- Windows-only: winget-packages.txt, PowerShell configs

## Naming Conventions

- Shell files: Use lowercase with hyphens (e.g., `aliases-git.zsh`)
- Functions: Use lowercase with underscores (e.g., `reload_shell`)
- Variables: Use UPPERCASE for environment variables, lowercase for local vars
- Alias categories: git, docker, dev, navigation, system, utilities

## Important Context

### ZDOTDIR Architecture
- `~/.zshenv` sets `ZDOTDIR=~/.config/zsh` so all zsh config lives under XDG
- The root `~/.zshrc` is a stub that sources `$ZDOTDIR/.zshrc`
- `skip_global_compinit=1` is set in `.zshenv` to prevent system compinit
- Custom compinit runs in `plugins.zsh` with 24h caching

### History Configuration
- Zsh history: 100,000 lines with deduplication
- History file: `~/.config/zsh/.zsh_history`
- INC_APPEND_HISTORY and HIST_EXPIRE_DUPS_FIRST enabled

### Plugin Management
- Zsh: antidote (plugin manager)
- Tmux: TPM (Tmux Plugin Manager)
- Plugin manifests: `private_dot_zsh_plugins.txt` for antidote

## Common Patterns

### Color Output in Scripts
```bash
RED=$(tput setaf 1 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")
```

### Graceful Tool Detection
```bash
if command -v tool_name &>/dev/null; then
  # Tool-specific configuration
fi
```

### Template Variables
Common chezmoi template variables:
- `{{ .chezmoi.os }}` - Operating system (linux, windows, darwin)
- `{{ .chezmoi.hostname }}` - Machine hostname
- `{{ .chezmoi.username }}` - Current username

## Troubleshooting Guidelines

When debugging issues:
1. Check `./verify.sh` output for environment validation
2. Review `~/.dotfiles-bootstrap-*.log` for bootstrap errors
3. Use `chezmoi diff` to see what would change
4. Test templates with `chezmoi execute-template`
5. Check shell configuration load order (exports → plugins → tools → functions → aliases)
