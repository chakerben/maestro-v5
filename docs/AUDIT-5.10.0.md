# Audit 5.10.0 — independent deep pass (2026-09-19)

Every file read, `npm test` run, each defect reproduced before being listed.
Closed in 5.11.0 unless marked otherwise. Severity: H = could not work as
written or unsafe; M = wrong or inconsistent; L = cosmetic.

| # | Sev | Where | Finding | Fix |
|---|---|---|---|---|
| 1 | H | dev `01-plan`, `02-implement`, `03-brainstorm`, `04-debug`, `01-frame` | `../references/` resolved to `skills/references/` (absent) | `${CLAUDE_PLUGIN_ROOT}/references/…` |
| 2 | H | dev `04-review.md:9` vs `checker.md` | checker told to write `review.md` without Write | checker returns, orchestrator writes |
| 3 | H | dev `02-execute.md:19` | `${CLAUDE_PLUGIN_ROOT}/../maestro-vcs` does not exist in the cache | local mirror of `secret-patterns.md`, drift-checked |
| 4 | H | vcs `secret-scan.sh:82-94` | 87 s / 3 000 lines (3 forks × 15 patterns per line) | one grep pass, 0.03 s; perf test |
| 5 | H | quality `bash-guard.js:14-16` | `permissions.deny` promised, written nowhere | scaffold writes it, doctor checks it |
| 6 | H | vcs `secret-patterns.md:29` | unquoted `KEY=value` never caught | generic pattern accepts unquoted; placeholder counter-list |
| 7 | H | `install-shortcuts.sh:47` | `$ARGUMENTS` under `set -u` → 0 files written | escaped; smoke test in `npm test` |
| 8 | H | `validate.js:204-211` | rule #2 scanner blind after a backtick in a regex literal | JS scanner; negative tests |
| 9 | H | mobile `flutter-rtl.md:32-34` | `DateFormat` does not do Umm al-Qura | `hijri` package |
| 10 | H | web `00`/`01` vs mobile `00` `paths` | Next rules loaded on Expo screens, RN rules never | App Router conventions / `app/**/*.tsx` |
| 11 | M+ | mobile `03-store-release` | `disable-model-invocation` hid it; triggers dead | invocable + routed |
| 12 | M+ | mobile `checklist.md` | Apple SDK min, Play targetSdk, 16 KB, ATT, deletion URL missing | added (verifiable wording) |
| 13 | M+ | mobile `02-pdf-rtl` | no ZATCA | `references/zatca.md` |
| 14 | M | core doctor vs onboard | official plugin hooks flagged red | three buckets |
| 15 | M | dev `00-sdlc:16` vs pm `02-specs` | two "spec" files, contradictory switch rule | one rule, one link |
| 16 | M | dev `m-i18n-checker` | "wish" dependency, never spawned | mini-checklist, spawned on `ar` |
| 17 | M | dev `executor.md` | inherits Task; Flutter → RN standards | denylist; Flutter → `04-flutter-standards` |
| 18 | M | mobile `flutter-rtl.md:29-31` | `Transform.flip` double-flips Material icons | corrected |
| 19 | M | vcs `00-commit` vs `01-pull-request` | two variables for one script path | `${CLAUDE_PLUGIN_ROOT}` |
| 20 | M | vcs `secret-scan.sh:86,97,72` | `gate:allow` `//` only; no-newline off-by-one; quoted paths | fixed + tests |
| 21 | M | quality `bash-guard.js` | blocks `git commit -m "…chmod 777…"`; misses `/dev/vd*`, `\| python` | quote-blanking; classes widened |
| 22 | M | quality `00-quality-gate` | `run` promised a scan it could not run | delegates to `00-commit` or says so |
| 23 | M | `release.sh` | `git add -A`; global `gh auth switch` | explicit list; opt-in |
| 24 | M | `prune-installed.sh` | `pgrep -x claude` misses node; schema guessed | widened; schema guard |
| 25 | M | core design | `CLAUDE.md` assumed unversioned, unsaid | README documents it |
| 26 | M | web `00:10-11` | `middleware.ts` only | `proxy.ts` (Next 16) |
| 27 | M | mobile `00`, `01` | New Architecture absent; `supportsRtl` absent | added |
| 28 | M | pm `02-specs` | Prisma/Zod hardcoded | stack-agnostic |
| 29 | — | dev/mobile/pm frontmatter | `effort:`/`arguments:` suspected undocumented | **withdrawn**: both are documented; `validate.js` whitelist follows the docs |
| 30 | M | dev `cognitive-protocols.md:3` | "binding" but loaded by no agent | `06-protocols` preloaded by all five |

Three cross-cutting patterns: the plugin-cache layout was assumed rather than
known (#3, #19); enforcement claims exceeded enforcement (#5, #8, #22, #30);
and `npm test` could not see any of #1–#3, #7, #10 — the first real `/sdlc`
run (ROADMAP prerequisite) would have.
