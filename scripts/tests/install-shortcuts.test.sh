#!/bin/bash
# install-shortcuts test — run from repo root: bash scripts/tests/install-shortcuts.test.sh
# Regression: under `set -u` an unescaped $ARGUMENTS aborted the script before
# it wrote a single file (5.10.0). Runs against a throwaway $HOME.
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
chk() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "  ❌ [$1] got=$2 want=$3"; fi; }

HOME="$T" bash scripts/install-shortcuts.sh >"$T/out.log" 2>&1
chk "exit 0" "$?" "0"

CMDS="$T/.claude/commands"
N=$(ls "$CMDS"/*.md 2>/dev/null | wc -l | tr -d ' ')
chk "≥ 15 commands written" "$([ "$N" -ge 15 ] && echo yes || echo "no($N)")" "yes"

BAD=0
for f in "$CMDS"/*.md; do
  head -1 "$f" | grep -q '^---$' || { BAD=$((BAD+1)); echo "  ❌ no frontmatter: $f"; continue; }
  sed -n '2,/^---$/p' "$f" | grep -Eq '^description: *"?[^" ]' || { BAD=$((BAD+1)); echo "  ❌ empty description: $f"; }
done
chk "every command has a non-empty description" "$BAD" "0"
chk "\$ARGUMENTS survives in the body" "$(grep -l '\$ARGUMENTS' "$CMDS"/*.md | wc -l | tr -d ' ')" "$N"
chk "gwt symlink installed" "$([ -L "$T/.local/bin/gwt" ] && echo yes || echo no)" "yes"

echo "install-shortcuts: $PASS passed, $FAIL failed"
[ "$FAIL" = "0" ] || exit 1
