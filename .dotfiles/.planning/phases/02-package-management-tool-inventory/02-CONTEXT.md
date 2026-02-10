# Phase 2: Package Management & Tool Inventory - Context

**Gathered:** 2026-02-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Generate declarative package lists documenting all system packages, uv-managed tools, and direct binary installs needed for environment reproduction. Lists are committed to chezmoi repo and consumed by the bootstrap script (Phase 5). This phase inventories and documents — it does not build the installer.

</domain>

<decisions>
## Implementation Decisions

### Package categorization
- Split into separate files by install method: apt-packages.txt, uv-tools.txt, binary-installs.txt
- Within apt-packages.txt, group packages by purpose (build-tools, shell-utils, dev-libs, etc.) with section headers
- All packages installed regardless of group — no tiers or optional sets
- PPA/custom-repo packages stay in apt-packages.txt, annotated with repo source in comments

### List format & annotation
- Plain text (.txt) format — one package per line, # comments
- Names + minimum versions where it matters (e.g., git>=2.40), no version pin otherwise
- Every package gets a comment explaining why it's needed
- binary-installs.txt entries include: name, source URL, version — bootstrap script owns install logic
- Post-install requirements annotated in comments (e.g., "# post-install: shell integration via eval")
- Auth-required tools (gh, claude) annotated with "# auth: manual" — bootstrap prints post-install checklist

### Discovery approach
- Auto-generate from current system, then curate
- For apt: use apt-mark showmanual (manually installed only, not transitive deps)
- For uv: auto-discover from system (uv tool list), then cross-reference with known tools (basedpyright, pre-commit, virtualenv, just)
- Curation happens within Phase 2 — review and trim lists before committing

### Non-apt installs
- Install method chosen case-by-case per tool (some use official install scripts, some use GitHub release binaries)
- Document specific Node.js LTS version and Bun version in the lists (not just "install fnm/bun")
- Post-install setup requirements noted in list annotations so Phase 5 knows what to automate

### Claude's Discretion
- Exact section groupings within apt-packages.txt
- Format details (column alignment, comment style)
- Which tools get install scripts vs GitHub binaries
- Order of entries within sections

</decisions>

<specifics>
## Specific Ideas

- Goal is zero manual post-install steps — everything automated by bootstrap, auth-required tools collected into a printed checklist at the end
- Lists should be easily parseable by bash (plain text, one per line)
- The package lists are the "bill of materials" — bootstrap script is the "assembly instructions"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-package-management-tool-inventory*
*Context gathered: 2026-02-10*
