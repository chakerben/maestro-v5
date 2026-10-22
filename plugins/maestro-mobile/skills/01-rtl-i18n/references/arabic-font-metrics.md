# Arabic fonts on mobile: metrics clipping (the "missing ي dots" bug)

Seen on several apps (Nemah 2026-10-15, WhatsApp tickets W15–W17; earlier on others). The client reports
«الياء ناقصة» / "the last letter looks wrong" on `حسابي`, `نعمي`, `الشخصي`, while the same text is fine in the
web prototype. It is **not** the font's design and **not** a reason to change the font.

## Cause

- A font declares vertical metrics (`hhea` ascent/descent, `OS/2` typo and win values). CoreText (iOS) and
  Minikin (Android) build the line box from them; React Native then **clips every `<Text>` to its line box**.
- Many Arabic families declare a descent that is smaller than their deepest Arabic glyphs. IBM Plex Sans Arabic:
  descent 415/1000 em, but the final ي with its two dots reaches 440 (Regular) / 455 (Bold). Everything under
  415 is cut: the dots show half-height. (ص / ض stay inside the descent at 240.)
- Chrome and Figma never clip glyph overflow, so the prototype looks right and the bug only appears on the device.
- A bigger `lineHeight` does not fix it on iOS (RN adds the extra space above the baseline), and padding on every
  `<Text>` changes the layout. The metrics are the bug; fix the metrics.

## Procedure (React Native / Expo)

1. Check every Arabic font the app loads, in every weight:
   ```bash
   pip install fonttools   # once
   python3 ${CLAUDE_PLUGIN_ROOT}/skills/01-rtl-i18n/assets/font-metrics.py check node_modules/@expo-google-fonts/<family>/*/*.ttf
   ```
   `CLIP` = the deepest/highest Arabic glyph exceeds the declared descent/ascent.
2. Re-export the fonts with metrics that cover the glyphs (ascent unchanged unless a glyph exceeds it, so text
   keeps its vertical position; a `<Text>` without an explicit `lineHeight` grows by the descent delta — IBM Plex
   goes 415 → 601 because the `usWin` values are reused when they cover the glyphs):
   ```bash
   python3 ${CLAUDE_PLUGIN_ROOT}/skills/01-rtl-i18n/assets/font-metrics.py fix node_modules/@expo-google-fonts/<family>/*/*.ttf --out assets/fonts
   ```
   Commit the script call in the project (`scripts/fonts/patch-metrics.*`) so a font bump re-runs it.
3. Load the local files under the **same family names** the theme tokens use — nothing else changes:
   ```ts
   const [loaded] = useFonts({
     IBMPlexSansArabic_400Regular: require('../assets/fonts/IBMPlexSansArabic_400Regular.ttf'),
     IBMPlexSansArabic_700Bold: require('../assets/fonts/IBMPlexSansArabic_700Bold.ttf'),
   });
   ```
4. Record it in `tech-decisions.md` (which family, old → new descent, which texts grow) and re-baseline the visual
   references the line-box change touched.
5. Verify on the device or simulator with `حسابي · نعمي · الشخصي · العالم` in the largest and smallest sizes —
   a crop of the screenshot at 3× must show both dots of the ي whole.

## Flutter

Flutter does not clip glyph overflow by itself, but a fixed-height container, `ClipRect`, or a `Text` inside a
`SizedBox` of the line height does. Run the same `check`; if a font reports `CLIP`, ship the fixed copy from
`assets/fonts` (same `family` in `pubspec.yaml`) rather than padding every widget.

## Web

Browsers do not clip glyph overflow; `line-height` only affects spacing. No action, but a web prototype is **never**
proof that the font is safe on mobile.

## Definition of done for any app with an `ar` locale

- `font-metrics.py check` passes (exit 0) on every shipped Arabic font file, in CI or recorded in the release log.
- The device screenshot of a word ending in ي shows both dots whole.
