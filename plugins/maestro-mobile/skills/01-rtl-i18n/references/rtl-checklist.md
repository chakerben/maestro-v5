# RTL readiness checklist

Run visually in BOTH directions on the 3 worst screens: forms, tables/lists,
checkout/summary.

## Layout
- [ ] html/dir set from the locale; RN: the recorded direction model
      (`references/react-native-rtl.md`) — forced RTL (Arabic-only) or `allowRTL`
      following the language (bilingual, no `forcesRTL`); no mirrored root
- [ ] Zero physical left/right in styles (logical props / ms-me utilities)
- [ ] No flex-row-reverse compensations
- [ ] Scrollbars, drawers, toasts appear on the correct side
- [ ] Swipe gestures mirrored (back-swipe direction)

## Content
- [ ] Every user-facing string in the i18n layer (grep for JSX literals)
- [ ] Count strings use ICU plural (6 Arabic categories covered by fallback)
- [ ] Mixed bidi content wrapped (dir=auto or \u2066..\u2069 isolates; RN: never
      `writingDirection` on a text run) —
      test "iPhone 15 من Apple" in a sentence
- [ ] Ellipsis/truncation on the correct end

## Formats
- [ ] Digits are 0-9 everywhere, display and input (Arabic-Indic / Persian digits
      normalised on input); any other digit set is a recorded project exception
- [ ] Gregorian dates only, one format app-wide; a Hijri display exists only as a
      recorded project exception
- [ ] Every number/date/amount goes through the one formatting helper
      (`references/formatting.md`); no `Intl` / `toLocaleString` elsewhere
- [ ] Currency via the SVG icon component, rendered as in `references/sar.md`;
      no currency character anywhere
- [ ] Phone numbers forced LTR (dir=ltr isolate)
- [ ] Phone INPUT laid out LTR as a whole: country-code box (🇸🇦 +966) on the LEFT,
      digits left-aligned next to it, label still RTL.
      Recipe — web: wrap the field (prefix + input, not the label) in
      `<div dir="ltr">`. RN: wrap the row in `<View style={{ direction: 'ltr' }}>`
      with `flexDirection: 'row'` and `borderEndWidth` on the prefix. Never
      `row-reverse` + physical `borderRight*`: RN swaps `left/right` props to
      `start/end` under RTL by default (`I18nManager.doLeftAndRightSwapInRTL`),
      so a "physical" border lands on the wrong edge.

## Typography
- [ ] Arabic font loaded with Latin subset fallback
- [ ] line-height >= 1.6 on Arabic body text, no diacritic clipping
- [ ] Mobile: `font-metrics.py check` passes on every shipped Arabic font (no `CLIP`, no `NO-ARABIC`: the ي dots stay whole on the device — references/arabic-font-metrics.md)
- [ ] letter-spacing: 0 on Arabic
- [ ] Bold weights exist in the font (fake bold breaks joining)

## Icons & media
- [ ] Directional icons flip; clocks/logos/media controls do not
- [ ] Illustrations with reading direction reviewed
