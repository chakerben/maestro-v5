# Pilot 5.15.0 — the first real `/sdlc auto` (2026-10-24)

The ROADMAP prerequisite since 5.3: "every rule in this repo is theory until
one feature has gone spec → plan → implement → review → ship with its task
folder as evidence." This is that run, on a throwaway Expo SDK 54 + Arabic
project (`tabarru`, donation app, amounts in halalas), headless
(`claude -p … --permission-mode acceptEdits`), with the marketplace loaded
from the working branch so every fix was live at once.

## What was asked

`/maestro-core:00-onboard scaffold`, then `/maestro-dev:00-sdlc auto` on a
deliberately critical feature: **recurring monthly donation** — domain
entity, `subscribe` / `cancel` / `runDueCharges` (idempotent), in-memory
adapter, unit tests incl. idempotency and refused payment, and an
Arabic-first screen with Hijri + Gregorian dates and RTL-safe styles.

## What came out

- `spec.md`: 12 checkable criteria, 9 auto-mode assumptions (first charge
  deferred to the worker, idempotency = ledger keyed `(id, periodStart)`,
  billing-day anchoring, Hermes/Hijri flagged for device verification).
- `plan.md` + 4 phases, devil-advocate `proceed with changes` (10 items
  applied, incl. an optional idempotency key on the `PaymentGateway` port).
- **8 commits** on `feat/recurring-donation`, one per phase through the
  gate, each with its phase file and log: harness (TS → CJS for `node
  --test`), domain, use cases + repo, UI helpers, composition + screen.
- Review 1 by **`checker-critical` on opus** (payment) + `m-i18n-checker`:
  `iterate` 7/10, 7 findings. Two were real money bugs: the Donation row
  saved *before* the ledger claim (two rows on overlapping runs), and
  `"10٬5"` parsed as 105 SAR. Phase 5 fixed them; review 2: **`ship` 9/10**.
- 37 tests green, typecheck clean, `depcruise` clean, `rtl-lint` zero
  findings on the screen; `maestro-check` exit 0 at every commit — with the
  caveat that until break 7 was fixed (phase 5) its `rtl`/`tests-related`
  checks were *skipped* on the branch scope, and the project's `lint`
  script is a no-op. The green of phases 1–4 was partly vacuous; the final
  branch verdict (6 green, base `master`) is not.
- A final report that lists its residual risks (crash window before the
  ledger, UTC month math vs Riyadh, no worker host, digits decision, Hermes
  unverified, screen never run on a device) **and its own pipeline breaks**.

The pipeline is autonomous end to end, and the review found what a review
is for.

## What broke, and what changed because of it

| # | Break | Fix |
|---|---|---|
| 1 | `.claude/settings.json` is a platform-protected path: scaffold could not write the deny list headless | `maestro-settings` (human-run command, one source with `fleet-apply.sh`); scaffold prints it, doctor reports the gap |
| 2 | `bash-guard` blocked the scaffold's own `node -e` because the JSON it wrote contained the text `git push --force` | rule 7 runs on the blanked command |
| 3 | `maestro-check`: `git ls-files \| grep -q` under `pipefail` hid the `ar` locale on 28k files | `grep -c`; `--scope all` never walks `node_modules` |
| 4 | scaffold created a `.gitignore` without `node_modules/` | the stack's build output is added when the file is created |
| 5 | the Expo Router `app/` folder was not covered by the `ui-no-infrastructure` boundary (the planner found it) | `app/`, `features/`, `pages/` are UI; the composition edge is the one allowed importer |
| 6 | **auto mode wrote the plan, announced "Next: devil-advocate, then phase 1" and ended the turn** | 00-sdlc: the turn ends at 05's report or a hard stop, never after a narrated next step; a plan with every phase pending resumes at the verdict |
| 7 | `maestro-check --scope branch` guessed `main`; the repo was on `master` with no remote → every path check "skipped" with a plausible reason (the reviewer noticed) | base resolved locally (main/master/develop), fallback to `--scope all` with a note, `base` and `scope_note` in the verdict |
| 8 | the generic secret rule hit `STUB_CARD_TOKEN = 'TODO_REAL_TOKENIZATION'` (correct, but `gate:allow` was needed) | `todo`, `fixme`, `stub`, `dummy`, `fake` join the placeholder list |
| 9 | a phase validation `grep -P '[\x{0600}-\x{06FF}]'` errored without a UTF-8 locale and `! grep` passed vacuously — the executor caught it and re-ran with `LC_ALL=C.UTF-8` | the phase template says so |
| 10 | first devil-advocate dispatch failed with an API 529; the orchestrator retried | nothing — correct behaviour, recorded |
| 11 | `context7` unavailable in the sandbox; the executor read the installed type declarations instead | nothing — correct fallback, recorded |

## What the pilot could not test

A device. The screen was never rendered: no `app.json`, no simulator in the
sandbox. Hermes support for `islamic-umalqura`, actual RTL mirroring, the
Arabic font — all unverified. `02-design-review` now refuses to score
RTL/visual passes without an Arabic device screenshot for that reason; the
first run on a real project must include one.

## Reading the result honestly

The spec and the plan were better than most humans write for a feature this
size, and the opus review earned its tier twice (F1, F5). The cost of the
pipeline on this feature: ~45 minutes wall clock, one iteration. Whether that
beats "Claude Code + the mobile standards, by hand" on a real client feature
is the next measurement — on Injaz Owner or Dhiyafa, chrono in hand, with the
same feature done both ways. That comparison, not another audit, decides how
much of maestro-dev stays.
