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
3b. Upsert a `<maestro_routing>` block in CLAUDE.md (idempotent — replace if
   present):

```
<maestro_routing>
Maestro is installed. Route by intent:
- Feature end-to-end -> skill maestro-dev:00-sdlc (say "auto" for unattended)
- Plan only -> maestro-dev:01-plan · Build a plan -> maestro-dev:02-implement
- Independent review -> agent checker · Challenge a plan -> agent m-devil-advocate
- Architecture/DB design -> agent m-architect
- Memory stale -> maestro-core:01-memory · Context bloated -> maestro-core:02-gardener
- Install broken / after migration -> maestro-core:04-doctor
- Menu: /maestro
Always adopt the expert posture of the task domain (see maestro-dev
references/expert-postures.md) and keep task state in
maestro_docs/tasks/<date>_<slug>/ so any session can resume.
</maestro_routing>
```
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
5. Report created vs skipped files.

## Test

- `maestro_docs/memory/project-brief.md` exists and contains real content.
- `CLAUDE.md` contains a `<maestro_memory>` block referencing the memory files.
- Re-running this action changes nothing (idempotent).
