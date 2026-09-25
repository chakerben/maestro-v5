---
name: 02-design-review
description: Review a screen or component against Maestro UX standards, RTL readiness, and visual quality — from code, a screenshot, or a live URL. Use before shipping UI or when a screen feels off. Produces a scored findings report. Not for building UI (that's implement + frontend-design).
argument-hint: "<path, screenshot, or URL>"
allowed-tools: Read, Grep, Glob, Bash
model: fable
effort: high
---

# Skill: design-review

Adopt the senior product designer posture. Judge, don't rebuild.

## Process

1. **Acquire.** Code path → read the component tree + styles. Screenshot →
   analyze visually. URL → fetch/screenshot if tooling allows.
2. **Four-states pass** (01-ux-standards): are loading/empty/error designed
   or accidental?
3. **A11y pass**: labels, contrast (estimate from styles/pixels), focus
   handling, target sizes.
4. **RTL pass** when an `ar` locale exists: apply the maestro-mobile
   01-rtl-i18n rules — read its `references/rtl-checklist.md` when that
   plugin is installed; otherwise use the core checks: logical properties
   only, correct icon flipping, letter-spacing 0 on Arabic, plurals via ICU.
5. **Visual pass**: hierarchy (one primary action per view?), spacing rhythm
   (consistent scale?), typography scale, "AI-slop" tells (default fonts,
   centered-everything, gradient soup) — align with the frontend-design
   plugin's direction when installed.
6. Report: findings by severity, each with evidence (line or region) and the
   concrete fix. Score /10 per pass + overall. Criticals → `maestro-pm:03-ticket`
   when installed, else list them in the review output.

## Test

- Every finding is actionable (a developer could fix it without asking what you meant).
- RTL pass ran whenever an `ar` locale exists.
