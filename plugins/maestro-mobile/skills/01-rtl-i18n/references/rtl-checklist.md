# RTL readiness checklist

Run visually in BOTH directions on the 3 worst screens: forms, tables/lists,
checkout/summary.

## Layout
- [ ] html/dir or I18nManager set from locale, not hardcoded
- [ ] Zero physical left/right in styles (logical props / ms-me utilities)
- [ ] No flex-row-reverse compensations
- [ ] Scrollbars, drawers, toasts appear on the correct side
- [ ] Swipe gestures mirrored (back-swipe direction)

## Content
- [ ] Every user-facing string in the i18n layer (grep for JSX literals)
- [ ] Count strings use ICU plural (6 Arabic categories covered by fallback)
- [ ] Mixed bidi content wrapped (dir=auto or \u2066..\u2069 isolates) —
      test "iPhone 15 من Apple" in a sentence
- [ ] Ellipsis/truncation on the correct end

## Formats
- [ ] Numerals decision recorded (arab vs latn) and consistent
- [ ] Hijri where the market requires; dual display on official docs
- [ ] SAR via `assets/sar-icon.svg` per `references/sar.md`; order follows direction
- [ ] Phone numbers forced LTR (dir=ltr isolate)

## Typography
- [ ] Arabic font loaded with Latin subset fallback
- [ ] line-height >= 1.6 on Arabic body text, no diacritic clipping
- [ ] letter-spacing: 0 on Arabic
- [ ] Bold weights exist in the font (fake bold breaks joining)

## Icons & media
- [ ] Directional icons flip; clocks/logos/media controls do not
- [ ] Illustrations with reading direction reviewed
