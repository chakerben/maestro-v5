# Design review rubric — deductions per pass (start at 10, floor 0)

Cite the line you deducted (`R-STATES-2`, …) next to each finding. Overall
score = the lowest pass. A deduction applies once per distinct defect, not per
occurrence.

## States (R-STATES)
- R-STATES-1 (−3): a required state missing — loading, empty, error, or
  offline — on a view that fetches.
- R-STATES-2 (−2): a state present but unreachable or untested (no fixture,
  no story).
- R-STATES-3 (−1): error state without a retry or a next step.
- R-STATES-4 (−1): skeleton/spinner that shifts layout when content lands.

## Accessibility (R-A11Y)
- R-A11Y-1 (−3): a control unreachable by keyboard, or focus lost after a
  dialog closes.
- R-A11Y-2 (−2): text contrast below 4.5:1 (3:1 for large text), or an icon
  button with no accessible name.
- R-A11Y-3 (−2): an input without a programmatic label.
- R-A11Y-4 (−1): focus ring removed with no replacement; tap target < 44 px.
- R-A11Y-5 (−1): motion with no `prefers-reduced-motion` branch.

## RTL (R-RTL) — only when an `ar` locale exists
- R-RTL-1 (−3): a physical property (`left`/`right`, `ml-`/`mr-`,
  `text-align: left`) on a directional element.
- R-RTL-2 (−2): a directional icon that does not flip, or a non-directional
  one (logo, clock, play) that does.
- R-RTL-3 (−2): `letter-spacing` ≠ 0 on Arabic text, or a Latin-only font
  rendering Arabic.
- R-RTL-4 (−1): mixed bidi text without isolation (`dir="auto"`, `<bdi>`,
  phone/code not forced LTR).
- R-RTL-5 (−1): count string without ICU plural.

## Visual (R-VISUAL)
- R-VISUAL-1 (−2): more than one primary action per view.
- R-VISUAL-2 (−2): spacing or type sizes off the project's scale (name the
  value and the scale).
- R-VISUAL-3 (−1): default system font where the project defines one; or
  the "AI-slop" set — centered-everything, gradient background, three
  rounded cards in a row with an icon each.
- R-VISUAL-4 (−1): inconsistent iconography (two icon sets, mixed stroke
  widths).
