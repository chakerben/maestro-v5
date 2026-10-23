---
name: 02-design-review
description: Review a screen or component against Maestro UX standards, RTL readiness, and visual quality — from code, a screenshot, or a live URL. Use before shipping UI or when a screen feels off. Produces a scored findings report. Not for building UI (that's implement + frontend-design).
argument-hint: "<path, screenshot, or URL>"
allowed-tools: Read, Grep, Glob, Bash
disallowed-tools: Write, Edit, NotebookEdit   # enforced: an audit never edits (allowed-tools alone only pre-approves)
model: fable
effort: high
---

# Skill: design-review

Adopt the senior product designer posture. Judge, don't rebuild. The
generic taste is not Maestro's to write: the official `frontend-design`
plugin and the `impeccable` skill carry it, and both are better at it than a
Maestro rubric. **This skill owns what they do not know: the Saudi/Arabic
layer and the proof on a device.**

## Process

0. **Tools first.** `maestro-check --scope branch` (maestro-quality, when
   installed): its `rtl` check already lists every physical property,
   `letter-spacing`, bare plural and hardcoded `dir` with file:line — those
   are findings, copy them, do not re-derive them by eye.
1. **Acquire.** Code path → read the component tree + styles. Screenshot →
   analyze visually. URL → fetch/screenshot if tooling allows.
   **A UI change in a project with an `ar` locale is reviewed on a device
   or simulator screenshot in Arabic, never from code alone** — ask for it
   (or take it: `xcrun simctl io booted screenshot`, `adb exec-out screencap
   -p`, Playwright with `locale: 'ar-SA'`) and refuse to score the RTL and
   visual passes without it. Chrome never clips what CoreText clips.
2. **Four-states pass** (01-ux-standards): are loading/empty/error designed
   or accidental?
3. **A11y pass**: labels, contrast (estimate from styles/pixels), focus
   handling, target sizes.
4. **RTL / KSA pass** when an `ar` locale exists — the Maestro layer, read
   on the Arabic screenshot: mirrored layout actually mirrored; directional
   icons flipped, logos/clocks/media not; Arabic font loaded with real bold
   weights, no clipped ي dots or diacritics; numerals consistent with the
   recorded arab/latn decision; Hijri where the market expects it; riyal
   symbol before the amount; phone/code/price blocks LTR; mixed Arabic/Latin
   lines isolated; line-height ≥ 1.6; register of the Arabic copy
   (`maestro-pm:04-writing` when installed).
5. **Visual pass** — delegate: when `frontend-design` or `impeccable` is
   installed, invoke it on the same screenshot and take its verdict as the
   visual pass (name which one ran). Only without either: hierarchy (one
   primary action per view?), spacing rhythm, typography scale, "AI-slop"
   tells (default fonts, centered-everything, gradient soup).
6. Report: findings by severity, each with evidence (line or region) and the
   concrete fix. Score each pass /10 with the rubric in
   `${CLAUDE_PLUGIN_ROOT}/skills/02-design-review/assets/rubric.md` (fixed
   deductions, so two runs on the same screen give the same number); overall
   = the lowest pass, not the mean — one unusable state sinks the screen.
   Criticals → `maestro-pm:03-ticket` when installed, else list them in the
   review output.

## Test

- Every finding is actionable (a developer could fix it without asking what you meant).
- With an `ar` locale the review names the Arabic device/simulator
  screenshot it judged, or stops without an RTL/visual score; the structural
  RTL findings come from `maestro-check`'s `rtl` output when available.
- The visual pass names `frontend-design` or `impeccable` when one ran.
- Every score cites the rubric lines it deducted; the same screen reviewed
  twice gets the same scores.
