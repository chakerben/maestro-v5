# SAR — rendering the Saudi riyal

Reference of `maestro-mobile:01-rtl-i18n`. Ships with `assets/sar-icon.svg`
(24×24, `fill="currentColor"`, a simplified geometric rendering; swap in the
official artwork when brand fidelity matters).

## Rule: always the icon component, never a character

- The currency mark is **one SVG component** (`SarIcon`), used on every
  surface: web, React Native, Flutter, PDF, email.
- Never a Unicode character — not `﷼` (U+FDFC is the sign of another
  currency), not the newer U+20C1, not `ر.س` / `SAR` typed next to a number
  — because one font in the render path without the glyph prints a tofu box
  on a price, and that is a critical bug.
- Ship a grep test for those characters in source and translation files,
  not a sentence in a guide.

## The one rendering

This is what the user sees — same object on an English and on an Arabic
screen (`[icon]` stands for the SVG):

```
English screen (LTR):   Total   [icon] 1,250.50
Arabic screen  (RTL):   [icon] 1,250.50   الإجمالي
```

- Child order in the component: **icon first, number second, one space**.
- The component is an **LTR object** with its direction pinned (like a phone
  number): it does not mirror with the page. Only its position in the line
  follows the page direction.
- Digits are 0-9 with two decimals, from the project's formatting helper
  (`formatting.md`) — never from a formatter that also places a currency
  code, because the formatter's currency position changes with the locale.

### React (web)

```tsx
import SarIcon from './assets/sar-icon.svg'; // svgr
import { formatNumber } from './format';     // the one helper, digits 0-9

export function Price({ amount }: { amount: number }) {
  return (
    <span dir="ltr" aria-label={`${amount} SAR`} style={{ display: 'inline-flex', alignItems: 'center', gap: '0.25em' }}>
      <SarIcon width="1em" height="1em" aria-hidden />
      <span>{formatNumber(amount, 2)}</span>
    </span>
  );
}
```

The icon inherits `currentColor` and `1em`, so it follows the text style.

### React Native

```tsx
import SarIcon from './assets/sar-icon.svg'; // react-native-svg-transformer

export function Price({ amount, size = 16, color }: Props) {
  return (
    <View accessible accessibilityLabel={`${amount} SAR`}
      style={{ direction: 'ltr', flexDirection: 'row', alignItems: 'center', gap: 4 }}>
      <SarIcon width={size} height={size} color={color} />
      <Text style={{ fontSize: size, color }}>{formatNumber(amount, 2)}</Text>
    </View>
  );
}
```

### Flutter

```dart
// pubspec: flutter_svg, intl; asset: assets/sar-icon.svg
Widget price(BuildContext context, num amount) {
  // 'en' pins digits 0-9 while the UI locale stays ar.
  final number = NumberFormat.decimalPatternDigits(locale: 'en', decimalDigits: 2).format(amount);
  final icon = SvgPicture.asset('assets/sar-icon.svg',
      height: 14, colorFilter: ColorFilter.mode(DefaultTextStyle.of(context).style.color!, BlendMode.srcIn));
  return Row(mainAxisSize: MainAxisSize.min, textDirection: TextDirection.ltr, children: [
    icon, const SizedBox(width: 4), Text(number),
  ]);
}
```

Wrap in `Semantics(label: '$amount SAR')`.

### PDF (02-pdf-rtl)

Inline the SVG markup in the HTML template (not `<img src>` — a headless
browser may not load it before printing), `height: 1em; vertical-align: -0.1em`,
inside a `dir="ltr"` inline wrapper with the number.

## Checks

- Screenshot on `ar` and `en`: both match the rendering above, icon in the
  colour of the digits, no baseline jump.
- `grep -rnE "﷼|ر\.س|⃁" src/ messages/ locales/` finds nothing (U+FDFC, the
  typed abbreviation, U+20C1).
