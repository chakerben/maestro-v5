# RTL in React Native / Expo

> Reference of `maestro-mobile:01-rtl-i18n`. Read before the first RN screen
> of a project with an `ar` locale. Each rule names the incident class.

## 1. Pick the direction model at project start — and record it

Write the choice in tech-decisions.md. Two models exist; nothing else is
allowed in a new project.

| App | Model | How |
|---|---|---|
| **Arabic-only** | Forced RTL | `I18nManager.allowRTL(true)` + `I18nManager.forceRTL(true)` at startup, the localisation plugin's `supportsRTL` + `forcesRTL`, Android `supportsRtl="true"`. If `I18nManager.isRTL` is still false after the first launch, reload once. |
| **Bilingual** | `allowRTL` follows the language | `I18nManager.allowRTL(isRtl(language))` at startup and on every language switch, then a full reload (Expo: `expo-updates` reload). **Never `forcesRTL`** in the build config — because a binary that forces RTL can never render the LTR language. |

- A direction change needs an app reload: design the language switcher with
  it (confirm, then reload) — because a half-applied direction mirrors some
  screens and not others.
- Old localisation plugin versions reset the direction from the device
  locale at every cold start: check the installed version's notes before
  relying on plugin options in an app with a language switcher.
- **Mirrored root is forbidden**: never flip the root view with
  `transform: [{ scaleX: -1 }]` (or any equivalent) — because every modal,
  icon, list, input and arrow then needs a counter-flip, and each missed one
  is a ticket. An existing project on that model keeps it until a deliberate
  migration; it does not spread to new screens of a new project.
- Never mix models "for one screen" — because two models compose into a
  double flip.

## 2. Styles

- `start`/`end` props only: `marginStart`, `paddingEnd`, `borderEndWidth`,
  `start`/`end` insets. Ship the ban on `left`, `right`, `marginLeft`,
  `paddingRight`, `borderLeft*`… as a lint rule (an `rtl-lint` pass or an
  ESLint rule), not as prose — because physical props are invisible until
  the other direction is tested. RN also swaps `left/right` to `start/end`
  under RTL by default (`doLeftAndRightSwapInRTL`), so a "physical" prop
  does not even stay physical.
- `flexDirection: 'row'` mirrors on its own. Never `row-reverse` as an RTL
  compensation — because it double-flips.
- An LTR object inside an RTL screen (phone input, amount with its icon) is
  a wrapper with `direction: 'ltr'`, not a set of reversed children.

## 3. Text

- **`writingDirection` at block level only** (a whole paragraph or input),
  never on a nested text run — because iOS reorders the entire paragraph
  when a run carries it. Mixed-direction fragments (a Latin product name in
  an Arabic sentence) are wrapped in bidi isolates (U+2066…U+2069).
- Every `TextInput` gets an explicit `textAlign` — because inputs ignore the
  inherited direction and the placeholder lands on the wrong edge.
- Reserve ink room for Arabic descenders: an explicit line box and bottom
  padding on tight labels, and the font metrics check
  (`arabic-font-metrics.md`) — because dots and tails were clipped on device
  while the web prototype looked right.
- Convert CSS typography explicitly when porting a design: a line-height
  below 1 becomes a real line box, `em` tracking becomes 0 on Arabic, and a
  weight becomes a **font family** (`…_700Bold`) — because RN has no
  synthetic weight for custom fonts and clips tight line boxes.
- Symbols and currency marks are SVG components, never font glyphs —
  because the device fallback font lacks them (see `sar.md`).

## 4. Icons and native surfaces

- Direction icons are chosen by intention (`back`, `forward`, `next`), one
  component that picks the glyph from `I18nManager.isRTL` — because a
  literal "arrow-left" is wrong in one direction.
- Localise system dialogs, native permission strings and the OS-level app
  name — because an Arabic screen opened an English alert.
- Modals, bottom sheets and toasts render in portals: check each one in
  RTL, they do not always inherit the parent's direction.

## 5. Verify

- On a device (not only a simulator) whose **system language is Arabic**,
  on both platforms; a bilingual app also on a device set to the other
  language — because a simulator in English hides native-layer bugs.
- The three worst screens (form, list, summary) in each direction, plus one
  modal and one input with mixed-direction content.
