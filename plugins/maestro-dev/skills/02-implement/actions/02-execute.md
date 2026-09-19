# 02 - Execute

The phase loop.

## Process

For each phase in order (skipping `done`):

1. **Open.** Set the phase `status: in-progress`.
2. **Dispatch.** Spawn the `executor` agent (subagent_type
   `maestro-dev:executor`) with a fresh context: the phase file, the plan
   objective, memory references, expert posture. The executor builds,
   formats what it touches, and fixes LSP diagnostics as it goes.
3. **Assert.** Run the phase's validation commands. Log the attempt
   (timestamp, result) in the phase's `## Log`.
   - Green → set `status: done`, commit the phase as ONE unit (code + status),
     message `feat(<slug>): phase <n> — <name>`. When maestro-vcs is
     installed, invoke `maestro-vcs:00-commit` (its injected scan runs on the
     phase diff). Else grep the staged diff's added lines against
     `${CLAUDE_PLUGIN_ROOT}/skills/02-implement/assets/secret-patterns.md`
     (each row's regex, reference command at its top) and stop on any hit —
     the gate is never skipped, only relocated.
   - Red → repair loop (new executor dispatch WITH the failure output),
     max 3 attempts, then set `status: blocked` with the last failure and stop.
4. **Drift check.** If the executor reports the plan doesn't match reality,
   stop the loop and return "replan needed: <specifics>".

## Test

- Every completed phase = exactly one commit containing its code and its
  `status: done` together.
- Every phase commit went through the secrets gate: a phase diff containing
  `sk_live_xxxxxxxxxxxxxxxxxxxxxxxx` produced no commit.
- No phase was marked done without its validation passing (see the Log).
- A blocked stop names the failing command and its output.
