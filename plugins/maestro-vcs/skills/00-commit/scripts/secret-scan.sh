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
# Lines ending in `// gate:allow <reason>` are listed under ALLOWED and do not
# count as hits; the gate must copy them into the commit body as Gate-Allow:.
set -uo pipefail
# BSD grep (macOS) applies locale collation to bracket ranges; force C so a
# range like `[A-Za-z0-9_-]` means bytes, not collation order.
export LC_ALL=C

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS_MD="$HERE/../assets/secret-patterns.md"
[ -f "$PATTERNS_MD" ] || { echo "SECRET SCAN: skipped — patterns file missing ($PATTERNS_MD)"; exit 0; }

MODE="${1:-cached}"
BASE="${2:-}"

diff_input() {
  case "$MODE" in
    cached) git diff --cached -U0 --no-color ;;
    branch)
      if [ -z "$BASE" ]; then
        for b in origin/main main origin/master master; do
          git rev-parse --verify -q "$b" >/dev/null && { BASE="$b"; break; }
        done
      fi
      [ -n "$BASE" ] || { echo "__NOBASE__"; return; }
      git diff -U0 --no-color "$BASE...HEAD" ;;
    stdin) cat ;;
    *) echo "__BADMODE__" ;;
  esac
}

DIFF="$(diff_input 2>/dev/null)"
case "$DIFF" in
  __NOBASE__) echo "SECRET SCAN: skipped — no base branch found (pass one: secret-scan.sh branch <base>)"; exit 0 ;;
  __BADMODE__) echo "SECRET SCAN: skipped — unknown mode '$MODE'"; exit 0 ;;
esac

# Parse "| `pattern` | Name |" rows; un-escape the markdown \| inside patterns.
PATS=()
NAMES=()
while IFS= read -r line; do
  case "$line" in '| `'*) ;; *) continue ;; esac
  pat="${line#\| \`}"; pat="${pat%%\` \|*}"; pat="${pat//\\|/|}"
  name="${line#*\` | }"; name="${name%% |*}"
  PATS+=("$pat"); NAMES+=("$name")
done < "$PATTERNS_MD"
[ "${#PATS[@]}" -gt 0 ] || { echo "SECRET SCAN: skipped — no patterns parsed"; exit 0; }

# Walk the diff: track file + new-line numbers, test each added line.
HITS=0; ALLOWED=0; CHECKED=0; FILE=""; LN=0; OUT=""; ALLOW_OUT=""
while IFS= read -r l; do
  case "$l" in
    +++\ b/*) FILE="${l#+++ b/}"; continue ;;
    +++*|---*) continue ;;
    @@*) h="${l#*+}"; h="${h%% *}"; h="${h%%,*}"; LN="${h:-0}"; continue ;;
    +*)
      added="${l#+}"; CHECKED=$((CHECKED+1))
      for i in "${!PATS[@]}"; do
        m="$(printf '%s\n' "$added" | grep -Eio -e "${PATS[$i]}" | head -1)" || true
        if [ -n "$m" ]; then
          masked="${m:0:8}…"
          if printf '%s' "$added" | grep -Eq '//[[:space:]]*gate:allow[[:space:]]+[^[:space:]]'; then
            ALLOWED=$((ALLOWED+1)); ALLOW_OUT+="  $FILE:$LN  ${NAMES[$i]}  $masked  ($(printf '%s' "$added" | sed -E 's/.*gate:allow[[:space:]]+//'))"$'\n'
          else
            HITS=$((HITS+1)); OUT+="  $FILE:$LN  ${NAMES[$i]}  $masked"$'\n'
          fi
          break
        fi
      done
      LN=$((LN+1)) ;;
    -*) ;;
    *) LN=$((LN+1)) ;;
  esac
done <<< "$DIFF"

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
