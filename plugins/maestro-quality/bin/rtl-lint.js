#!/usr/bin/env node
/**
 * rtl-lint — the structural rules of maestro-mobile:01-rtl-i18n as a linter.
 *
 *   node rtl-lint.js <file...>        exit 1 when any finding; one line per finding:
 *   <file>:<line>  <RULE>  <quoted code>  ->  <fix>
 *
 * Rules (each one is a line of references/rtl-checklist.md that a grep can
 * hold; the judgement calls — icon flipping, bidi isolation, numerals — stay
 * with the reviewer):
 *   RTL-PHYS     physical left/right in styles on a directional property
 *                (margin/padding/border/inset/text-align/float), web or RN
 *   RTL-TW       Tailwind ml-/mr-/pl-/pr-/left-/right-/text-left/text-right
 *   RTL-REVERSE  flex-row-reverse / flexDirection: 'row-reverse' as an RTL
 *                compensation (the layout already mirrors)
 *   RTL-DIR      dir="rtl" / dir="ltr" / direction: 'rtl' hardcoded on a page
 *                element (exempt: a line also marked ltr-object / rtl-ok,
 *                a <bdi>, phone/code/price wrappers, <html>)
 *   RTL-SPACING  letter-spacing / letterSpacing other than 0 / normal
 *   RTL-PLURAL   a count interpolation followed by a bare plural suffix
 *                ("{count} items", "${n} item(s)") instead of ICU plural
 *   RTL-DART     EdgeInsets.only(left:|right:), Alignment.centerLeft/Right,
 *                Positioned(left:|right:), TextAlign.left/right in Dart
 *
 * A line ending in "// rtl-ok <reason>" (or "# rtl-ok", "/* rtl-ok * /") is
 * exempt and listed under ALLOWED — the reason has to be there.
 *
 * Regexes are built from strings (\x60 = backtick) so the file stays free of
 * template-literal delimiters.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const Q = '["\'\\x60]'; // a string delimiter: " ' or backtick

const RULES = [
  { id: 'RTL-PHYS', ext: /\.(tsx?|jsx?|css|scss)$/,
    re: new RegExp('\\b(margin|padding|border|inset|scroll-margin|scroll-padding)-?(Left|Right|left|right)\\b(?![-\\w]*(radius|width|color|style))'
      + '|\\bborder(Left|Right)(Width|Color)\\b'
      + '|\\btext-?[aA]lign\\s*[:=]\\s*' + Q + '?(left|right)\\b'
      + '|\\bfloat\\s*:\\s*(left|right)\\b'
      + '|(?<![-\\w/.:])(left|right)\\s*:\\s*(-?\\d|' + Q + '|\\$\\{|\\{)'),
    fix: 'logical property (margin-inline-start / marginStart, inset-inline-start / start, text-align: start)' },
  { id: 'RTL-TW', ext: /\.(tsx?|jsx?|html|vue|svelte)$/,
    // only inside a class attribute / className / clsx-like call, never in a style object
    re: new RegExp('(?:class(?:Name)?\\s*=\\s*|\\b(?:clsx|cn|cva|tw|twMerge|classnames)\\()[^\\n]*?(?<=' + Q + '|\\s)(?:-?(?:sm|md|lg|xl|2xl|hover|focus|rtl|ltr|dark):)*-?(?:ml|mr|pl|pr|left|right|text-left|text-right|rounded-[lr]|rounded-[tb][lr]|border-[lr]|scroll-ml|scroll-mr)(?:-(?:\\d|px|auto|full|\\[)|(?=' + Q + '|\\s))'),
    fix: 'ms-/me-/ps-/pe-/start-/end-/text-start/text-end/rounded-s-/rounded-e-/border-s-/border-e-' },
  { id: 'RTL-REVERSE', ext: /\.(tsx?|jsx?|css|scss|html)$/,
    re: new RegExp('\\bflex-row-reverse\\b|flexDirection\\s*:\\s*[^,;}\\n]*row-reverse|flex-direction\\s*:\\s*row-reverse'),
    fix: 'drop the reverse — flex mirrors under dir=rtl / I18nManager; an LTR object gets direction: ltr on its wrapper instead' },
  { id: 'RTL-DIR', ext: /\.(tsx?|jsx?|html|vue|svelte)$/,
    re: new RegExp('\\bdir\\s*=\\s*' + Q + '(rtl|ltr)' + Q + '|\\bdirection\\s*:\\s*' + Q + '(rtl|ltr)' + Q),
    exempt: /ltr-object|rtl-ok|<bdi|phone|tel|code|price|amount|iban|otp|<html|<Html|lang=/i,
    fix: 'dir from the locale on <html>; dir="auto" on UGC; direction: ltr only on an LTR object (phone, code, price) — say so with // rtl-ok' },
  { id: 'RTL-SPACING', ext: /\.(tsx?|jsx?|css|scss|dart)$/,
    re: new RegExp('\\bletter-?[sS]pacing\\s*[:=]\\s*(?!(0|\'0\'|"0"|0px|0em|normal|null|undefined)\\s*[,;}\\)\\n]|(0|\'0\'|"0"|0px|0em|normal|null|undefined)$)[-\\w.\'"$\\{]'),
    fix: 'letter-spacing: 0 on Arabic (tracking breaks cursive joining)' },
  { id: 'RTL-PLURAL', ext: /\.(tsx?|jsx?|json|arb|dart)$/,
    re: new RegExp('(\\$\\{\\s*\\w*(count|total|n|num|qty|items?|length)\\w*\\s*\\}|\\{\\s*\\w*(count|total|n|num|qty)\\w*\\s*\\})\\s+[a-zA-Z\\u0600-\\u06FF]+\\(?s\\)?(?=' + Q + '|\\s|<)'),
    fix: 'ICU plural with the six Arabic categories (zero/one/two/few/many/other)' },
  { id: 'RTL-DART', ext: /\.dart$/,
    re: new RegExp('EdgeInsets\\.only\\([^)]*\\b(left|right)\\s*:|EdgeInsets\\.fromLTRB\\(|Alignment\\.(center|top|bottom)(Left|Right)\\b|Positioned\\([^)]*\\b(left|right)\\s*:|TextAlign\\.(left|right)\\b|BorderRadius\\.only\\([^)]*\\b(top|bottom)(Left|Right)\\s*:'),
    fix: 'EdgeInsetsDirectional / AlignmentDirectional / PositionedDirectional / TextAlign.start / BorderRadiusDirectional' },
];
const ALLOW = new RegExp('(//|#|/\\*|<!--)\\s*rtl-ok(\\s|$|\\*/|-->)');

let findings = 0, allowed = 0, unreadable = 0;
// Blank /* … */ block comments (same length, newlines kept) so a commented-out
// style never fires and line numbers stay right.
function blankBlockComments(src) {
  return src.replace(/\/\*[\s\S]*?\*\//g, (m) => m.replace(/[^\n]/g, ' '));
}
const DART_OPENER = /\b(EdgeInsets\.(only|fromLTRB)|Positioned|BorderRadius\.only)\s*\(/;
for (const file of process.argv.slice(2)) {
  let txt;
  try { txt = fs.readFileSync(file, 'utf8'); } catch (e) { unreadable++; console.log('unreadable: ' + file + ' (' + (e.code || e.message) + ')'); continue; }
  const lines = blankBlockComments(txt).split('\n');
  const raw = txt.split('\n'); // markers (rtl-ok, exemptions) are read on the raw line, comments included
  const applicable = RULES.filter((r) => r.ext.test(file));
  if (!applicable.length) continue;
  const isDart = /\.dart$/.test(file);
  lines.forEach((line, i) => {
    // a trailing // comment is not code (unless it carries the rtl-ok marker); an
    // import line / re-export line is a path, not a style — a component body is code
    const code = line.replace(/(^|[^:])\/\/(?!.*rtl-ok).*$/, '$1').replace(/^\s*(import\b.*\bfrom\b|import\s+['"]|export\s*(\*|\{[^}]*\})\s*from\b).*$/, '');
    if (!code.trim()) return;
    // Dart: `dart format` splits EdgeInsets.only(\n  left: 8,\n) over lines — the
    // Dart rule reads a window from an opener line to its closing paren (≤ 8 lines)
    let dartSubject = null;
    if (isDart && DART_OPENER.test(code) && !/\)/.test(code)) dartSubject = lines.slice(i, i + 8).join(' ').split(')')[0] + ')';
    const loc = path.relative(process.cwd(), file) + ':' + (i + 1);
    const isAllowed = ALLOW.test(raw[i] || '');
    for (const r of applicable) {
      const subject = (r.id === 'RTL-DART' && dartSubject) ? dartSubject : code;
      if (!r.re.test(subject)) continue;
      if (r.exempt && r.exempt.test(raw[i] || '')) continue;
      if (isAllowed) { allowed++; console.log('  ALLOWED ' + loc + '  ' + r.id + '  ' + line.trim().slice(0, 100)); continue; }
      findings++;
      console.log(loc + '  ' + r.id + '  ' + line.trim().slice(0, 100) + '  ->  ' + r.fix);
    }
  });
}
console.log('rtl-lint: ' + findings + ' finding(s), ' + allowed + ' allowed' + (unreadable ? ', ' + unreadable + ' unreadable' : ''));
process.exit(findings || unreadable ? 1 : 0);
