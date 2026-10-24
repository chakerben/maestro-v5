# Roadmap

Candidate improvements, prioritized.

## Prerequisite — done (2026-10-24)

The first real feature went through `/sdlc auto` end to end on a throwaway
Expo + Arabic project: `docs/PILOT-5.15.0.md` (8 commits, opus review found
two money bugs, 11 pipeline breaks fixed in 5.15.0). **Next measurement:**
the same client feature done twice — through the pipeline and by hand with
only the mobile standards — on Injaz Owner or Dhiyafa, with a device
screenshot. That comparison decides how much of maestro-dev stays.

## v5.3 candidates (after pilot feedback)

- ~~maestro-dev:04-debug~~ — **shipped in 5.8.0.**
- ~~maestro-dev:brainstorm~~ — **shipped as `maestro-dev:03-brainstorm`.**
  One question at a time, journal with a falsifiable stop condition, devil-advocate
  pass, routed handoff. See docs/BRAINSTORM-SUPERPOWERS.md for what was absorbed
  from Superpowers and what was deliberately refused.
- ~~maestro-vcs worktree support~~ — **shipped in 5.8.0** as
  `maestro-vcs:03-worktree` + `scripts/gwt`. Still open: ship `gwt` in the
  plugin's `bin/` (on the Bash PATH while enabled) instead of a symlink into
  the clone `install-shortcuts.sh` ran from (audit 5.14.0 2.7).
- **skill-eval harness** — automated test cases validating that skill
  descriptions trigger on the right prompts (pattern from AIDD).

## Next (platform-watch rows marked open)

- **Shortcuts as skills** — `install-shortcuts.sh` writes `~/.claude/commands/*.md`,
  the older format; move them to `~/.claude/skills/<name>/SKILL.md`
  (`platform-watch.md`).

## v5.4 candidates

- **i18n of the framework itself** — AR/FR translations of user-facing skill
  outputs (SKILL.md stay English for model performance).
- ~~maestro-mobile:03-store-release~~ — **shipped in 5.8.0.**
- **maestro-web:03-seo-standards** — metadata, OG, sitemap, hreflang for
  multilingual sites (ar/fr/en alternates).

## Later — tested on one project before becoming framework

- **Strix** (open-source dynamic pentest agent, Docker + own LLM key): a
  `maestro-quality:03-pentest` skill that runs it as a CLI against a staging
  URL with a test Clerk session, pre-launch only. Not a hook, not an MCP.
- **Motion AI Kit** only if a project standardises on Motion over GSAP.
- **Firecrawl** official plugin the first time a real multi-page crawl is needed.
- `context: fork` on the audit skills; `isolation: worktree` on the executor.

## Watching the official ecosystem (rule #8)

Re-check `claude-plugins-official` at each release: if Anthropic ships an
official equivalent of any Maestro skill, deprecate ours and recommend theirs
via 00-onboard. Current watchlist: memory/context management, RTL tooling,
release management.
