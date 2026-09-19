#!/bin/bash
# Maestro — secret-scan.sh
# The executable form of ../assets/secret-patterns.md (single source of truth:
# the patterns are parsed from that file, never duplicated here).
#
# USAGE
#   secret-scan.sh cached            # added lines of the staged diff
#   secret-scan.sh branch [base]     # added lines of <base>...HEAD (default: origin/main, main, master)
#   secret-scan.sh stdin             # added lines from a diff on stdin
#
# OUTPUT (always exit 0 — it is injected into a skill with `!`, and a non-zero
# exit would abort the invocation instead of informing it):
#   SECRET SCAN: clean — N added line(s) checked
#   SECRET SCAN: RED — k hit(s)          followed by  <file>:<line>  <pattern name>  <masked match>
#   SECRET SCAN: skipped — <reason>
# Lines ending in a `gate:allow <reason>` comment (`//`, `#`, `--`, `/* */`,
# `<!-- -->`) are listed under ALLOWED and do not count as hits; the gate must
# copy them into the commit body as Gate-Allow:.
#
# PERFORMANCE: the diff is parsed in one awk pass into a temp file
# (file<TAB>line<TAB>content), then ONE grep pass finds the candidate lines;
# only those few lines pay the per-pattern work (5.10: 3000 lines went from
# ~90 s to < 1 s).
set -uo pipefail
# BSD grep (macOS) applies locale collation to bracket ranges; force C so a
# range like `[A-Za-z0-9_-]` means bytes, not collation order.
export LC_ALL=C

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS_MD="$HERE/../assets/secret-patterns.md"
[ -f "$PATTERNS_MD" ] || { echo "SECRET SCAN: skipped — patterns file missing ($PATTERNS_MD)"; exit 0; }

MODE="${1:-cached}"
BASE="${2:-}"

TMP="$(mktemp "${TMPDIR:-/tmp}/secret-scan.XXXXXX")" || { echo "SECRET SCAN: skipped — cannot create temp file"; exit 0; }
ERR="$(mktemp "${TMPDIR:-/tmp}/secret-scan.XXXXXX")" || { rm -f "$TMP"; echo "SECRET SCAN: skipped — cannot create temp file"; exit 0; }
trap 'rm -f "$TMP" "$ERR"' EXIT

# Fixed prefixes: users with diff.noprefix / diff.mnemonicPrefix would otherwise
# lose every file name. Parsing relies on "+++ b/<path>". core.quotepath=false
# keeps non-ASCII paths readable (only paths with control chars stay quoted).
DIFF_OPTS=(-U0 --no-color --src-prefix=a/ --dst-prefix=b/ --no-ext-diff)
diff_input() {
  case "$MODE" in
    cached) git -c core.quotepath=false diff --cached "${DIFF_OPTS[@]}" ;;
    branch)
      if [ -z "$BASE" ]; then
        for b in origin/main main origin/master master; do
          git rev-parse --verify -q "$b" >/dev/null && { BASE="$b"; break; }
        done
      fi
      [ -n "$BASE" ] || { echo "__NOBASE__"; return; }
      git -c core.quotepath=false diff "${DIFF_OPTS[@]}" "$BASE...HEAD" ;;
    stdin) cat ;;
    *) echo "__BADMODE__" ;;
  esac
}

DIFF="$(diff_input 2>"$ERR")" || { echo "SECRET SCAN: skipped — git diff failed ($(head -c 200 "$ERR" | tr -d '\n'))"; exit 0; }
case "$DIFF" in
  __NOBASE__) echo "SECRET SCAN: skipped — no base branch found (pass one: secret-scan.sh branch <base>)"; exit 0 ;;
  __BADMODE__) echo "SECRET SCAN: skipped — unknown mode '$MODE'"; exit 0 ;;
esac

# Parse "| `pattern` | Name |" rows; un-escape the markdown \| inside patterns.
PATS=()
NAMES=()
GREP_ARGS=()
while IFS= read -r line; do
  case "$line" in '| `'*) ;; *) continue ;; esac
  pat="${line#\| \`}"; pat="${pat%%\` \|*}"; pat="${pat//\\|/|}"
  name="${line#*\` | }"; name="${name%% |*}"
  PATS+=("$pat"); NAMES+=("$name"); GREP_ARGS+=(-e "$pat")
done < "$PATTERNS_MD"
[ "${#PATS[@]}" -gt 0 ] || { echo "SECRET SCAN: skipped — no patterns parsed"; exit 0; }

# Placeholder values are not secrets (applied to the MATCHED text, never to
# the whole line, so a comment cannot hide a real key).
PLACEHOLDER='example|changeme|placeholder|xxx+|your[_-]?|<.*>|\$\{'
# gate:allow marker, anchored at end of line, in any common comment syntax.
ALLOW_RE='(//|#|--|/\*|<!--)[[:space:]]*gate:allow([[:space:]].*)?$'

# Pass 1 (awk): walk the diff once, track file + new-line numbers, write every
# added line as  file<TAB>line<TAB>content.
printf '%s\n' "$DIFF" | awk -v OFS='\t' '
  { sub(/\r$/, "") }                                   # CRLF content: keep line numbers and reasons clean
  /^diff --git / { file = $0; sub(/.* b\//, "", file); sub(/"$/, "", file); prev = $0; next }
  /^\+\+\+ "?b\// {                                    # real header only after "--- " or "diff --git"
    if (prev ~ /^--- / || prev ~ /^diff --git/) {
      f = substr($0, 5)
      if (f ~ /^"/) f = substr(f, 2, length(f) - 2)   # de-quote "b/path"
      sub(/^b\//, "", f); file = f; prev = $0; next
    }
  }
  /^--- / { if (prev ~ /^(diff --git|index |new file|deleted file|similarity|rename)/) { prev = $0; next } }
  /^@@/ { h = $0; sub(/^@@ -[^ ]* \+/, "", h); sub(/[ ,].*/, "", h); ln = h + 0; prev = $0; next }
  /^(index |new file mode|deleted file mode|similarity |rename |Binary files|old mode|new mode)/ { prev = $0; next }
  /^\\ No newline at end of file/ { prev = $0; next }  # a marker, not a line
  { prev = $0 }
  /^\+/ { print file, ln, substr($0, 2); ln++; next }
  /^-/ { next }
  { ln++ }
' > "$TMP"
CHECKED=$(wc -l < "$TMP" | tr -d ' ')

# Pass 2 (grep): ONE pass over the content column finds the candidate lines
# (record numbers in $TMP). Only those lines pay the per-pattern work below.
CANDIDATES="$(cut -f3- "$TMP" | grep -Ein "${GREP_ARGS[@]}" | cut -d: -f1)" || true

mask_secrets() { # replace every pattern match in $1 by its first 8 chars + …
  local s="$1" m
  for p in "${PATS[@]}"; do
    m="$(printf '%s\n' "$s" | grep -Eio -e "$p" | head -1)" || true
    [ -n "$m" ] && s="${s//"$m"/${m:0:8}…}"
  done
  printf '%s' "$s"
}

HITS=0; ALLOWED=0; OUT=""; ALLOW_OUT=""
for n in $CANDIDATES; do
  rec="$(sed -n "${n}p" "$TMP")"
  FILE="${rec%%$'\t'*}"; rest="${rec#*$'\t'}"; LN="${rest%%$'\t'*}"; added="${rest#*$'\t'}"
  allow=""
  if printf '%s\n' "$added" | grep -Eq "$ALLOW_RE"; then
    reason="$(printf '%s\n' "$added" | sed -E 's/.*gate:allow[[:space:]]*//; s/[[:space:]]*(\*\/|-->)[[:space:]]*$//')"
    allow="$(mask_secrets "$reason")"
  fi
  for i in "${!PATS[@]}"; do
    m="$(printf '%s\n' "$added" | grep -Eio -e "${PATS[$i]}" | head -1)" || true
    [ -n "$m" ] || continue
    if printf '%s\n' "$m" | grep -Eiq "$PLACEHOLDER"; then continue; fi
    masked="${m:0:8}…"
    if [ -n "$allow" ]; then
      ALLOWED=$((ALLOWED+1)); ALLOW_OUT+="  $FILE:$LN  ${NAMES[$i]}  $masked  ($allow)"$'\n'
      continue   # an allowed line lists EVERY secret it carries
    fi
    HITS=$((HITS+1)); OUT+="  $FILE:$LN  ${NAMES[$i]}  $masked"$'\n'
    break
  done
done

if [ "$HITS" -gt 0 ]; then
  echo "SECRET SCAN: RED — $HITS hit(s) in $CHECKED added line(s)"
  printf '%s' "$OUT"
else
  echo "SECRET SCAN: clean — $CHECKED added line(s) checked against ${#PATS[@]} patterns"
fi
if [ "$ALLOWED" -gt 0 ]; then
  echo "ALLOWED ($ALLOWED) — copy into the commit body as Gate-Allow:"
  printf '%s' "$ALLOW_OUT"
fi
exit 0
