# Roadmap

Candidate improvements, prioritized.

## Prerequisite before anything below

**The first real feature through `/sdlc` has still never been executed.**
Every rule in this repo is theory until one feature has gone spec → plan →
implement → review → ship with its task folder as evidence. Do that first,
journal included, and file what broke as the next release's changelog.

## v5.3 candidates (after pilot feedback)

- ~~maestro-dev:04-debug~~ — **shipped in 5.8.0.**
- ~~maestro-dev:brainstorm~~ — **shipped as `maestro-dev:03-brainstorm`.**
  One question at a time, journal with a falsifiable stop condition, devil-advocate
  pass, routed handoff. See docs/BRAINSTORM-SUPERPOWERS.md for what was absorbed
  from Superpowers and what was deliberately refused.
- **maestro-vcs worktree support** — parallel feature work via git worktrees
  (v4 had worktree-parallel; reintroduce only if a real need appears).
- **skill-eval harness** — automated test cases validating that skill
  descriptions trigger on the right prompts (pattern from AIDD).

## v5.4 candidates

- **i18n of the framework itself** — AR/FR translations of user-facing skill
  outputs (SKILL.md stay English for model performance).
- ~~maestro-mobile:03-store-release~~ — **shipped in 5.8.0.**
- **maestro-web:03-seo-standards** — metadata, OG, sitemap, hreflang for
  multilingual sites (ar/fr/en alternates).

## Watching the official ecosystem (rule #8)

Re-check `claude-plugins-official` at each release: if Anthropic ships an
official equivalent of any Maestro skill, deprecate ours and recommend theirs
via 00-onboard. Current watchlist: memory/context management, RTL tooling,
release management.
