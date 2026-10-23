# Platform watch — what Claude Code now does that Maestro used to do

PHILOSOPHY rule #8 applied over time: each row is a capability Maestro built
or documented before the platform had it, the Claude Code version that made
it native, and what Maestro did about it. `04-doctor` reads this table at
every run and compares it to the installed CLI: a row whose `since` is below
the installed version and whose Maestro side still exists is a 🟡 "the
platform does this now — retire ours".

Keep the table short and dated; delete a row once Maestro's side is gone.
The source for new rows is the Claude Code changelog
(https://code.claude.com/docs/en/changelog) read at each Maestro release —
not a TikTok list.

| Capability | Native since | Maestro side | Status |
|---|---|---|---|
| Executables on the Bash PATH while a plugin is enabled (`bin/`) | 2.1.2xx | `gwt` symlinked by `install-shortcuts.sh` | retired 5.15.0 — `gwt` is in `maestro-vcs/bin/` |
| Deny a subagent dispatch that names a model (`Agent(model:*)`) | 2.1.2xx | "a pin is not overridable" (prose) | retired 5.15.0 — the deny rule is the pin |
| Plugin `userConfig` substituted in skill text (`${user_config.KEY}`) | 2.1.2xx | env var read in a Bash injection | retired 5.15.0 |
| Skills as the successor of `~/.claude/commands/*.md` | 2.1.x | `install-shortcuts.sh` writes command files | **open** — move the shortcuts to `~/.claude/skills/<name>/SKILL.md` |
| `context: fork` for a skill | 2.1.x | audits read the whole codebase in the session | retired 5.15.0 — the three audits fork |
| Per-tool permission classifier in auto mode | 2.1.x | `bash-guard.js` accident guard | **keep** — bash-guard is cheaper and fail-open; re-check when the classifier is on by default |
| Native plugin `dependencies` | 2.1.x | "when installed" guards in skill text | **keep** — rule 7b: the field broke the user/project scope split (5.9.3) |
