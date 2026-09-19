# 04 - Scaffold

Create the Maestro memory bank and wire it into CLAUDE.md.

## Input

The project root and the stack profile.

## Output

`maestro_docs/` structure created, CLAUDE.md carrying a `<maestro_memory>`
block (the SessionStart hook keeps it in sync afterwards).

## Process

1. Create the structure (skip anything that exists):

```
maestro_docs/
├── memory/
│   ├── project-brief.md      # what the product is, for whom, core goals
│   ├── tech-decisions.md     # stack choices and the WHY
│   ├── patterns.md           # project-specific conventions and gotchas
│   └── internal/             # read-on-demand deep docs
├── specs/                    # PRDs and specs (maestro-pm writes here)
└── tasks/                    # feature folders <yyyy_mm_dd>_<slug>/ (maestro-dev writes here)
```

2. Pre-fill `project-brief.md` and `tech-decisions.md` from the stack profile
   — short bullets, facts only, no placeholders left empty. Ask the user for
   the one-paragraph product description if it cannot be inferred.
3. If `CLAUDE.md` does not exist, create a minimal one (project name, stack
   one-liner). Never overwrite an existing CLAUDE.md.
3b. Write the `<maestro_routing>` block in CLAUDE.md: the tags around the
   verbatim content of `${CLAUDE_PLUGIN_ROOT}/references/routing.md` (never a
   hand-typed copy — that file is the single source). From the next session
   start, the memory-sync hook keeps this block current on every release, so
   plain prompts always route to the current skill set without anyone typing a
   skill name.

3c. Pre-fill `patterns.md` with the concurrency convention — a repository is
   routinely open in several sessions at once, and the rule has to be readable
   before the first commit, not after the first collision:

```
## Sessions concurrentes — un worktree par branche
Le répertoire principal reste sur la branche par défaut ; toute branche vit
dans son propre worktree (`gwt new <branche>`, skill maestro-vcs:03-worktree).
Jamais de `git switch` ni de `git commit -a` dans un répertoire partagé —
commiter par chemins. <port de dev à décaler / services partagés du projet>
```
4. Run the memory-sync logic once so the `<maestro_memory>` block appears
   immediately (the hook will maintain it from now on).
4b. Merge the canonical `permissions.deny` entries into the project's
   `.claude/settings.json` (create the file with `{}` if absent; parse it,
   never regex it; keep every other key and every existing deny entry; add
   only the entries below that are missing; write back pretty-printed). The
   `bash-guard` hook is the accident guard — this list is the enforced layer
   the platform applies, and nothing else installs it:

```
Bash(rm -rf /)        Bash(rm -rf /*)       Bash(rm -rf ~)      Bash(rm -rf ~/*)
Bash(rm -rf $HOME)    Bash(curl * | bash)   Bash(curl * | sh)
Bash(wget * | bash)   Bash(wget * | sh)     Bash(git push --force*)  Bash(git push -f*)
```

   Show the diff before writing. If `.claude/settings.json` is malformed
   JSON, stop and report — never overwrite a file you could not parse.
4c. Session model. If `.claude/settings.json` has no top-level `"model"`
   key, ask once: write `"model": "sonnet"`? — "Maestro's ladder assumes
   sonnet as the session default; think-steps pin fable, critical steps
   opus" (`${CLAUDE_PLUGIN_ROOT}/references/model-policy.md`). Yes → add
   the key (same parse-merge-write as 4b). An existing value, whatever it
   is, is never overwritten — report it and move on.
5. Report created vs skipped files.

## Test

- `maestro_docs/memory/project-brief.md` exists and contains real content.
- `CLAUDE.md` contains a `<maestro_memory>` block referencing the memory files.
- `.claude/settings.json` parses, its `permissions.deny` contains all 11
  canonical entries, and every key/entry that was there before is still there.
- `.claude/settings.json` `model` is `sonnet` when the user accepted 4c, or
  still its previous value when one existed — never replaced.
- Re-running this action changes nothing (idempotent) — including
  `.claude/settings.json`, byte for byte.
