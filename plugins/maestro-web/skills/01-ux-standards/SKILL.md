---
name: 01-ux-standards
description: Product-grade UX rules — mobile-first, accessibility, the four UI states, form ergonomics. Auto-applies when building screens or components. Visual/aesthetic direction is the official frontend-design plugin's job; this skill covers behavior and inclusivity.
user-invocable: false
---

# Skill: ux-standards

frontend-design (official) makes it look distinctive; this skill makes it
WORK for everyone.

## The four states — every data surface

loading (skeleton mirroring final layout, not a lone spinner), empty
(explains + primary action), error (human message + retry), data. A screen
missing one is incomplete, not "MVP".

## Mobile-first

Build at 360px first, enhance up. Test the layout at 360, 768, 1280.
Touch targets >= 44px. Sticky CTAs on long mobile forms.

## Accessibility floor (non-negotiable)

- Full keyboard path: tab order logical, focus visible, Escape closes overlays.
- Every input has a label (not placeholder-as-label); errors linked via
  aria-describedby and announced.
- Contrast >= 4.5:1 body text; interactive states not color-only.
- Images: meaningful alt or empty alt for decorative. Icons-as-buttons carry
  aria-label.
- Motion respects prefers-reduced-motion.

## Forms

- Validate on blur + on submit (not on every keystroke); preserve input on
  error; submit disabled only WHILE submitting (with spinner), never before
  first attempt (let them try, then guide).
- Destructive actions: confirm with the consequence named ("Delete 3
  invoices?"), never a bare "Are you sure?".

## Feedback

Every action acknowledges within 100ms (optimistic or pending state). Toasts
for background outcomes; inline for field-level; never toast a form error the
user must fix.
