---
status: reproducing     # reproducing | isolating | cause-found | fixed | not-reproducible
date: <yyyy-mm-dd>
slug: <slug>
---

# Debug — <one-line title>

## Report

<verbatim: the user's words, stack trace, failing test path>

## Evidence

<file:line quotes read in action 01>

## Repro

```bash
<command that fails on demand>
```
<captured failing output tail>

## Isolation

- removed <X> → still fails
- removed <Y> → passes (so Y is part of it)

## Minimal case

<smallest failing case, ideally a ≤15-line test>

## Cause

- **Symptom**: <file:line — message>
- **Cause**: <file:line — mechanism>
- **Why the fix goes at the cause**: <other paths sharing it>
- Confidence: <high | medium — missing experiment: …>

## Regression test

<path> — RED output before fix:
<tail>

## Fix

<diff summary> · deliberately not changed: <…>
GREEN: regression + related suite tails

## Seen on the way

- <defect not fixed here → ticket>
