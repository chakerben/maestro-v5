# 02 - Official plugins

Recommend and install official Anthropic plugins matching the stack profile.

## Input

The stack profile from `01-detect-stack`.

## Output

The approved official plugins installed at the right scope, with a per-plugin
status report (installed / already present / skipped).

## Recommendation matrix

| Signal | Plugin | Scope | Why |
|---|---|---|---|
| Always | `security-guidance` | project | Per-edit vulnerability review (often already active by default — check first) |
| Always | `commit-commands` | user | Git commit/push/PR workflows |
| Always | `github` | user | Issues, PRs, branches without leaving the session |
| Always | `context7` | user | Up-to-date library docs, anti-hallucination |
| TypeScript detected | `typescript-lsp` | user | Real-time type diagnostics after every edit |
| Python detected | `pyright-lsp` | user | Real-time Python diagnostics |
| Frontend (Next.js/React) | `frontend-design` | user | Production-grade UI, anti-generic output |
| Expo / React Native | `expo` | project | Expo MCP integration |
| Figma in workflow (ask) | `figma` | user | Design-to-code |
| Prisma detected | `prisma` (partner) | project | Prisma tooling (often already installed — check) |
| Always (recommended) | `code-review` | user | Parallel review agents before commit — complements the checker |
| Always (recommended) | `pr-review-toolkit` | user | Specialized PR review passes |
| Developing Maestro itself (ask) | `skill-creator` | user | Scaffold and evaluate new skills |
| PDF generation or E2E testing (ask) | `playwright` | project | Browser automation — required route for Arabic RTL PDFs (maestro-mobile:02-pdf-rtl) and E2E |
| Multi-page crawl / doc extraction needed (ask) | `firecrawl` | user | Official plugin; keyless tier covers scrape/search. One page → WebFetch, no plugin |

## Vetted third-party (not official — install only skill-level, never their hooks)

| Signal | Tool | How | Why it passed vetting |
|---|---|---|---|
| Frontend with visual ambition (ask) | Impeccable (`npx impeccable install`) | skill + commands only; **decline its PostToolUse design hook** | Best generic design-taste skill; no RTL knowledge — `maestro-mobile:01-rtl-i18n` and `maestro-web:02-design-review` layer Arabic on top |
| Looking for a niche skill | skills.sh CLI (`npx skills find <kw>`) | discovery only | Run `references/third-party-vetting.md` on anything before `add` |

Everything else from the 2026-09 tooling audit (`docs/TOOLING-AUDIT-2026-09.md`)
is either absorbed into Maestro skills or rejected — do not re-suggest it.

## Process

1. Build the recommendation list from the matrix and the profile.
2. Check what is already installed: `claude plugin list` (or ask the user to
   run `/plugin` if the CLI is unavailable) — mark those "already present".
3. Present the remaining list with one-line justifications. **Wait for
   explicit approval** (all / subset / none).
4. Install each approved plugin:
   `claude plugin install <name>@claude-plugins-official --scope <scope>`
5. For LSP plugins, remind the user the language-server binary must be on
   PATH (e.g. `npm i -g typescript typescript-language-server`, or
   `pipx install pyright`) and verify with `which`.
6. Report per-plugin status.

## Test

- No plugin was installed without explicit approval in this session.
- Every installed plugin appears in `claude plugin list`.
- LSP binaries were verified or the user was clearly told what to install.
- No third-party hook was installed (`claude plugin list` + `.claude/settings.json` show ≤ 2 Maestro hooks and nothing else).
