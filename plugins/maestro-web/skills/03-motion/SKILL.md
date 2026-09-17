---
name: 03-motion
description: Web motion for marketing surfaces — hero reveals, scroll-driven sections, smooth scroll, micro-interactions — with GSAP + Lenis as the default, reduced-motion respected, and the RTL/Arabic traps handled. Use when a request mentions animation, scroll effect, hero, landing page feel, "faire vivre la page", parallax. Not for app dashboards (keep them still), not for React Native (Reanimated — maestro-mobile).
argument-hint: "<what should move, on which page>"
effort: medium
---

# Skill: motion

> GSAP is free for all use, plugins included, since Webflow acquired it
> (2025) — SplitText, ScrollTrigger, ScrollSmoother, MorphSVG. Lenis (MIT) is
> the smooth-scroll layer. Nothing else is installed by default; React Bits
> and the like are copy sources, not dependencies.

## Defaults

- `gsap` + `@gsap/react` (`useGSAP`) for timelines and scroll; `lenis/react`
  (`ReactLenis`) wrapping the marketing layout only — never the app shell.
- Motion lives in client components under `app/(marketing)/`; the dashboard
  gets none of it (lean-code rung 1: skip).
- Docs via context7 before writing: GSAP and Lenis APIs moved in 2025–2026.

## Non-negotiables

- `prefers-reduced-motion: reduce` → every timeline degrades to a fade or to
  nothing; check `gsap.matchMedia()` in the same file as the animation.
- Nothing animates `top/left/width/height` — transforms and opacity only.
  Layout-shifting motion is a CLS regression, not a feature.
- Scroll-driven sections are pinned with `ScrollTrigger`, never with a
  `scroll` listener; `ScrollTrigger.refresh()` after fonts load (Arabic web
  fonts are heavy and shift line boxes).
- One `gsap.context()` / `useGSAP` scope per component; killed on unmount.
- No animation on the first contentful element above the fold slower than
  300 ms — the headline must be readable before the reveal finishes.

## RTL / Arabic traps

- **SplitText: `type: 'words'` (or `lines`), never `chars` on Arabic** —
  splitting glyphs breaks cursive joining and shaping. Test with «فاتورة».
- Direction-aware offsets: `x: dir === 'rtl' ? 80 : -80`; read `dir` from
  `document.documentElement`, do not hardcode. Horizontal Lenis/snap:
  set `gestureOrientation` and test with a trackpad on the `ar` route.
- Mirrored assets: arrows, progress bars and timelines flip; icons of real
  objects (clock, phone) do not (rule from `maestro-mobile:01-rtl-i18n`).
- Line-height for Arabic reveals ≥ 1.6; masks clipping descenders is the #1
  visual bug on Arabic headlines.

## Process

1. Name the moments: what moves, when, for how long — as a table (element,
   trigger, duration, easing). Three moments make a page feel alive; ten make
   it feel slow.
2. Write the reduced-motion variant first, then the full one.
3. Verify on the `ar` route and on a mid-range Android profile (CPU 4×
   throttle): no dropped frames on the hero, LCP unchanged.
4. Report: bundle delta (`gsap` core ≈ 25 kB gz; plugins tree-shaken), LCP
   before/after, reduced-motion screenshot.

## Test

- `grep -r "type: *'chars'"` finds nothing on components rendered under an
  `ar` locale.
- Every timeline has a `matchMedia` reduced-motion branch.
- LCP measured before/after and reported; no layout property animated.
