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
3b. Say the trade once, here, where the user decides: the SessionStart hook
   rewrites the `<maestro_memory>` and `<maestro_routing>` blocks in
   CLAUDE.md whenever the memory bank or the marketplace's `routing.md`
   changes. In a project that versions CLAUDE.md (the default), every
   Maestro release therefore dirties the file at the next session start and
   wants a `chore: sync CLAUDE.md` commit; a project that ignores CLAUDE.md
   avoids the churn but must copy it into worktrees (`gwt` does). Record the
   choice in `patterns.md`.

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
4. Run the hook once, `node ${CLAUDE_PLUGIN_ROOT}/hooks/memory-sync.js`, so
   both blocks (`<maestro_memory>`, `<maestro_routing>` with its hash line)
   appear immediately in the exact shape the hook expects — tags alone on
   their line; a hand-typed block with a tag inline becomes a stray tag the
   hook refuses to touch forever. Never write these blocks by hand.
4b. The canonical `permissions.deny` entries in the project's
   `.claude/settings.json`. **`.claude/` is a platform-protected path**: a
   write there prompts the human even in `acceptEdits`, and is refused
   headless (`claude -p`, `fleet-apply --scaffold`, `00-sdlc auto`) — the
   first pilot proved it. So this step is a merge the human runs, never a
   silent write: print the one-liner below and, when a human is present,
   offer the Edit (they answer the prompt — "allow Claude to edit its own
   settings for this session" is theirs to say). Headless: print it and
   move on; `04-doctor` reports the gap until it is closed.

```bash
maestro-settings .      # maestro-quality bin/, on the PATH while that plugin is enabled — or, from the marketplace checkout: scripts/fleet-apply.sh --settings <project>
```

   Either path parses the file, never regexes it; keeps every other key and
   every existing entry (except the four dead pipe rules, named); adds only
   what is missing; writes back pretty-printed. The `bash-guard` hook is the
   accident guard — this list is the enforced layer the platform applies:

```
Bash(rm -rf /)        Bash(rm -rf /*)       Bash(rm -rf ~)      Bash(rm -rf ~/*)
Bash(rm -rf $HOME)    Bash(git push --force)  Bash(git push --force *)
Bash(git push -f)     Bash(git push -f *)
Agent(model:*)
```

   What is NOT in the list, and why: a rule with a pipe in it
   (`Bash(curl * | bash)`) never matches — the platform splits a compound
   command at `|`, `&&`, `;` and matches each subcommand on its own, so no
   subcommand ever contains the pipe. The four former pipe entries
   (`curl`/`wget` × `bash`/`sh`) are the one exception to "keep every
   existing entry": remove them, naming each, as `fleet-apply.sh --settings`
   does. Piping remote content into a shell is bash-guard's job (rule 3 of
   `bash-guard.js`), and that layer is an accident guard, not a boundary;
   say so when asked. `--force*` used to match `--force-with-lease`, the
   form the framework recommends; an existing `--force*` is the user's and
   stays — `04-doctor` reports it.

   `Agent(model:*)` is what makes the model ladder real: Claude Code resolves
   a subagent's model from the `model` parameter of the dispatch **before**
   the agent's frontmatter, so without this rule the orchestrator could run
   `checker-critical` on sonnet. With it, a dispatch that names a model is
   refused and the frontmatter pin is the only path (model-policy.md).

   Show the diff before writing. If `.claude/settings.json` is malformed
   JSON, stop and report — never overwrite a file you could not parse.
4c. Session model `"model": "sonnet"` — same file, same rule as 4b (the
   human runs the merge; `maestro-settings` writes it when absent, never
   overwrites an existing value). Why sonnet: the session orchestrates
   (dispatch, gates, commits, docs); the agents pin their own tier
   (`${CLAUDE_PLUGIN_ROOT}/references/model-policy.md`).
4d. Merge into `.gitignore` (create it if absent; append only what is
   missing, one entry per line): `.claude-md.maestro.lock` and
   `CLAUDE.md.*.tmp` — the hook's lock and atomic-write temp files. Show the
   diff before writing.
4e. **Architecture the tool enforces** (skip when a boundary config already
   exists — never overwrite one): node/Expo/Next → copy
   `${CLAUDE_PLUGIN_ROOT}/skills/00-onboard/assets/architecture/dependency-cruiser.node.cjs`
   to `.dependency-cruiser.cjs` and add `dependency-cruiser` to
   devDependencies (install with the lockfile's runner; `typescript` must
   be a devDependency too — depcruise cannot read `.ts/.tsx` without it);
   Flutter → copy
   `import_lint.flutter.yaml` into `analysis_options.yaml` (merge under
   `import_lint:`) and add `import_lint` to `dev_dependencies`. Create the
   four layer folders (`domain/ application/ infrastructure/` + the stack's
   UI folder) with a one-line README each when they do not exist, from
   `assets/architecture/README.md`. From now on `maestro-check boundaries`
   is red when `domain/` imports a framework or `ui/` imports an adapter.
   A project with its own architecture keeps it: record the deviation in
   `tech-decisions.md` and edit the config instead of deleting it.
5. Report created vs skipped files.

## Test

- `maestro_docs/memory/project-brief.md` exists and contains real content.
- `CLAUDE.md` contains one `<maestro_memory>` block referencing the memory
  files and one `<maestro_routing>` block whose second line is the hook's
  `<!-- maestro-routing <hash> … -->` comment; each tag sits alone on its line.
- `.gitignore` lists `.claude-md.maestro.lock` and `CLAUDE.md.*.tmp`.
- A boundary config exists (`.dependency-cruiser.cjs` or `import_lint` in
  `analysis_options.yaml`), its linter is a dev dependency, and
  `maestro-check --list` shows `boundaries` running, not skipped.
- The report prints the `maestro-settings` / `fleet-apply --settings`
  one-liner whenever `.claude/settings.json` lacks a canonical entry or the
  model key, and never claims to have written that file headless.
- After the human ran it: the file parses, `permissions.deny` contains all
  10 canonical entries, every pre-existing key/entry is still there (minus
  the four named dead pipe rules), `model` is `sonnet` or its previous value.
- Re-running this action changes nothing (idempotent) — including
  `.claude/settings.json` and `.gitignore`, byte for byte.
