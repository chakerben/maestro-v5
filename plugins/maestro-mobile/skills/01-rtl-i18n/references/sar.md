# SAR — rendering the Saudi riyal

Reference of `maestro-mobile:01-rtl-i18n`. Ships with `assets/sar-icon.svg`
(24×24, `fill="currentColor"`, a simplified geometric rendering; swap in the
official SAMA artwork when brand fidelity matters).

## Why an icon, not a character

- `SAR` / `ر.س` / `﷼` (U+FDFC) are legacy spellings; the new symbol is
  **U+20C1 SAUDI RIYAL SIGN**, added in Unicode 17.0 (September 2025).
- Use U+20C1 as text only when every font in the render path (UI, PDF
  headless, email) ships the glyph; most Arabic UI fonts and older OS fonts
  do not yet, and a tofu box on a price is a critical bug. Until then the
  inline SVG is the reliable route on web, RN, Flutter and PDF.

## Strategy: format with `code`, replace the code by the icon

Let `Intl` do the locale work (digits, grouping, position of the currency),
then swap the `SAR` token for the icon. Never build the string by hand.

```ts
const parts = new Intl.NumberFormat(locale, {
  style: 'currency', currency: 'SAR', currencyDisplay: 'code',
  numberingSystem: digits, // 'arab' | 'latn' — from tech-decisions.md
}).formatToParts(amount);
```

### React / React Native

```tsx
import SarIcon from './assets/sar-icon.svg'; // svgr (web) or react-native-svg-transformer (RN)

export function Price({ amount, locale, digits }: Props) {
  const parts = new Intl.NumberFormat(locale, {
    style: 'currency', currency: 'SAR', currencyDisplay: 'code', numberingSystem: digits,
  }).formatToParts(amount);
  return (
    <span aria-label={`${amount} SAR`} style={{ display: 'inline-flex', alignItems: 'center', gap: '0.15em' }}>
      {parts.map((p, i) =>
        p.type === 'currency'
          ? <SarIcon key={i} width="1em" height="1em" aria-hidden />
          : <span key={i}>{p.value}</span>)}
    </span>
  );
}
```

The icon inherits `currentColor` and `1em`, so it follows the text style;
order and spacing come from `formatToParts`, so `ar` and `en` differ only by
data, never by a hand-written `isRTL ? … : …`.

### Flutter

```dart
// pubspec: flutter_svg, intl; asset: assets/sar-icon.svg
Widget price(BuildContext context, num amount) {
  final locale = Localizations.localeOf(context).toString();
  final text = NumberFormat.currency(locale: locale, name: 'SAR', symbol: 'SAR').format(amount);
  final i = text.indexOf('SAR');
  final icon = SvgPicture.asset('assets/sar-icon.svg',
      height: 14, colorFilter: ColorFilter.mode(DefaultTextStyle.of(context).style.color!, BlendMode.srcIn));
  return Row(mainAxisSize: MainAxisSize.min, textDirection: Directionality.of(context), children: [
    if (i > 0) Text(text.substring(0, i)),
    icon,
    if (i + 3 < text.length) Text(text.substring(i + 3)),
  ]);
}
```

`Row` follows `Directionality`, so the amount/icon order flips with the
locale without code. Wrap in `Semantics(label: '$amount SAR')`.

### PDF (02-pdf-rtl)

Inline the SVG markup in the HTML template (not `<img src>` — headless
Chromium may not load it before `page.pdf()`), `height: 1em; vertical-align: -0.1em`.

## Checks

- Screenshot on `ar` and `en`: icon sits where `SAR` would, same colour as
  the digits, no baseline jump.
- `grep -rn "﷼\|ر\.س" src/` finds nothing in new code.
