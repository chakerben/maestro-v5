# SAR — rendering the Saudi riyal

Reference of `maestro-mobile:01-rtl-i18n`. Ships with `assets/sar-icon.svg`
(24×24, `fill="currentColor"`, a simplified geometric rendering; swap in the
official SAMA artwork when brand fidelity matters).

## Why an icon, not a character

- `SAR` / `ر.س` are the legacy spellings (`﷼` U+FDFC is the *Iranian* RIAL
  SIGN, never SAR); the new symbol is **U+20C1 SAUDI RIYAL SIGN**, added in
  Unicode 17.0 (September 2025).
- Use U+20C1 as text only when every font in the render path (UI, PDF
  headless, email) ships the glyph; most Arabic UI fonts and older OS fonts
  do not yet, and a tofu box on a price is a critical bug. Until then the
  inline SVG is the reliable route on web, RN, Flutter and PDF.

## Strategy: `Intl` for the number, the icon placed by rule

Let `Intl` do the locale work (digits, grouping) with `style: 'decimal'`;
then put the icon **before** the number with a space. That is SAMA's rule for
the new symbol ("to the left of the numeral, with a space, in all languages")
and it is NOT what `formatToParts` gives you: ICU places the `SAR` code
*after* the amount in `ar-SA`. Never build the digits by hand; never let the
currency position come from the formatter.

```ts
const number = new Intl.NumberFormat(locale, {
  style: 'decimal', minimumFractionDigits: 2, maximumFractionDigits: 2,
  numberingSystem: digits, // 'arab' | 'latn' — from tech-decisions.md
}).format(amount);
```

### React / React Native

```tsx
import SarIcon from './assets/sar-icon.svg'; // svgr (web) or react-native-svg-transformer (RN)

export function Price({ amount, locale, digits }: Props) {
  const number = new Intl.NumberFormat(locale, {
    style: 'decimal', minimumFractionDigits: 2, maximumFractionDigits: 2, numberingSystem: digits,
  }).format(amount);
  // Icon first, then the number — same order in ar and en. The wrapper is an
  // LTR object (like a phone number): it must not mirror with the page.
  return (
    <span dir="ltr" aria-label={`${amount} SAR`} style={{ display: 'inline-flex', alignItems: 'center', gap: '0.25em' }}>
      <SarIcon width="1em" height="1em" aria-hidden />
      <span>{number}</span>
    </span>
  );
}
```

The icon inherits `currentColor` and `1em`, so it follows the text style; in
RN use `<View style={{ direction: 'ltr', flexDirection: 'row' }}>` as the
wrapper.

### Flutter

```dart
// pubspec: flutter_svg, intl; asset: assets/sar-icon.svg
Widget price(BuildContext context, num amount) {
  final locale = Localizations.localeOf(context).toString();
  final number = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2).format(amount);
  final icon = SvgPicture.asset('assets/sar-icon.svg',
      height: 14, colorFilter: ColorFilter.mode(DefaultTextStyle.of(context).style.color!, BlendMode.srcIn));
  // Icon first, then the number, in every locale (SAMA). The row is an LTR
  // object: pin its direction instead of letting it follow the page.
  return Row(mainAxisSize: MainAxisSize.min, textDirection: TextDirection.ltr, children: [
    icon, const SizedBox(width: 4), Text(number),
  ]);
}
```

Wrap in `Semantics(label: '$amount SAR')`.

### PDF (02-pdf-rtl)

Inline the SVG markup in the HTML template (not `<img src>` — headless
Chromium may not load it before `page.pdf()`), `height: 1em; vertical-align: -0.1em`.

## Checks

- Screenshot on `ar` and `en`: icon sits where `SAR` would, same colour as
  the digits, no baseline jump.
- `grep -rn "﷼\|ر\.س" src/` finds nothing in new code.
