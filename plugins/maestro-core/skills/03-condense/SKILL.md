---
name: 03-condense
description: Toggle terse output mode (lite, full, ultra) that strips filler while code and errors stay verbatim. Use to condense output, switch intensity, or stop terse mode. Not for editing prose or compressing code.
argument-hint: lite | full | ultra | stop
disable-model-invocation: true
---

# Skill: condense

> Adapted from AIDD Framework (MIT) — aidd-refine:03-condense.

Terse output mode with three intensity levels. Strips articles, filler, and
pleasantries from prose while preserving technical substance, code blocks,
quoted errors, and security warnings.

## Rules

- **Persistence**: once active, applies to EVERY response until explicitly
  stopped. No drifting back to verbose prose.
- **Off switch**: only on explicit signal — `stop condense`, `normal mode`,
  or invoking the skill again (toggle).
- **Drop**: articles (a/an/the), filler (just/really/basically/actually),
  pleasantries (sure/certainly/happy to), hedging. Fragments acceptable.
- **Keep verbatim**: code blocks, quoted errors, security warnings, commit
  messages, PR bodies.
- **Pattern**: `[thing] [action] [reason]. [next step].`
- **Auto-pause** for security warnings and irreversible confirmations, then
  resume.

## Levels

- `lite` — drop pleasantries and hedging only.
- `full` (default) — drop all filler, short synonyms preferred.
- `ultra` — telegraphic fragments, max compression.

## Test

- After `lite|full|ultra`, the next three responses contain no filler word
  from the Drop list and every code block / quoted error is byte-identical to
  what it would have been in normal mode.
- After `stop`, the following response is normal prose again.
- A security warning during condense mode was printed in full, not condensed.
