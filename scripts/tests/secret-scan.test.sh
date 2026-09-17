#!/bin/bash
# secret-scan test suite — run from repo root: bash scripts/tests/secret-scan.test.sh
S="$(pwd)/plugins/maestro-vcs/skills/00-commit/scripts/secret-scan.sh"
PASS=0; FAIL=0
chk() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "  ❌ [$1] got='$2' want='$3'"; fi; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T" && git init -q && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git checkout -q -b feat
printf 'const a = 1;\nconst k = "sk_live_abcdefghijklmnopqrstuvwxyz";\nconst ok = "sk_live_abcdefghijklmnopqrstuvwxyz"; // gate:allow fixture\n' > a.js
git add a.js
OUT=$(bash "$S" cached)
chk "cached: RED" "$(echo "$OUT" | head -1 | cut -d' ' -f1-3)" "SECRET SCAN: RED"
chk "cached: hit at a.js:2" "$(echo "$OUT" | grep -c 'a.js:2  Stripe key')" "1"
chk "cached: allow listed, not a hit" "$(echo "$OUT" | grep -c 'a.js:3.*fixture')" "1"
chk "cached: masked" "$(echo "$OUT" | grep -c 'sk_live_abcdefghij')" "0"
git -c user.name=t -c user.email=t@t commit -qm x
printf 'AKIAABCDEFGHIJKLMNOP\n' > b.txt && git add b.txt && git -c user.name=t -c user.email=t@t commit -qm y
OUT=$(bash "$S" branch master)
chk "branch: 2 hits across commits" "$(echo "$OUT" | head -1 | grep -o '[0-9]* hit' )" "2 hit"
echo "x" > c.txt && git add c.txt
chk "clean" "$(bash "$S" cached | head -1 | cut -d' ' -f1-3)" "SECRET SCAN: clean"
chk "always exit 0" "$(bash "$S" cached >/dev/null; echo $?)" "0"
chk "unknown mode: skipped, exit 0" "$(bash "$S" bogus | cut -d' ' -f1-3; )" "SECRET SCAN: skipped"
echo "secret-scan: $PASS passed, $FAIL failed"
[ "$FAIL" = "0" ] || exit 1
