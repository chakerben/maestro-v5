# RTL and Arabic in Flutter

> Reference of `maestro-mobile:01-rtl-i18n`. The SKILL.md rules (logical
> layout, plurals, Hijri, SAR, typography) still hold in substance; this file
> gives their Flutter form, which looks like neither web nor RN.

## Flutter — the web rules do not apply as written

- **Direction**: `MaterialApp` gets `localizationsDelegates` +
  `supportedLocales`; Flutter then sets `Directionality` on its own. Never
  hardcode a `TextDirection` except to isolate one fragment.
- **Margins and alignment**: `EdgeInsetsDirectional.only(start:, end:)`,
  `AlignmentDirectional`, `PositionedDirectional`,
  `BorderRadiusDirectional`. An `EdgeInsets.only(left:)` on a directional
  element is an RTL bug, not a detail.
- **Strings**: ARB files + `gen_l10n` (`AppLocalizations.of(context)!`). An
  `isArabic ? '…' : '…'` ternary in a widget is the anti-pattern: it cannot
  be translated, cannot be tested, and scatters the language across the UI.
  Migration: extract screen by screen, one ARB per locale, `@@locale` set.
- **Plurals**: ARB's ICU syntax covers the six Arabic categories
  (`zero one two few many other`) — use all of them, not `count == 1`.
- **Fonts**: a Latin font (Space Grotesk, Inter, Poppins…) has **no Arabic
  glyphs** — text falls back to the system font, rendering uncontrolled.
  Declare an Arabic family (Cairo, Tajawal, IBM Plex Sans Arabic) and select
  it per locale in the `TextTheme`.
- **Line height**: `TextStyle(height: 1.6…1.8)` for Arabic, otherwise
  diacritics and descenders are clipped. `letterSpacing` stays at 0 — it
  breaks cursive joining.
- **Icons and gestures**: Material's directional icons (`Icons.arrow_back`,
  `arrow_forward`, `chevron_*`, `list`, `format_indent_*`…) carry
  `matchTextDirection` and flip on their own under an RTL `Directionality` —
  do NOT wrap them in `Transform.flip` (double flip). `Transform.flip` or
  `matchTextDirection: true` only for custom SVGs/assets. Trap:
  `Icons.arrow_back_ios` does not flip — use `arrow_back_ios_new`. `Slider`,
  `PageView` and navigation swipes mirror too.
- **Numbers and dates**: `NumberFormat`/`DateFormat` with the locale (`ar`
  → Arabic-Indic digits per the project decision). Never `toString()` on a
  displayed number. `DateFormat` from `intl` is **Gregorian only** — it does
  not do the umalqura calendar; for Hijri use the `hijri` / `hijri_calendar`
  package (or a native channel to `Calendar.islamicUmmAlQura`) and show Hijri
  + Gregorian on official documents.
- **Currency**: SAR via `assets/sar-icon.svg` — Flutter snippet in
  `references/sar.md`.
