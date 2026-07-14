# Roadmap

Candidate improvements, prioritized. Nothing here blocks the pilot rollout.

## v5.3 candidates (after pilot feedback)

- **maestro-dev:03-debug** — systematic root-cause debugging skill
  (reproduce → smallest failing case → cause → fix → regression test).
  Today the executor + expert postures cover it implicitly.
- **maestro-dev:04-brainstorm** — Socratic one-question-at-a-time ideation
  (pattern absorbed from Superpowers; formalize as a skill if pilots miss it).
- **maestro-vcs worktree support** — parallel feature work via git worktrees
  (v4 had worktree-parallel; reintroduce only if a real need appears).
- **skill-eval harness** — automated test cases validating that skill
  descriptions trigger on the right prompts (pattern from AIDD).

## v5.4 candidates

- **i18n of the framework itself** — AR/FR translations of user-facing skill
  outputs (SKILL.md stay English for model performance).
- **maestro-mobile:03-store-release** — App Store / Play Store submission
  checklist skill (KSA specifics: age ratings, data disclosure).
- **maestro-web:03-seo-standards** — metadata, OG, sitemap, hreflang for
  multilingual sites (ar/fr/en alternates).

## Watching the official ecosystem (rule #8)

Re-check `claude-plugins-official` at each release: if Anthropic ships an
official equivalent of any Maestro skill, deprecate ours and recommend theirs
via 00-onboard. Current watchlist: memory/context management, RTL tooling,
release management.
