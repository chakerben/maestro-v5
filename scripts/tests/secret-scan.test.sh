#!/bin/bash
# secret-scan test suite — run from repo root: bash scripts/tests/secret-scan.test.sh
S="$(pwd)/plugins/maestro-vcs/skills/00-commit/scripts/secret-scan.sh"
PASS=0; FAIL=0
chk() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "  ❌ [$1] got='$2' want='$3'"; fi; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T" && git init -q && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
BASE=$(git rev-parse --abbrev-ref HEAD)   # main or master, per the machine's init.defaultBranch
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
OUT=$(bash "$S" branch "$BASE")
chk "branch: 2 hits across commits" "$(echo "$OUT" | head -1 | grep -o '[0-9]* hit' )" "2 hit"
echo "x" > c.txt && git add c.txt
chk "clean" "$(bash "$S" cached | head -1 | cut -d' ' -f1-3)" "SECRET SCAN: clean"
chk "always exit 0" "$(bash "$S" cached >/dev/null; echo $?)" "0"
chk "unknown mode: skipped, exit 0" "$(bash "$S" bogus | cut -d' ' -f1-3; )" "SECRET SCAN: skipped"
# 5.9.2 regressions (independent audit of 5.9.1)
git config diff.noprefix true
printf '++i;\n+++ b/fake\nAKIAABCDEFGHIJKLMNOP\nx="sk_live_abcdefghijklmnopqrstuvwxyz"; y="AKIAABCDEFGHIJKLMNOP" // gate:allow both\r\n' > d.txt
git add d.txt
OUT=$(bash "$S" cached)
chk "noprefix: file name kept" "$(echo "$OUT" | grep -c 'd.txt:3  AWS')" "1"
chk "++ content line: line numbers right (hit at 3)" "$(echo "$OUT" | grep -c 'd.txt:3')" "1"
chk "+++ inside content: FILE not rewritten" "$(echo "$OUT" | grep -c 'fake')" "0"
chk "allowed line lists every secret" "$(echo "$OUT" | grep -c 'd.txt:4')" "2"
chk "CRLF: reason has no CR" "$(echo "$OUT" | grep -c $'both\r')" "0"
git config --unset diff.noprefix
chk "git failure → skipped, not clean" "$(bash "$S" branch nonexistent | cut -d' ' -f1-3)" "SECRET SCAN: skipped"
# 5.10 — parser, gate:allow syntaxes, new patterns, performance
git rm -q --cached c.txt d.txt; rm -f c.txt d.txt
printf 'x' > n.txt && git add n.txt && git -c user.name=t -c user.email=t@t commit -qm n
printf 'x\nAKIAABCDEFGHIJKLMNOP\n' > n.txt && git add n.txt
chk "no-newline marker does not shift line numbers" "$(bash "$S" cached | grep -c 'n.txt:2  AWS')" "1"
git checkout -q -- n.txt; git reset -q
QD=$(printf 'diff --git "a/caf\\303\\251.txt" "b/caf\\303\\251.txt"\nnew file mode 100644\n--- /dev/null\n+++ "b/caf\\303\\251.txt"\n@@ -0,0 +1 @@\n+AKIAABCDEFGHIJKLMNOP\n')
chk "quoted path: FILE from +++ header, de-quoted" "$(printf '%s\n' "$QD" | bash "$S" stdin | grep -c '^  caf\\303\\251.txt:1  AWS')" "1"
AD=$(printf 'diff --git a/s.sql b/s.sql\n--- a/s.sql\n+++ b/s.sql\n@@ -0,0 +1,4 @@\n+a AKIAABCDEFGHIJKLMNOP -- gate:allow seed\n+b AKIAABCDEFGHIJKLMNOP # gate:allow fixture\n+c AKIAABCDEFGHIJKLMNOP /* gate:allow mock */\n+d AKIAABCDEFGHIJKLMNOP <!-- gate:allow doc AKIAABCDEFGHIJKLMNOP -->\n')
OUT=$(printf '%s\n' "$AD" | bash "$S" stdin)
chk "gate:allow: --, #, /* */, <!-- --> all accepted" "$(echo "$OUT" | grep -c 's.sql:[1-4]  AWS')" "4"
chk "gate:allow: no hit, closers stripped from reason" "$(echo "$OUT" | head -1 | cut -d' ' -f1-3):$(echo "$OUT" | grep -c '(mock)$'):$(echo "$OUT" | grep -c '\*/')" "SECRET SCAN: clean:1:0"
chk "gate:allow: secret masked inside the reason" "$(echo "$OUT" | grep 's.sql:4' | grep -c 'doc AKIAABCD…)$')" "1"
printf 'DB_PASSWORD=hunter2hunter2hunter2\n' > .env && git add -f .env
chk ".env unquoted password: RED" "$(bash "$S" cached | head -1 | cut -d' ' -f1-3)" "SECRET SCAN: RED"
printf 'API_KEY=changeme_placeholder_value\nTOKEN=<your-token-here>\n' > .env && git add -f .env
chk "placeholder values: clean" "$(bash "$S" cached | head -1 | cut -d' ' -f1-3)" "SECRET SCAN: clean"
printf 'ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcd\n' > .env && git add -f .env
chk "GitHub token: RED" "$(bash "$S" cached | grep -c 'GitHub token')" "1"
git rm -q --cached .env; rm -f .env
# 5.14.0 audit 3.1–3.3 — the gate's own fixture, the mandated env.ts pattern, case-sensitive prefixes
FP=$(printf 'diff --git a/env.ts b/env.ts\n--- a/env.ts\n+++ b/env.ts\n@@ -0,0 +1,7 @@\n+const apiKey = process.env.OPENAI_API_KEY;\n+const passwordMinLength = DEFAULT_PASSWORD_LENGTH;\n+const cfg = { apiKey: env.STRIPE_SECRET_KEY, secret: import.meta.env.VITE_SECRET };\n+const t = "task1234567890abcdef1234567890abcdef12";\n+const k = "sk_live_xxxxxxxxxxxxxxxxxxxxxxxx";\n+token = os.environ["API_TOKEN"]\n+const secretSantaAssignments = buildAssignments(users);\n')
OUT=$(printf '%s\n' "$FP" | bash "$S" stdin)
chk "env references are not secrets (process.env / env. / import.meta.env / os.environ / bare identifier)" "$(echo "$OUT" | head -1 | cut -d' ' -f1-3)" "SECRET SCAN: clean"
chk "provider prefixes are case-sensitive (task123… is not a Twilio key)" "$(echo "$OUT" | grep -c Twilio)" "0"
chk "an xxx fixture is a placeholder, not a hit" "$(echo "$OUT" | grep -c Stripe)" "0"
TP=$(printf 'diff --git a/env.ts b/env.ts\n--- a/env.ts\n+++ b/env.ts\n@@ -0,0 +1,4 @@\n+const k = "sk_live_4eC39HqLyjWDarjtT1zdp7dc";\n+const secret = "h7Gq92kLm3PzXw81vRt6";\n+DB_PASSWORD=hunter2hunter2hunter2\n+const twilio = "SK0123456789abcdef0123456789abcdef";\n')
OUT=$(printf '%s\n' "$TP" | bash "$S" stdin)
chk "canonical fixture sk_live_4eC39… is RED" "$(echo "$OUT" | grep -c 'env.ts:1  Stripe key')" "1"
chk "quoted literal secret still RED" "$(echo "$OUT" | grep -c 'env.ts:2  Generic')" "1"
chk "unquoted value with digits still RED" "$(echo "$OUT" | grep -c 'env.ts:3  Generic')" "1"
chk "real Twilio key still RED" "$(echo "$OUT" | grep -c 'env.ts:4  Twilio')" "1"
# cold review of the 5.14.0 fixes: a quoted value is a literal whatever it starts with; in a config
# file nothing is an identifier (a passphrase without digits is a secret); in code, identifiers are.
CR=$(printf 'diff --git a/.env b/.env\n--- a/.env\n+++ b/.env\n@@ -0,0 +1,4 @@\n+API_KEY=correcthorsebatterystaple\n+DB_PASSWORD=ThisIsMyProdPassphrase\n+SESSION_SECRET=process.env.FROM_PLATFORM\n+TOKEN=changeme_placeholder_value\ndiff --git a/config.yml b/config.yml\n--- a/config.yml\n+++ b/config.yml\n@@ -0,0 +1 @@\n+password: SuperSecretPasswordNoDigits\ndiff --git a/k.ts b/k.ts\n--- a/k.ts\n+++ b/k.ts\n@@ -0,0 +1,3 @@\n+const apiKey = "process.env.MY_REAL_SECRET_VALUE_9f8e7d";\n+const secret = %s;\n+const k = { secret: config.auth.clientSecret, s2: buildSecret(users), s3: SOME_CONSTANT_NAME };\n' "'env.hunter2hunter2hunter2'")
OUT=$(printf '%s\n' "$CR" | bash "$S" stdin)
chk ".env passphrases without digits: RED (2)" "$(echo "$OUT" | grep -c '^  .env:[12]  Generic')" "2"
chk ".env lookup value and placeholder: clean" "$(echo "$OUT" | grep -c '^  .env:[34]')" "0"
chk "yaml passphrase: RED" "$(echo "$OUT" | grep -c 'config.yml:1  Generic')" "1"
chk "quoted 'process.env.…' / 'env.…' strings are literals: RED (2)" "$(echo "$OUT" | grep -c 'k.ts:[12]  Generic')" "2"
chk "dotted path, call and CONSTANT in code are references" "$(echo "$OUT" | grep -c 'k.ts:3')" "0"
for i in $(seq 1 3000); do echo "const value_$i = compute($i) + 'an ordinary string literal';"; done > big.js && git add big.js
T0=$(date +%s); OUT=$(bash "$S" cached); T1=$(date +%s)
chk "perf: 3000 clean lines scanned" "$(echo "$OUT" | head -1 | cut -d' ' -f1-6)" "SECRET SCAN: clean — 3000 added"
chk "perf: 3000 lines in < 5 s" "$([ $((T1-T0)) -lt 5 ] && echo fast || echo "slow ($((T1-T0))s)")" "fast"
echo "secret-scan: $PASS passed, $FAIL failed"
[ "$FAIL" = "0" ] || exit 1
