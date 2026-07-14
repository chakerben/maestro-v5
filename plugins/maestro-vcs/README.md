# maestro-vcs

Delivery, layered on the official commit-commands plugin.

## Skills

- `00-commit` — **the quality checkpoint**: secrets scan (never skippable,
  15+ patterns), configurable gate levels, conventional message, recorded
  bypasses. Everything v4 enforced at runtime runs here, once, at the right
  moment.
- `01-pull-request` — structured PR from the task folder. Never merges.
- `02-release` — semver from conventional commits, changelog, annotated tag.
