# 02 - Execute

The phase loop.

## Process

For each phase in order (skipping `done`; a `blocked` phase was already
refused by 01):

1. **Open.** Set the phase `status: in-progress`; `attempts: 0` in its
   frontmatter if absent.
2. **Dispatch.** Spawn the `executor` agent (subagent_type
   `maestro-dev:executor`) with a fresh context: the phase file, the plan
   objective, memory references, expert posture — and, on a resumed
   half-done phase, the `git status --short` and `## Log` from 01, so it
   continues the partial work instead of starting over. The executor
   builds, formats what it touches, and fixes LSP diagnostics as it goes.
3. **Assert.** Run the phase's validation commands. Log the attempt
   (timestamp, result) in the phase's `## Log` and increment `attempts`.
   - Red → repair loop (new executor dispatch WITH the failure output);
     at `attempts: 3` set `status: blocked` with the last failure and stop.
   - Green → **stage** the phase's code and its phase file (explicit paths,
     never `-a`), then run the gate, then mark `done`:
     - maestro-vcs installed → invoke `maestro-vcs:00-commit` with the
       caller's mode (`auto` = no message pause) and the message
       `feat(<slug>): phase <n> — <name>`; its injected scan and the gate
       level's checks run on the staged diff. **A red gate is one more
       attempt**: the phase stays `in-progress`, the failing output goes to
       the repair loop above — never `done` with nothing committed.
     - else → grep the staged diff's added lines against
       `${CLAUDE_PLUGIN_ROOT}/skills/02-implement/assets/secret-patterns.md`
       (each row's regex; this fallback has no placeholder filter and no
       `gate:allow` — any hit is a hard stop, phase stays `in-progress`),
       then commit.
     - Gate green and committed → set `status: done` in the same commit
       (write the status before the commit command runs; the phase file is
       staged with the code). ONE commit per phase: code + status.
4. **Drift check.** If the executor reports the plan doesn't match reality,
   stop the loop and return "replan needed: <specifics>".

## Test

- Every completed phase = exactly one commit containing its code and its
  `status: done` together; no phase file reads `done` while its diff is
  uncommitted (a red commit gate leaves it `in-progress`).
- In auto mode the run paused at no phase commit.
- Every phase commit went through the secrets gate: a phase diff containing
  `sk_live_4eC39HqLyjWDarjtT1zdp7dc` produced no commit.
- No phase was marked done without its validation passing (see the Log).
- A blocked stop names the failing command and its output.
