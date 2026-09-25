# Contributing to Maestro 5

Maestro is an opinionated framework. Its constraints exist because the version
before it broke a working machine: v4 shipped 14 lifecycle hooks running
typecheck, tests and formatting after every edit, stacked with third-party
orchestrators — 33 GB of Node RAM on a 24 GB laptop, Jetsam kills, full
system freezes (13 July 2026). Everything below follows from that day.

Read [PHILOSOPHY.md](PHILOSOPHY.md) first. Its rules are not preferences.
When a change conflicts with a rule, the change loses.

## The gate

```bash
npm test
```

One command, nine checks, 219 cases — and it is the whole contract:

| Check | What it refuses |
|---|---|
| `check-versions.js` | version drift across the 9 manifests |
| `validate.js` | a hook declared anywhere but `hooks/hooks.json`; a hook without `timeout` or `${CLAUDE_PLUGIN_ROOT}`; a hook script that spawns processes or names test/format tooling; an agent without `role:`; a reviewer that can write; a skill with no `## Test`; a `!`cmd`` injection without `allowed-tools`; a `dependencies` field; a dependency cycle |
| `context-budget.js` | a description over 700 chars; the skill index over 11k; the router over 2k; a preloaded skill over 4k; an agent dispatch over 6k; a hook over 100 ms |
| `tests/bash-guard.test.sh` | 126 cases — blocked spellings, false positives, and the documented bypasses asserted as passing |
| `tests/memory-sync.test.sh` | 33 cases, each a reproduced corruption of a real CLAUDE.md |
| `tests/secret-scan.test.sh` | 24 cases on the commit-gate scanner |
| `tests/validate.test.sh` | 18 cases — the validator's own smuggling attempts |
| `tests/fleet-apply.test.sh` | 13 cases on the fleet script |
| `tests/install-shortcuts.test.sh` | 5 cases |

A red `npm test` is not a starting point for discussion. Also run
`npm run test:platform` (`claude plugin validate --strict`) when you touch
frontmatter — it follows the platform, which moves.

## Adding a skill

Two shapes, and `validate.js` enforces both (rule #4):

- **Router** — `SKILL.md` (contract + actions table) plus `actions/*.md`, each
  with its own `## Test`. For anything with more than one step or any
  persistent state.
- **Contract** — `SKILL.md` alone, carrying one `## Test` that says what a
  correct run leaves behind, or what it must never do.

The `description` is the routing decision, so it states **when** to use the
skill and when not to — never what the skill contains. Put the "what" in the
body. Keep `SKILL.md` under 5 500 characters; long material goes to
`references/` and is named from the contract so it loads only when needed.

State that depends on the repository (what is staged, the gate level, the last
tag) is **computed** with a `!`cmd`` injection, not recalled in prose
(rule 2b) — and the skill then declares `allowed-tools`.

## Adding an agent

Every agent declares `role: reviewer | builder | advisor`; the validator keys
on that, not on the file name. A reviewer carries both a `tools:` allowlist
and a `disallowedTools:` denylist — belt and braces, because the denylist
survives the platform adding new tools — plus a `maxTurns`. An agent that
writes and approves the same change does not ship (rule #5).

Preload with `skills:` only what the agent needs for **every** dispatch: it is
paid every time. Stack-specific standards load by `paths` or by explicit
invocation instead.

## What will be refused

- A third hook. Any third hook, for any reason (rule #1).
- Anything running typecheck, tests, a formatter, an LLM call or a daemon on a
  tool event (rule #2). That is the v4 crash.
- A `dependencies` field between Maestro plugins: the platform resolves it per
  scope, and a core-at-user-scope install breaks every dependent plugin
  (rule 7b, learned the hard way in 5.9.3).
- Re-implementing something an official Anthropic plugin already does
  (rule #8). Recommend theirs in `00-onboard` instead.
- A second framework layered on top — Superpowers, GSD and others are sources
  we absorb ideas from, never layers we stack (rule #7).

Before proposing any third-party skill, plugin or MCP, run it through
[`plugins/maestro-core/references/third-party-vetting.md`](plugins/maestro-core/references/third-party-vetting.md).
Five questions; the first "no" ends the evaluation.

## Commits, branches, releases

Conventional Commits, in English. Scopes follow the plugin or the area:
`core, dev, mobile, web, pm, quality, vcs, scripts, validate, docs`.

The main checkout stays on the default branch; every branch gets its own
worktree (`gwt new <branch>`, skill `maestro-vcs:03-worktree`). In a shared
directory, commit by explicit paths — never `git commit -a`, never
`git switch`.

Releases are the maintainer's: `./scripts/release.sh <version>` runs from
`main` only, gates on `npm test`, and pushes the tag that publishes. Do not
bump versions in a pull request.

## Writing style

Documentation and skill text are read by a model under budget. Say the thing,
once, with the number or the file path. No filler, no summary that repeats the
opening. `maestro-pm:04-writing` holds the rules and they apply to this
repository too.
