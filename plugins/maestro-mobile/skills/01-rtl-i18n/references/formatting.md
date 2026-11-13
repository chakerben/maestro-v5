# One formatting helper: Western digits, Gregorian, explicit time zone

> Reference of `maestro-mobile:01-rtl-i18n`. The default for every project:
> digits 0-9 everywhere (display **and** input), Gregorian calendar only.
> Arabic-Indic digits or a Hijri display exist only as a project exception
> recorded in tech-decisions.md — and then still through this one helper.

## Why one helper

`Intl` picks the numbering system and the calendar from the locale **and the
runtime**: the same `ar-SA` call prints different digits and a different
calendar on a browser, a server and a mobile JS engine. Every direct call is
a place where the default can drift. So: one module, pinned, and a lint rule
or a grep test that forbids `Intl.` / `toLocaleString` / `toLocaleDateString`
anywhere else (ship that as a test, not as prose).

## The helper (TypeScript — web and React Native)

```ts
// format.ts — the ONLY file allowed to call Intl.
const NUM = 'ar-u-nu-latn';               // digits 0-9
const DATE = 'en-CA-u-ca-gregory-nu-latn'; // yields YYYY-MM-DD parts, 0-9

export const formatNumber = (n: number, fractionDigits = 0) =>
  new Intl.NumberFormat(NUM, {
    minimumFractionDigits: fractionDigits, maximumFractionDigits: fractionDigits,
  }).format(n);

export function formatDate(d: Date, timeZone: string) {
  const parts = new Intl.DateTimeFormat(DATE, {
    timeZone, year: 'numeric', month: '2-digit', day: '2-digit',
  }).formatToParts(d);
  const get = (t: string) => parts.find((p) => p.type === t)!.value;
  return `${get('year')}/${get('month')}/${get('day')}`; // one format, app-wide
}

// Arabic-Indic U+0660–0669 and Persian U+06F0–06F9: the low nibble is the digit.
export const toLatinDigits = (s: string) =>
  Array.from(s, (c) => {
    const p = c.codePointAt(0)!;
    return (p >= 0x660 && p <= 0x669) || (p >= 0x6f0 && p <= 0x6f9) ? String(p & 0xf) : c;
  }).join('');
```

- The time zone is a parameter (the business zone, from configuration),
  never the device default — because "today" differs between the server,
  the device and the user.
- Month names, when a screen needs them, come from the translation
  catalogue keyed by month number — not from the runtime's locale data.
- Mobile JS engines do not all honour the `-u-ca-` / `-u-nu-` extensions:
  run the helper's unit test **on the device runtime** once; if it fails,
  build the string from `getFullYear()`-style parts computed in the business
  zone instead.

## Input

- Run `toLatinDigits` on every numeric, phone, code and date input before
  validation and before search — because keyboards and pasted text carry
  Arabic-Indic and Persian digits.
- Do the same once on the server at the validation boundary — the client is
  not the only writer.
- Never compare digit strings produced by two locales, and never parse a
  formatted number back: keep the number, format at the edge.

## Flutter

`NumberFormat`/`DateFormat` from `intl` follow the locale's digits: pass a
Latin-digit locale to the formatter (`'en'`) while the UI locale stays `ar`,
inside one `formatters.dart`; `DateFormat` is Gregorian, which is the
default wanted here.

## Recorded exception

When a project decides otherwise (a regulated document that must show a
Hijri date next to the Gregorian one, a consumer surface in Arabic-Indic
digits): the decision, its scope (which screens or documents) and its owner
go in tech-decisions.md; the variant is one more function **in the same
helper**; input is still normalised to 0-9 and storage never changes.

## Test

- Unit test: `formatNumber(1234.5, 2)`, `formatDate(...)` and
  `toLatinDigits('٠١٢۳')` produce only `[0-9]` digits.
- `grep -rnE "Intl\.|toLocale(Date|Time)?String" src/` matches the helper
  file only.
