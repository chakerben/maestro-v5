#!/usr/bin/env python3
"""
Arabic font metrics check — do the font's vertical metrics cover its Arabic glyphs?

Why: React Native (iOS and Android) clips a <Text> to the line box CoreText / Minikin derive from the font's hhea
(or OS/2 typo) ascent and descent. Many Arabic families ship a descent smaller than their deepest Arabic glyphs
(IBM Plex Sans Arabic: descent 415/1000 em, final ي with dots 455, ص / ض 521). On the device the dots of «حسابي» and
the tail of «الشخصي» are cut; in Chrome (where the design prototype lives) nothing is clipped, so the bug only shows
on the phone and reads like "the ي is missing". Changing the font is the wrong fix — the metrics are.

Usage:
  python3 font-metrics.py check  fonts/*.ttf                 # report, exit 1 when a font would clip
  python3 font-metrics.py fix    fonts/*.ttf --out assets/fonts   # write copies whose metrics cover the Arabic glyphs
  add --all to measure every Arabic block (extended letters) instead of the standard alphabet + tashkeel + digits

Requires fontTools (`pip install fonttools`). Works on TTF and OTF (CFF). The fix only enlarges hhea / OS-2 typo
ascent and descent (usWin values when they already cover the glyphs, else the glyph bounds themselves) and sets
USE_TYPO_METRICS; glyph outlines, names and family names are untouched, so the app keeps the same fontFamily keys.
"""
import argparse
import sys
from pathlib import Path

try:
    from fontTools.ttLib import TTFont
    from fontTools.pens.boundsPen import BoundsPen
except ImportError:  # pragma: no cover
    sys.exit("fontTools missing: pip install fonttools")

# Every Arabic block (`--all`): extended letters (ڜ, ڴ…) sit deeper / higher than the standard alphabet.
ARABIC_RANGES = ((0x0600, 0x06FF), (0x0750, 0x077F), (0x08A0, 0x08FF), (0x0870, 0x089F), (0xFB50, 0xFDFF), (0xFE70, 0xFEFF))
# Default: the standard Arabic alphabet, tashkeel, tatweel, digits and punctuation — what an Arabic UI actually renders.
COMMON_RANGES = ((0x0621, 0x0655), (0x0660, 0x066D), (0x0670, 0x0671), (0x060C, 0x060C), (0x061B, 0x061B), (0x061F, 0x061F), (0x0640, 0x0640))
USE_TYPO_METRICS = 1 << 7


def is_arabic(cp: int, every_block: bool) -> bool:
    return any(lo <= cp <= hi for lo, hi in (ARABIC_RANGES if every_block else COMMON_RANGES))


def arabic_glyph_names(font: TTFont, every_block: bool) -> set[str]:
    """Glyphs mapped from an Arabic code point plus their contextual / ligature variants (name-derived: `uni0635.fina`,
    `sad.medi`, `lam_alef`…), which is where the deep final forms live."""
    cmap = font.getBestCmap() or {}
    base = {name for cp, name in cmap.items() if is_arabic(cp, every_block)}
    stems = {n.split('.')[0] for n in base}
    out = set(base)
    for n in font.getGlyphOrder():
        stem = n.split('.')[0]
        parts = stem.split('_')
        if stem in stems or (len(parts) > 1 and all(p in stems for p in parts)):
            out.add(n)
    return out


def bounds(font: TTFont, names: set[str]):
    gs = font.getGlyphSet()
    lowest, highest = (0, None), (0, None)
    for n in names:
        if n not in gs:
            continue
        pen = BoundsPen(gs)
        gs[n].draw(pen)
        if pen.bounds is None:
            continue
        _, y_min, _, y_max = pen.bounds
        if y_min < lowest[0]:
            lowest = (y_min, n)
        if y_max > highest[0]:
            highest = (y_max, n)
    return lowest, highest


def report(path: Path, every_block: bool):
    f = TTFont(path)
    hhea, os2, upm = f['hhea'], f['OS/2'], f['head'].unitsPerEm
    (low, low_n), (high, high_n) = bounds(f, arabic_glyph_names(f, every_block))
    descent, ascent = -hhea.descent, hhea.ascent
    clip_below, clip_above = -low - descent, high - ascent
    verdict = 'CLIP' if clip_below > 0 or clip_above > 0 else 'OK'
    print(f"{path.name}: {verdict}  hhea ascent {ascent} descent {descent} (upm {upm}) · typo {os2.sTypoAscender}/{os2.sTypoDescender} · win {os2.usWinAscent}/{os2.usWinDescent}")
    print(f"  deepest Arabic glyph {low:.0f} ({low_n}) → {'exceeds descent by ' + format(clip_below, '.0f') if clip_below > 0 else 'covered'}")
    print(f"  highest Arabic glyph {high:.0f} ({high_n}) → {'exceeds ascent by ' + format(clip_above, '.0f') if clip_above > 0 else 'covered'}")
    return f, verdict, low, high


def fix(path: Path, out_dir: Path, every_block: bool):
    f, verdict, low, high = report(path, every_block)
    hhea, os2 = f['hhea'], f['OS/2']
    descent = max(-hhea.descent, os2.usWinDescent, int(-low) + 1)
    ascent = max(hhea.ascent, int(high) + 1)
    hhea.descent, hhea.ascent = -descent, ascent
    os2.sTypoDescender, os2.sTypoAscender = -descent, ascent
    os2.usWinDescent, os2.usWinAscent = max(os2.usWinDescent, descent), max(os2.usWinAscent, ascent)
    os2.fsSelection |= USE_TYPO_METRICS
    out_dir.mkdir(parents=True, exist_ok=True)
    f.save(out_dir / path.name)
    print(f"  → {out_dir / path.name}: ascent {ascent} descent {descent} ({'was clipping' if verdict == 'CLIP' else 'already covered, metrics normalised'})")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('mode', choices=['check', 'fix'])
    ap.add_argument('fonts', nargs='+', type=Path)
    ap.add_argument('--out', type=Path, default=Path('assets/fonts'), help='fix: output directory (default assets/fonts)')
    ap.add_argument('--all', action='store_true', help='measure every Arabic block, not only the standard alphabet')
    a = ap.parse_args()
    bad = 0
    for p in a.fonts:
        if a.mode == 'check':
            bad += report(p, a.all)[1] == 'CLIP'
        else:
            fix(p, a.out, a.all)
    if a.mode == 'check' and bad:
        print(f"\n{bad} font(s) would clip Arabic glyphs on React Native: run `font-metrics.py fix` (see references/arabic-font-metrics.md)")
        sys.exit(1)


if __name__ == '__main__':
    main()
