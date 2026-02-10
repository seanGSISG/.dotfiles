# Phase 1: Repository Foundation & Safety - Research

**Researched:** 2026-02-10
**Domain:** chezmoi dotfiles management with age encryption
**Confidence:** HIGH

## Summary

chezmoi is the established standard for managing dotfiles across multiple machines with built-in support for templating, encryption, and version control. The tool stores desired state in `~/.local/share/chezmoi` and uses special file naming conventions (prefixes like `dot_`, `private_`, `executable_`) to control how files are applied to the target system.

age encryption integrates directly into chezmoi through configuration in `chezmoi.toml`, using asymmetric key pairs generated via `chezmoi age-keygen`. Files added with `chezmoi add --encrypt` are stored encrypted in the repository and automatically decrypted during `chezmoi apply` when the private key is available.

Safety guardrails are critical: pre-commit hooks (detect-secrets or gitleaks), `.gitignore` patterns to exclude keys, `.chezmoiignore` for non-managed files, and mandatory dry-run verification (`chezmoi apply --dry-run --verbose`) before applying changes prevent accidental secret exposure and data loss.

**Primary recommendation:** Initialize chezmoi with age encryption configured from the start, establish pre-commit secret scanning before the first commit, and always backup existing dotfiles before running `chezmoi add`.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| chezmoi | v2.x (latest) | Dotfiles state management | Official standard, built-in age support, active development |
| age | v1.x | File encryption | Recommended by chezmoi, simpler than GPG, no passphrases needed |
| git | 2.x | Version control | Built into chezmoi workflow, required for multi-machine sync |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| detect-secrets | v1.5.0+ | Pre-commit secret scanning | Baseline-based approach, fewer false positives |
| gitleaks | v8.x | Pre-commit secret scanning | Alternative to detect-secrets, faster scans |
| pre-commit | 3.x | Git hook framework | Manage multiple hooks consistently |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| age | GPG | GPG more complex, requires passphrase or agent, age simpler for dotfiles |
| detect-secrets | gitleaks | gitleaks faster but more false positives, detect-secrets has baseline workflow |
| chezmoi | GNU stow | stow is symlink-only, no encryption or templating, chezmoi is full-featured |

**Installation:**
```bash
# chezmoi (direct binary)
sh -c "$(curl -fsLS get.chezmoi.io)"

# age (via package manager or direct)
apt install age  # or download from https://github.com/FiloSottile/age/releases

# pre-commit framework
pip install pre-commit

# detect-secrets
pip install detect-secrets
```

## Architecture Patterns

### Recommended Project Structure
```
~/.local/share/chezmoi/          # Source state (git repo)
├── .chezmoi.toml.tmpl           # Config template (for machine-specific values)
├── .chezmoiignore               # Files to not apply to target
├── .chezmoiremove               # Files to remove from target
├── .gitignore                   # Prevent committing keys
├── .pre-commit-config.yaml      # Pre-commit hooks config
├── .secrets.baseline            # detect-secrets baseline (if used)
├── README.md                    # Bootstrap instructions
├── .secrets.env.example         # Template for required secrets
├── dot_zshrc.tmpl               # Template files (.tmpl extension)
├── private_dot_ssh/             # Private directory (0700 permissions)
│   └── encrypted_private_id_ed25519.age  # Encrypted file (.age extension)
└── .planning/                   # Project planning docs (committed per user decision)
```

### Pattern 1: Age Encryption Setup
**What:** Generate age key, configure chezmoi, add encrypted files
**When to use:** For any files containing secrets (API keys, tokens, private SSH keys)
**Example:**
```bash
# Source: https://www.chezmoi.io/user-guide/encryption/age/
# Generate age key pair
chezmoi age-keygen --output=$HOME/key.txt
# Output includes public key like: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p

# Configure chezmoi (edit ~/.config/chezmoi/chezmoi.toml)
encryption = "age"
[age]
identity = "/home/user/key.txt"
recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"

# Add encrypted file
chezmoi add --encrypt ~/.ssh/id_ed25519

# Ignore the key itself
echo "key.txt" >> ~/.local/share/chezmoi/.chezmoiignore
```

### Pattern 2: Safe Apply Workflow
**What:** Always verify before applying changes
**When to use:** Every time before running `chezmoi apply`
**Example:**
```bash
# Source: https://www.chezmoi.io/reference/commands/apply/
# See what would change
chezmoi diff

# Dry-run with verbose output
chezmoi apply --dry-run --verbose

# Apply changes (only after verification)
chezmoi apply -v
```

### Pattern 3: Pre-commit Secret Scanning
**What:** Block commits containing secrets
**When to use:** Set up immediately after `chezmoi init`, before first commit
**Example:**
```yaml
# Source: https://github.com/Yelp/detect-secrets
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        exclude: package.lock.json
```

```bash
# Initialize baseline (marks known secrets as approved)
detect-secrets scan > .secrets.baseline

# Install hooks
pre-commit install
```

### Pattern 4: Template for Machine-Specific Values
**What:** Use chezmoi templates for hostname, username, paths
**When to use:** Files with machine-specific configuration
**Example:**
```bash
# Source: https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/
# dot_zshrc.tmpl
export HOSTNAME="{{ .chezmoi.hostname }}"
export USER="{{ .chezmoi.username }}"

{{- if eq .chezmoi.os "linux" }}
export PLATFORM="linux"
{{- else if eq .chezmoi.os "darwin" }}
export PLATFORM="macos"
{{- end }}
```

### Pattern 5: Bootstrap on New Machine
**What:** Single-command setup on new machine
**When to use:** Initial setup or after machine rebuild
**Example:**
```bash
# Source: https://www.chezmoi.io/quick-start/
# Requires age key already available (from Bitwarden or backup)

# One-command init and apply
chezmoi init --apply https://github.com/seanGSISG/.dotfiles.git

# Will prompt for age key location or passphrase if needed
```

### Anti-Patterns to Avoid
- **Editing target files directly:** Always use `chezmoi edit ~/.zshrc`, never edit `~/.zshrc` directly (changes will be overwritten)
- **Committing plaintext secrets:** Never add secret files without `--encrypt` flag
- **Skipping dry-run:** Running `chezmoi apply` without `--dry-run` first risks unexpected overwrites
- **Auto-pushing to remote:** Automating `git push` increases risk of accidentally pushing secrets before hooks run
- **Forgetting .gitignore:** Age keys must be in `.gitignore` to prevent accidental commit

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| File permission management | Manual `chmod` in scripts | chezmoi `private_` prefix | Declarative, version-controlled, applies automatically |
| Multi-machine differences | Shell `if` statements checking hostname | chezmoi templates with `.chezmoi.hostname` | Cleaner, renders at apply time, no runtime overhead |
| Secret encryption | Custom encryption scripts | chezmoi age integration | Built-in, tested, handles key management |
| Dotfile symlinks | Custom symlink scripts or GNU stow | chezmoi copy/template system | Handles templates, encryption, permissions together |
| Secret scanning | Regex patterns in shell scripts | detect-secrets or gitleaks | Comprehensive pattern databases, baseline management, maintained |
| Backup before apply | Custom backup scripts | chezmoi's state tracking + git history | Built-in safety, version control integration |

**Key insight:** Dotfiles management appears simple but has subtle edge cases (permissions, templating, encryption, multi-machine sync). chezmoi handles these comprehensively; custom solutions inevitably reimplement its features poorly.

## Common Pitfalls

### Pitfall 1: Editing Wrong File Location
**What goes wrong:** User edits `~/.zshrc` directly, then runs `chezmoi apply` and changes are overwritten
**Why it happens:** Confusion about source state vs target state
**How to avoid:** Always use `chezmoi edit <file>` or edit files in `~/.local/share/chezmoi/` directly
**Warning signs:** Changes to dotfiles keep disappearing after running `chezmoi apply`

### Pitfall 2: Committing Encryption Keys
**What goes wrong:** Age private key (`key.txt`) gets committed to repository, exposing all encrypted secrets
**Why it happens:** Missing or incomplete `.gitignore` patterns
**How to avoid:** Add keys to `.gitignore` AND `.chezmoiignore` immediately after generation
**Warning signs:** `git status` shows `key.txt` as untracked; pre-commit hook fails with key detection

### Pitfall 3: .chezmoiignore Confusion
**What goes wrong:** Files appear/disappear unexpectedly during `chezmoi apply`
**Why it happens:** .chezmoiignore matches target paths, not source paths; patterns prevent files from being applied
**How to avoid:** Test ignore patterns with `chezmoi apply --dry-run --verbose` to see what's excluded
**Warning signs:** Files in source state don't appear in target after apply

### Pitfall 4: No Backup Before Migration
**What goes wrong:** `chezmoi add` or `chezmoi apply` overwrites existing dotfiles, no recovery possible
**Why it happens:** Assumption that chezmoi is non-destructive
**How to avoid:** Create backup before first `chezmoi add`: `tar czf ~/dotfiles-backup-$(date +%Y%m%d).tar.gz ~/.zshrc ~/.ssh ~/.config`
**Warning signs:** N/A - this is preventative

### Pitfall 5: Skipping Verification
**What goes wrong:** `chezmoi apply` makes unexpected changes (deletes files, wrong permissions, wrong content)
**Why it happens:** Not using `--dry-run --verbose` to preview changes
**How to avoid:** Make `chezmoi diff` and `chezmoi apply -nv` part of standard workflow
**Warning signs:** Surprise when running `chezmoi apply`, files not in expected state

### Pitfall 6: Encryption Key Not Available on New Machine
**What goes wrong:** `chezmoi apply` fails because age key isn't present, encrypted files can't be decrypted
**Why it happens:** Key stored only on original machine, not backed up to Bitwarden or secure location
**How to avoid:** Store age private key in Bitwarden immediately after generation; document retrieval process in README
**Warning signs:** `chezmoi apply` errors with "age: no identity matched" on new machine

### Pitfall 7: Template Files Without .tmpl Extension
**What goes wrong:** Files with template syntax ({{ .chezmoi.hostname }}) are copied literally without processing
**Why it happens:** Forgetting to add `.tmpl` extension when creating template
**How to avoid:** Use `chezmoi add --template` or manually add `.tmpl` extension to source file
**Warning signs:** Literal "{{ .chezmoi.hostname }}" appears in applied files

## Code Examples

Verified patterns from official sources:

### Complete Initialization Sequence
```bash
# Source: https://www.chezmoi.io/quick-start/
# Initialize chezmoi (creates ~/.local/share/chezmoi)
chezmoi init

# Generate age key for encryption
chezmoi age-keygen --output=$HOME/key.txt
# Save the public key output (age1...) for config

# Configure chezmoi with age encryption
cat > ~/.config/chezmoi/chezmoi.toml <<EOF
encryption = "age"
[age]
identity = "$HOME/key.txt"
recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
EOF

# Add key to ignore files
chezmoi cd
echo "key.txt" >> .chezmoiignore
echo "key.txt" >> .gitignore

# Add existing dotfiles
chezmoi add ~/.zshrc
chezmoi add ~/.config/starship.toml

# Add encrypted secrets
chezmoi add --encrypt ~/.ssh/id_ed25519

# Set up git remote
git remote add origin https://github.com/seanGSISG/.dotfiles.git
```

### Secret Template Pattern
```bash
# Source: https://blog.gitguardian.com/secure-your-secrets-with-env/
# Create .secrets.env.example in source state
cat > ~/.local/share/chezmoi/.secrets.env.example <<'EOF'
# API Keys and Tokens
# Copy this file to .secrets.env and fill in real values
# .secrets.env should be added with: chezmoi add --encrypt ~/.secrets.env

GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

# Commit the example (no real secrets)
git add .secrets.env.example

# Create real secrets file locally (not in git)
cp .secrets.env.example ~/.secrets.env
# Edit with real values, then:
chezmoi add --encrypt ~/.secrets.env
```

### Pre-commit Hook Setup
```bash
# Source: https://github.com/Yelp/detect-secrets
chezmoi cd

# Create pre-commit config
cat > .pre-commit-config.yaml <<'EOF'
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        exclude: |
          (?x)^(
            .*.lock|
            .*.baseline
          )$
EOF

# Generate baseline (run before first commit)
detect-secrets scan > .secrets.baseline

# Install hooks
pre-commit install

# Test manually
pre-commit run --all-files
```

### Safe Apply Workflow
```bash
# Source: https://www.chezmoi.io/reference/commands/apply/
# Always follow this sequence:

# 1. See what files have changed
chezmoi diff

# 2. Dry-run to see exact changes
chezmoi apply --dry-run --verbose

# 3. Review output carefully
# 4. Apply only if changes are expected
chezmoi apply -v

# 5. Verify result
chezmoi verify
```

### .chezmoiignore Example
```gitignore
# Source: https://github.com/renemarc/dotfiles/blob/master/.chezmoiignore
# Repository documentation (don't apply to home dir)
README.md
LICENSE
*.md

# Backup of age key (don't apply)
key.txt
key.txt.bak

# Planning docs (committed but not applied)
.planning/

# Platform-specific: ignore macOS files on Linux
{{ if ne .chezmoi.os "darwin" -}}
.config/iterm2/
.Brewfile
{{- end }}

# Platform-specific: ignore Linux files on macOS
{{ if ne .chezmoi.os "linux" -}}
.config/i3/
{{- end }}

# Ignore secrets example template on all machines
.secrets.env.example
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| GPG encryption | age encryption | 2020+ | Simpler key management, no passphrase prompts, better UX |
| Manual symlinks (GNU stow) | chezmoi declarative state | 2018+ | Adds templating, encryption, multi-machine support |
| git-secrets (AWS) | detect-secrets/gitleaks | 2020+ | Generic secret detection, not AWS-specific, baseline workflow |
| Embedded secrets in shell scripts | .env files + encryption | Ongoing | Separates config from code, easier rotation |
| `chezmoi remove` | `chezmoi forget` | v2.0+ (2020) | Clearer semantics: forget = stop managing, destroy = delete everything |

**Deprecated/outdated:**
- `chezmoi remove` command: Replaced by `chezmoi forget` (stop managing) and `chezmoi destroy` (full reset)
- Builtin age without external binary: Limited features (no passphrase, no SSH keys); install age binary for full functionality
- GPG encryption in chezmoi: Still supported but age is recommended for new setups due to simplicity

## Open Questions

Things that couldn't be fully resolved:

1. **Multi-recipient age encryption**
   - What we know: chezmoi supports multiple recipients via array syntax in config
   - What's unclear: Best practice for team dotfiles (shared age keys vs per-user encryption)
   - Recommendation: For personal dotfiles, single recipient (your key); document multi-recipient pattern as future enhancement

2. **Bitwarden Secrets Manager integration**
   - What we know: Can store age key in Bitwarden, retrieve via `bws` CLI
   - What's unclear: Whether to automate key retrieval in bootstrap or manual step
   - Recommendation: Manual retrieval documented in README; automation in later phase if needed

3. **Secret rotation workflow**
   - What we know: Requires forget → config change → re-add cycle per official docs
   - What's unclear: Best practice for rotating secrets without losing history
   - Recommendation: Document process in README, test during implementation

## Sources

### Primary (HIGH confidence)
- [chezmoi age encryption documentation](https://www.chezmoi.io/user-guide/encryption/age/) - Official setup guide
- [chezmoi quick start](https://www.chezmoi.io/quick-start/) - Official initialization workflow
- [chezmoi encryption FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/encryption/) - Best practices
- [chezmoi .chezmoiignore reference](https://www.chezmoi.io/reference/special-files/chezmoiignore/) - Pattern specification
- [chezmoi apply command](https://www.chezmoi.io/reference/commands/apply/) - Dry-run and verification
- [chezmoi manage different file types](https://www.chezmoi.io/user-guide/manage-different-types-of-file/) - Naming conventions

### Secondary (MEDIUM confidence)
- [Yelp detect-secrets GitHub](https://github.com/Yelp/detect-secrets) - Pre-commit hook setup
- [gitleaks GitHub](https://github.com/gitleaks/gitleaks) - Alternative secret scanner
- [renemarc dotfiles .chezmoiignore example](https://github.com/renemarc/dotfiles/blob/master/.chezmoiignore) - Real-world patterns
- [GitGuardian best practices for .env files](https://blog.gitguardian.com/secure-your-secrets-with-env/) - Secret template patterns
- [dotfiles.github.io bootstrap examples](https://dotfiles.github.io/bootstrap/) - Community patterns

### Tertiary (LOW confidence)
- WebSearch: "chezmoi common mistakes pitfalls gotchas 2026" - Community knowledge, needs verification
- WebSearch: "dotfiles pre-commit hooks secret scanning 2026" - General patterns, verify with official docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official documentation, verified installation paths
- Architecture: HIGH - Official docs, real-world examples from active repos
- Pitfalls: MEDIUM - Mix of official docs and community experiences, common patterns observed
- Code examples: HIGH - Directly from official documentation and verified sources

**Research date:** 2026-02-10
**Valid until:** 2026-04-10 (60 days - chezmoi stable, age encryption mature)
