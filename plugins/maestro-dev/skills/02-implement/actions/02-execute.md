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
3. **Assert.** A phase that touches UI in a project with an `ar` locale
   validates on an Arabic device/simulator screenshot stored in the task
   folder (`screens/phase-<n>-ar.png`; `xcrun simctl io booted screenshot`,
   `adb exec-out screencap -p`, Playwright `locale: 'ar-SA'`) — Chrome does
   not clip what the device clips, and a web prototype proves nothing for
   RTL. Run the phase's validation commands, then
   `maestro-check --scope staged --json-only` after staging (maestro-quality,
   when installed) — the phase is green only when both are. Log the attempt
   (timestamp, result, red check names) in the phase's `## Log` and
   increment `attempts`.
   - Red → repair loop (new executor dispatch WITH the failure output);
     at `attempts: 3` set `status: blocked` with the last failure and stop.
   - Green → write `status: done` in the phase file, **stage** the phase's
     code and that phase file (explicit paths, never `-a`), then commit
     through the gate — the gate and the `git commit` are one invocation,
     so the status has to be on disk and staged before it:
     - maestro-vcs installed → invoke `maestro-vcs:00-commit` with the
       caller's mode (`auto` = no message pause) and the message
       `feat(<slug>): phase <n> — <name>`; its injected scan and the gate
       level's checks run on the staged diff.
     - else → grep the staged diff's added lines against
       `${CLAUDE_PLUGIN_ROOT}/skills/02-implement/assets/secret-patterns.md`
       (each row's regex; this fallback has no placeholder filter and no
       `gate:allow` — any hit is a hard stop), then `git commit`.
     - **The gate went red, nothing was committed** → undo the status:
       set `status: in-progress` back, `git restore --staged` the phase
       file, count the attempt, and hand the failing output to the repair
       loop above. A phase file never reads `done` while its diff is
       uncommitted. ONE commit per phase: code + status.
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
