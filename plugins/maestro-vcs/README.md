# maestro-vcs

Delivery, layered on the official commit-commands plugin.

## Skills

- `00-commit` — **the quality checkpoint**: secrets scan (never skippable,
  15+ patterns), configurable gate levels, conventional message, recorded
  bypasses. Everything v4 enforced at runtime runs here, once, at the right
  moment.
- `01-pull-request` — structured PR from the task folder. Never merges.
- `02-release` — semver from conventional commits, changelog, annotated tag.
- `03-worktree` — one branch, one worktree (`gwt`, shipped in `bin/` and on
  the Bash PATH while the plugin is enabled): the main checkout stays on
  the default branch, so concurrent sessions stop moving each other's branch; a real
  dependency install replaces the `node_modules` link in mobile and bundler
  projects
- `04-deploy-verify` — "merged" is not "live": deployment identified by
  commit sha, smoke call, invariant, deploy log; migrations as a guarded
  step of the production build only; cherry-pick releases with a mandatory
  schema-versus-migrations diff before and after
