# dotfiles

Personal dotfiles managed by chezmoi with age encryption for secrets. One command sets up a fresh WSL2 Ubuntu machine with the complete dev environment.

## Stack

- **chezmoi** - Dotfile management with templating and secrets
- **age** - Modern encryption for secrets (keys, tokens, API credentials)
- **zsh** - Primary shell
- **Starship** - Fast, minimal prompt
- **antidote** - Lightweight zsh plugin manager
- **fnm** - Fast Node.js version manager (40x faster than nvm)
- **fzf** - Fuzzy finder for command history and file navigation
- **zoxide** - Smarter cd command with frecency algorithm
- **pre-commit + detect-secrets** - Prevent accidental secret commits

## Quick Start (New Machine)

Bootstrap a fresh machine in three steps:

```bash
# 1. Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# 2. Retrieve age key from Bitwarden, save to ~/key.txt
# (See "Secrets & Encryption" section below)

# 3. Initialize and apply dotfiles
chezmoi init --apply https://github.com/seanGSISG/.dotfiles.git

# 4. Source secrets into current shell
source ~/.secrets.env
```

The `chezmoi init` step will:
- Clone this repo to `~/.local/share/chezmoi/`
- Render `.chezmoi.toml` from the template using your machine's hostname/username
- Apply all managed files to your home directory
- Decrypt `~/.secrets.env` using the age key

## Secrets & Encryption

### How It Works

Secrets are stored in `~/.secrets.env`, encrypted in the repo as `encrypted_dot_secrets.env.age`. The age encryption key (`~/key.txt`) is stored in Bitwarden and never committed to git.

Shell configs (`.bashrc`, `.zshrc`, `.profile`) source `~/.secrets.env` if it exists:

```bash
[ -f ~/.secrets.env ] && source ~/.secrets.env
```

### Current Secrets

- `GITHUB_PERSONAL_ACCESS_TOKEN` - GitHub CLI authentication
- `EXA_API_KEY` - Exa search API
- `GREPTILE_API_KEY` - Greptile code search API

### Adding New Secrets

```bash
# Edit secrets file (opens decrypted in $EDITOR)
chezmoi edit ~/.secrets.env

# Review changes
chezmoi diff

# Apply (re-encrypts)
chezmoi apply --verbose
```

### Retrieving the Age Key

The encryption key is stored in Bitwarden as a secure note titled "dotfiles age key" (or similar).

On a new machine:
1. Install Bitwarden CLI: `npm install -g @bitwarden/cli`
2. Login: `bw login`
3. Get the key: `bw get notes "dotfiles age key" > ~/key.txt`
4. Secure it: `chmod 600 ~/key.txt`

Alternative: Copy the key manually from Bitwarden vault to `~/key.txt`

### Storing the Age Key (First Time)

After initial setup, store `~/key.txt` in Bitwarden:

1. Open Bitwarden vault
2. Create new secure note: "dotfiles age key"
3. Paste contents of `~/key.txt`
4. Save

**CRITICAL**: The age key is the only way to decrypt your secrets. Losing it means losing access to all encrypted data.

## Directory Structure

```
~/.local/share/chezmoi/          # chezmoi source directory (this repo)
├── .chezmoi.toml.tmpl           # Template for machine-specific config
├── .chezmoiignore               # Files to not apply to home directory
├── .gitignore                   # Blocks age keys from git
├── .pre-commit-config.yaml      # Pre-commit hooks
├── .secrets.baseline            # detect-secrets baseline
├── .secrets.env.example         # Template for secrets file
├── encrypted_dot_secrets.env.age # Encrypted secrets (safe to commit)
├── dot_bashrc                   # Managed .bashrc
├── dot_zshrc                    # Managed .zshrc
├── dot_profile                  # Managed .profile
└── README.md                    # This file (not applied to ~/)
```

Files prefixed with `dot_` become hidden files in your home directory (e.g., `dot_bashrc` → `~/.bashrc`).

Files with `.age` suffix are encrypted and decrypted automatically by chezmoi.

## Day-to-Day Usage

```bash
# View current status
chezmoi status

# See what would change (always dry-run first)
chezmoi diff

# Edit a managed file
chezmoi edit ~/.bashrc

# Edit encrypted secrets
chezmoi edit ~/.secrets.env

# Apply changes
chezmoi apply --verbose

# Add a new file to chezmoi
chezmoi add ~/.gitconfig

# Add a new secret file (encrypted)
chezmoi add --encrypt ~/.aws/credentials

# Commit and push changes
cd ~/.local/share/chezmoi
git add [files]
git commit -m "description"
git push
```

## Safety Notes

1. **Never edit target files directly** - Always use `chezmoi edit` or modify source files
2. **Always dry-run first** - Use `chezmoi diff` before `chezmoi apply`
3. **Pre-commit hooks protect you** - detect-secrets scans for plaintext secrets before commits
4. **Encrypted files are safe** - Only `.age` files are committed, never plaintext secrets
5. **Keep age key secure** - Store in Bitwarden, never commit to git
6. **Test on a VM first** - Before applying major changes, test in a disposable environment

## Troubleshooting

**Decryption fails:**
- Verify `~/key.txt` exists and matches the public key in `.chezmoi.toml`
- Check file permissions: `chmod 600 ~/key.txt`

**Pre-commit hook blocks commit:**
- Review flagged files: `git diff --cached`
- If false positive: Update baseline with `detect-secrets scan > .secrets.baseline`
- If real secret: Move to `~/.secrets.env` and encrypt

**Changes not applying:**
- Check ignored files: `cat ~/.local/share/chezmoi/.chezmoiignore`
- Verify source file exists in chezmoi directory
- Run with verbose output: `chezmoi apply --verbose --dry-run`

## References

- [chezmoi documentation](https://www.chezmoi.io/)
- [age encryption](https://github.com/FiloSottile/age)
- [detect-secrets](https://github.com/Yelp/detect-secrets)
