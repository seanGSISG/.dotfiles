---
phase: 06-migration-testing
plan: 01
subsystem: infra
tags: [chezmoi, age-encryption, ssh, bootstrap, secrets-management]

# Dependency graph
requires:
  - phase: 05.1-bootstrap-folders
    provides: "Bootstrap script with Claude Code installation"
provides:
  - "SSH keys age-encrypted in chezmoi repo"
  - "Age key interactive prompt in bootstrap"
  - "Automatic SSH key deployment via chezmoi apply"
affects: [06-migration-testing]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Age-encrypted SSH keys in chezmoi source"
    - "Interactive age key prompt before chezmoi apply"

key-files:
  created:
    - "private_dot_ssh/encrypted_private_idm-prod-key.age"
    - "private_dot_ssh/idm-prod-key.pub"
    - "private_dot_ssh/authorized_keys"
    - "private_dot_ssh/private_known_hosts"
  modified:
    - "bootstrap.sh"

key-decisions:
  - "SSH keys stored age-encrypted in chezmoi repo for automatic deployment"
  - "Age key prompt runs before chezmoi apply to ensure decryption works"
  - "Remove interactive SSH copy function (replaced by chezmoi-managed keys)"
  - "Split setup_chezmoi() into install_chezmoi() + setup_age_key() + apply_chezmoi()"

patterns-established:
  - "Age key validation: must start with AGE-SECRET-KEY-"
  - "Age key stored at ~/.config/age/keys.txt with 600 permissions"
  - "Bootstrap execution order: install chezmoi → prompt age key → apply configs"

# Metrics
duration: 2min
completed: 2026-02-12
---

# Phase 06 Plan 01: SSH Keys & Age Prompt Summary

**SSH keys age-encrypted in chezmoi repo with interactive age key prompt in bootstrap, eliminating manual SCP step**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-12T09:14:31Z
- **Completed:** 2026-02-12T09:17:23Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- SSH private key (idm-prod-key) added to chezmoi with age encryption
- SSH public key, authorized_keys, known_hosts tracked unencrypted
- Bootstrap prompts for age key paste before chezmoi apply
- Interactive SSH copy function removed (keys deploy via chezmoi now)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add SSH keys to chezmoi repo with age encryption** - `15d46f6` (feat)
2. **Task 2: Add age key paste prompt to bootstrap.sh** - `63fd903` (feat)

## Files Created/Modified
- `private_dot_ssh/encrypted_private_idm-prod-key.age` - Age-encrypted SSH private key
- `private_dot_ssh/idm-prod-key.pub` - SSH public key (unencrypted)
- `private_dot_ssh/authorized_keys` - SSH authorized_keys (unencrypted)
- `private_dot_ssh/private_known_hosts` - SSH known_hosts (unencrypted)
- `bootstrap.sh` - Added setup_age_key() function, split chezmoi setup, removed SSH copy function

## Decisions Made
- Split `setup_chezmoi()` into three functions (`install_chezmoi`, `setup_age_key`, `apply_chezmoi`) for clear separation of concerns
- Age key prompt is skippable — user can add key later and re-run `chezmoi apply`
- Validate age key format (must start with AGE-SECRET-KEY-) to catch paste errors early
- Update post-install checklist to reflect that age key prompt happens during bootstrap

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - both tasks completed without issues. Chezmoi's age integration worked as expected.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Bootstrap script is ready for testing on a fresh machine. SSH keys will deploy automatically when:
1. User pastes age key during bootstrap (or adds it manually later)
2. `chezmoi apply` runs (happens automatically in bootstrap after age key setup)

No blockers. Ready to proceed with bootstrap testing on target machine.

---
*Phase: 06-migration-testing*
*Completed: 2026-02-12*
