---
phase: 01-repository-foundation-safety
plan: 02
subsystem: security-infrastructure
status: complete
completed: 2026-02-10
duration: 3 min

requires:
  - 01-01  # chezmoi and age installed, encryption configured

provides:
  - safety-guardrails  # .gitignore, .chezmoiignore, pre-commit hooks active
  - encrypted-secrets  # age-encrypted .secrets.env managed by chezmoi
  - clean-configs  # inline secrets removed from shell configs

affects:
  - 01-03  # initial commit will include all safety files
  - all-future-phases  # pre-commit hooks protect all commits

tech-stack:
  added:
    - detect-secrets (v1.5.0, via pipx)
    - pre-commit hooks
  patterns:
    - age-encrypted secret files in chezmoi
    - guarded sourcing of secrets in shell configs
    - .chezmoiignore for repo-only files

key-files:
  created:
    - ~/.local/share/chezmoi/.gitignore
    - ~/.local/share/chezmoi/.chezmoiignore
    - ~/.local/share/chezmoi/.pre-commit-config.yaml
    - ~/.local/share/chezmoi/.secrets.baseline
    - ~/.local/share/chezmoi/.secrets.env.example
    - ~/.local/share/chezmoi/encrypted_dot_secrets.env.age
    - ~/.secrets.env (target state, decrypted by chezmoi)
  modified:
    - ~/.bashrc (removed inline secrets, added source line)
    - ~/.zshrc (removed inline secrets, added source line)
    - ~/.profile (removed inline secrets, added source line)

decisions:
  - id: SEC-01
    decision: "Use detect-secrets with baseline workflow for pre-commit scanning"
    rationale: "Fewer false positives than alternatives, baseline allows marking encrypted files as non-secrets"
    date: 2026-02-10
  - id: SEC-02
    decision: "Use pipx to install detect-secrets (not pip)"
    rationale: "Environment is externally-managed, pipx creates isolated virtual environments"
    date: 2026-02-10
  - id: SEC-03
    decision: "Extract all inline secrets into single ~/.secrets.env file"
    rationale: "Centralized secret management, encrypted once, sourced by all shells"
    date: 2026-02-10

tags: [security, chezmoi, secrets, pre-commit, git, safety]
---

# Phase 01 Plan 02: Safety Guardrails & Secret Extraction Summary

**One-liner:** Pre-commit secret scanning active, three secrets (GITHUB_PERSONAL_ACCESS_TOKEN, EXA_API_KEY, GREPTILE_API_KEY) extracted from shell configs into age-encrypted .secrets.env, inline exports removed.

## What Was Built

### Safety Guardrails (Task 1)

Created comprehensive safety infrastructure in the chezmoi source repository:

1. **`.gitignore`** - Blocks age encryption keys (key.txt, *.age.key) and local state from being committed
2. **`.chezmoiignore`** - Prevents repo-only files (README, .planning/, .github/) from being applied to home directory
3. **`.pre-commit-config.yaml`** - Configured detect-secrets v1.5.0 with baseline workflow
4. **`.secrets.baseline`** - Generated baseline marking encrypted files as non-secrets
5. **Pre-commit hooks** - Installed and active in chezmoi git repo

### Secret Extraction (Task 2)

Extracted and encrypted secrets from shell configs:

1. **Identified secrets:**
   - GITHUB_PERSONAL_ACCESS_TOKEN (was in .bashrc line 201, .profile line 31)
   - EXA_API_KEY (was in .bashrc line 185, .zshrc line 119)
   - GREPTILE_API_KEY (was in .bashrc line 186)

2. **Created `~/.secrets.env`** with real values, sourced by all shell configs

3. **Added to chezmoi with encryption** → `encrypted_dot_secrets.env.age`

4. **Removed inline exports** from ~/.bashrc, ~/.zshrc, and ~/.profile (SEC-01 satisfied)

5. **Added guarded source lines** to each config: `[ -f ~/.secrets.env ] && source ~/.secrets.env`

6. **Created `.secrets.env.example`** with placeholder values for documentation

7. **Verified round-trip:** Secrets remain available at runtime via sourcing

## Tasks Completed

| Task | Name | Duration | Status |
|------|------|----------|--------|
| 1 | Configure safety guardrails (.gitignore, .chezmoiignore, pre-commit hooks) | 1 min | ✓ Complete |
| 2 | Extract secrets, remove inline exports, and create encrypted .secrets.env | 2 min | ✓ Complete |

**Total execution time:** 3 minutes

## Technical Achievements

### Security Posture

- **Pre-commit protection:** All commits now scanned for secrets before they reach git
- **Key protection:** .gitignore ensures age key never committed
- **Encrypted storage:** Secrets stored only in age-encrypted form in repo
- **Clean configs:** No plaintext secrets in shell config files (SEC-01 satisfied)

### Chezmoi Integration

- **Age encryption working:** Round-trip encrypt/decrypt verified
- **Target state correct:** `chezmoi apply` would create ~/.secrets.env from encrypted source
- **Repo-only files:** .chezmoiignore prevents documentation from polluting home directory

### Runtime Behavior

- **Secrets available:** All three secrets accessible after `source ~/.bashrc`
- **Guarded sourcing:** `[ -f ~/.secrets.env ] &&` prevents errors if file missing
- **Multi-shell support:** .bashrc, .zshrc, and .profile all source the same secrets file

## Verification Results

All verification criteria passed:

1. ✓ .gitignore contains "key.txt"
2. ✓ .chezmoiignore contains "README.md" and ".planning/"
3. ✓ .pre-commit-config.yaml contains "detect-secrets"
4. ✓ .secrets.baseline exists
5. ✓ pre-commit hooks pass on all files
6. ✓ encrypted_dot_secrets.env.age exists and is encrypted (not plaintext)
7. ✓ `chezmoi cat ~/.secrets.env` outputs plaintext with all three secrets
8. ✓ .secrets.env.example contains placeholders, NOT real secrets
9. ✓ Zero inline exports remain in .bashrc (GITHUB_PERSONAL_ACCESS_TOKEN, EXA_API_KEY, GREPTILE_API_KEY all removed)
10. ✓ Zero inline exports remain in .zshrc (EXA_API_KEY removed)
11. ✓ Zero inline exports remain in .profile (GITHUB_PERSONAL_ACCESS_TOKEN removed)
12. ✓ All three shell configs source ~/.secrets.env with guarded syntax

## Files in Chezmoi Repo

New untracked files ready for commit in Plan 01-03:

```
~/.local/share/chezmoi/
├── .gitignore                         # Safety: blocks keys
├── .chezmoiignore                     # Safety: prevents repo-only files from applying
├── .pre-commit-config.yaml            # Safety: secret scanning
├── .secrets.baseline                  # Safety: detect-secrets baseline
├── .secrets.env.example               # Documentation: placeholder values
└── encrypted_dot_secrets.env.age      # Encrypted: real secrets
```

## Decisions Made

**SEC-01: Extract inline secrets into centralized encrypted file**
- Before: Secrets scattered across .bashrc, .zshrc, .profile as plaintext exports
- After: Single ~/.secrets.env encrypted with age, sourced by all shells
- Rationale: Centralized management, encrypted storage, easier to rotate/update

**SEC-02: Use pipx for detect-secrets installation**
- Tried: `pip3 install --user detect-secrets` (failed: externally-managed environment)
- Solution: `pipx install detect-secrets` (creates isolated virtualenv)
- Outcome: detect-secrets v1.5.0 installed globally at ~/.local/bin/

**SEC-03: Use detect-secrets baseline workflow**
- Alternative: Run detect-secrets without baseline (many false positives on encrypted files)
- Chosen: Generate baseline with `detect-secrets scan > .secrets.baseline`
- Benefit: Encrypted .age files marked as known non-secrets, no false positives

## Deviations from Plan

None - plan executed exactly as written.

## Next Phase Readiness

**Ready for Plan 01-03 (Initial Commit & Push):**
- ✓ All safety files created and tested
- ✓ Pre-commit hooks active and passing
- ✓ Secrets extracted and encrypted
- ✓ Shell configs cleaned (inline secrets removed)
- ✓ Git status shows 6 untracked files ready for initial commit

**Blockers:** None

**Concerns:** None

## Links

- **Plan:** .planning/phases/01-repository-foundation-safety/01-02-PLAN.md
- **Previous:** [01-01-SUMMARY.md](./01-01-SUMMARY.md) - chezmoi and age installation
- **Next:** Plan 01-03 - Initial commit and push to remote

---

*Summary created: 2026-02-10*
*Execution: Autonomous (no checkpoints)*
