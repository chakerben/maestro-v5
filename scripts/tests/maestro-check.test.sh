#!/bin/bash
# maestro-check + rtl-lint — the gate is commands with exit codes, not sentences.
# Run from repo root: bash scripts/tests/maestro-check.test.sh
set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="$(pwd)"
CHECK="$ROOT/plugins/maestro-quality/bin/maestro-check"
LINT="$ROOT/plugins/maestro-quality/bin/rtl-lint.js"
export CLAUDE_PLUGIN_ROOT="$ROOT/plugins/maestro-quality"
pass=0; fail=0
chk() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  ❌ [$1] got='$2' want='$3'"; fi; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# ── rtl-lint ────────────────────────────────────────────────────────────────
mkdir -p "$T/l" && cd "$T/l"
cat > a.tsx <<'EOF'
export default function Row() {
  return <View style={{ marginLeft: 8, paddingStart: 4, flexDirection: I18nManager.isRTL ? 'row-reverse' : 'row' }}>
    <Text style={{ textAlign: 'left', letterSpacing: 1.2 }}>{`${count} items`}</Text>
    <View style={{ direction: 'ltr', flexDirection: 'row' }}>{/* phone: rtl-ok LTR object */}</View>
    <div className="ml-4 pe-2 text-right rounded-l-md" dir="auto" />
    <span dir="ltr" className="price">x</span>
    <Text style={{ marginStart: 8, letterSpacing: 0 }}>ok</Text>
    <View style={{ marginLeft: 8 }} /> // rtl-ok mirrored by hand for the map
  </View>;
}
EOF
printf 'import { View } from "react-native"; // marginLeft in an import comment\nconst u = "http://x.test/left:1";\nconst s = { left: 0, position: "absolute" };\n' > b.tsx
printf 'final p = EdgeInsets.only(left: 8);\nfinal q = EdgeInsetsDirectional.only(start: 8);\nfinal a = Alignment.centerLeft;\nfinal t = TextStyle(letterSpacing: 0.5);\nfinal z = TextStyle(letterSpacing: 0);\n' > c.dart
OUT=$(node "$LINT" a.tsx b.tsx c.dart); RC=$?
chk "rtl-lint exits 1 on findings" "$RC" "1"
chk "a.tsx:2 physical + reverse" "$(echo "$OUT" | grep -c '^a.tsx:2  RTL-\(PHYS\|REVERSE\)')" "2"
chk "a.tsx:3 textAlign left + letterSpacing + bare plural (3), not Tailwind" "$(echo "$OUT" | grep -c '^a.tsx:3 ')" "3"
chk "a.tsx:4 direction ltr with rtl-ok: not a finding" "$(echo "$OUT" | grep -c '^a.tsx:4 ')" "0"
chk "a.tsx:5 Tailwind ml-4/text-right/rounded-l (1 line, 1 rule)" "$(echo "$OUT" | grep -c '^a.tsx:5  RTL-TW')" "1"
chk "a.tsx:6 dir=ltr on a price wrapper is exempt" "$(echo "$OUT" | grep -c '^a.tsx:6 ')" "0"
chk "a.tsx:7 marginStart + letterSpacing 0: clean" "$(echo "$OUT" | grep -c '^a.tsx:7 ')" "0"
chk "a.tsx:8 rtl-ok marker lists as ALLOWED" "$(echo "$OUT" | grep -c 'ALLOWED a.tsx:8')" "1"
chk "b.tsx: import comment, url, absolute left — only the style object fires" "$(echo "$OUT" | grep -c '^b.tsx:')" "1"
chk "c.dart: EdgeInsets.only(left), centerLeft, letterSpacing 0.5 (3); Directional and 0 clean" "$(echo "$OUT" | grep -c '^c.dart:')" "3"
chk "rtl-lint clean file exits 0" "$(printf 'const a = { marginStart: 1 };\n' > ok.tsx; node "$LINT" ok.tsx >/dev/null; echo $?)" "0"

# ── maestro-check on a fake Expo + Arabic project ───────────────────────────
mkdir -p "$T/p/app" "$T/p/messages" && cd "$T/p" && git init -q
cat > package.json <<'EOF'
{ "name": "demo", "private": true,
  "scripts": { "typecheck": "node -e 'process.exit(0)'", "lint": "node -e 'process.exit(0)'", "test": "node -e \"console.log('1 test ok')\"" },
  "dependencies": { "expo": "54.0.0", "react-native": "0.81.0" } }
EOF
echo '{}' > package-lock.json; echo '{"hello":"مرحبا"}' > messages/ar.json
printf 'export const ok = { marginStart: 1 };\n' > app/ok.tsx
git add -A && git -c user.name=t -c user.email=t@t commit -qm init
# 1. clean staged change → green
printf 'export const y = 2;\n' >> app/ok.tsx && git add -A
J=$(bash "$CHECK" --level standard --json-only 2>/dev/null); RC=$?
chk "clean change: exit 0" "$RC" "0"
chk "clean change: verdict green, stack expo, ar locale" "$(echo "$J" | node -e 'const j=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(j.verdict,j.stack,j.ar_locale)')" "green expo true"
chk "standard runs tests-related (not high only)" "$(echo "$J" | grep -c '"name": "tests-related"')" "1"
chk "boundaries skipped with a reason, not green" "$(echo "$J" | node -e 'const j=JSON.parse(require("fs").readFileSync(0,"utf8"));const b=j.checks.find(c=>c.name==="boundaries");console.log(b.status, /dependency-cruiser/.test(b.output))')" "skipped true"
git -c user.name=t -c user.email=t@t commit -qm clean
# 2. secret + RTL defect → red, both named
printf 'const apiKey = "sk_live_4eC39HqLyjWDarjtT1zdp7dc";\n' > app/k.ts
printf 'export const bad = <View style={{ marginLeft: 8 }} />;\n' > app/bad.tsx
git add -A
J=$(bash "$CHECK" --level standard --json-only 2>/dev/null); RC=$?
chk "secret + rtl defect: exit 1" "$RC" "1"
chk "secrets red, rtl red, typecheck green" "$(echo "$J" | node -e 'const j=JSON.parse(require("fs").readFileSync(0,"utf8"));const s=n=>j.checks.find(c=>c.name===n).status;console.log(s("secrets"),s("rtl"),s("typecheck"))')" "red red green"
chk "rtl output names the file:line and the rule" "$(echo "$J" | grep -c 'app/bad.tsx:1  RTL-PHYS')" "1"
# 3. level off: only secrets
chk "level off runs secrets only" "$(bash "$CHECK" --level off --list | tr '\n' ' ')" "secrets "
chk "level high adds tests-full and lighthouse" "$(bash "$CHECK" --level high --list | grep -c 'tests-full\|lighthouse')" "2"
# 4. a scan that cannot run is red, never green
git reset -q; git checkout -q -- . ; rm -f app/k.ts app/bad.tsx
printf 'export const z = 3;\n' >> app/ok.tsx && git add -A
mkdir -p "$T/lone/bin" && cp "$CHECK" "$LINT" "$T/lone/bin/"   # a copy with no maestro-vcs sibling
J=$(CLAUDE_PLUGIN_ROOT="$T/lone" HOME="$T/emptyhome" bash "$T/lone/bin/maestro-check" --level off --json-only 2>/dev/null); RC=$?
chk "no secret-scan reachable: red (a scan that did not run is not clean)" "$RC:$(echo "$J" | node -e 'console.log(JSON.parse(require("fs").readFileSync(0,"utf8")).checks[0].status)')" "1:red"
# 4b. branch scope on a repo with no remote whose default branch is master (first pilot):
#     the base must resolve locally and the files must be seen — not "skipped: no UI file in scope"
git -c user.name=t -c user.email=t@t commit -qm base2 >/dev/null 2>&1 || true
git branch -M master 2>/dev/null; git checkout -q -b feat/x
printf 'export const bad = <View style={{ marginLeft: 8 }} />;\n' > app/bad2.tsx && git add -A && git -c user.name=t -c user.email=t@t commit -qm feat
J=$(bash "$CHECK" --level standard --scope branch --json-only 2>/dev/null)
chk "branch scope resolves base=master locally and rtl runs red on the branch file" "$(echo "$J" | node -e 'const j=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(j.base, j.checks.find(c=>c.name==="rtl").status)')" "master red"
git checkout -q master 2>/dev/null; git branch -D feat/x -q 2>/dev/null
# 4c. master-only repo (no other branch, no remote): --scope branch falls back to all WITH the note in the JSON,
#     and a committed secret is red on that scope (zero scanned lines is never green)
mkdir -p "$T/solo/src" && cd "$T/solo" && git init -q && git branch -M master
echo '{"name":"solo","private":true}' > package.json; printf 'export const k = "AKIAABCDEFGHIJKLMNOP";\n' > src/k.ts
git add -A && git -c user.name=t -c user.email=t@t commit -qm init
J=$(bash "$CHECK" --level off --scope branch --json-only 2>/dev/null)
chk "master-only: scope note present and effective scope all" "$(echo "$J" | node -e 'const j=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(j.scope, /no base branch/.test(j.scope_note||""))')" "all true"
chk "master-only: committed AKIA key is red on the all scope" "$(echo "$J" | node -e 'console.log(JSON.parse(require("fs").readFileSync(0,"utf8")).checks[0].status)')" "red"
# 4d. a staged path with a space is one file for rtl-lint
mkdir -p "$T/sp/my dir" "$T/sp/messages" && cd "$T/sp" && git init -q && echo '{"name":"sp","private":true,"dependencies":{"expo":"54.0.0"}}' > package.json && echo '{}' > messages/ar.json
printf 'export const a = { marginLeft: 1 };\nexport const b = { paddingRight: 2 };\n' > "my dir/a b.tsx" && git add -A
J=$(bash "$CHECK" --level standard --scope staged --json-only 2>/dev/null)
chk "path with a space: both findings seen" "$(echo "$J" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8")).checks.find(c=>c.name==="rtl");console.log(r.status,(r.output.match(/RTL-PHYS/g)||[]).length)')" "red 2"
# 4e. rtl-lint: block comments blanked, dart multi-line caught, unreadable file is non-zero
cd "$T/l"; printf '/* marginLeft: 4 */\nconst ok = 1;\n' > blk.tsx; printf 'final p = EdgeInsets.only(\n  left: 8,\n);\nfinal q = EdgeInsets.only(top: 8);\n' > ml.dart
chk "block comment does not fire" "$(node "$LINT" blk.tsx | tail -1)" "rtl-lint: 0 finding(s), 0 allowed"
chk "dart format multi-line EdgeInsets.only(left:) caught, top: not" "$(node "$LINT" ml.dart | grep -c 'ml.dart:1  RTL-DART'):$(node "$LINT" ml.dart | grep -c 'ml.dart:4')" "1:0"
chk "unreadable file: reported and exit 1" "$(node "$LINT" nope.tsx >/dev/null; echo $?)" "1"
# 5. gates.json is read when --level is absent
mkdir -p maestro_docs && echo '{ "level": "off" }' > maestro_docs/gates.json
chk "level read from maestro_docs/gates.json" "$(bash "$CHECK" --list | tr '\n' ' ')" "secrets "

# ── boundaries: the shipped dependency-cruiser config catches domain→framework and ui→infrastructure ──
# Needs dependency-cruiser + typescript: skipped (not failed) when not installed in the repo's node_modules
# or when ARCH_FIXTURE_NODE_MODULES points nowhere — CI installs them.
NM="${ARCH_FIXTURE_NODE_MODULES:-$ROOT/node_modules}"
if [ -x "$NM/.bin/depcruise" ] && [ -d "$NM/typescript" ]; then
  mkdir -p "$T/arch/src/domain" "$T/arch/src/application" "$T/arch/src/infrastructure" "$T/arch/src/ui" "$T/arch/node_modules/@prisma/client" && cd "$T/arch"
  ln -s "$NM/.bin" node_modules/.bin; ln -s "$NM/typescript" node_modules/typescript; ln -s "$NM/dependency-cruiser" node_modules/dependency-cruiser
  for d in "$NM"/*; do b=$(basename "$d"); [ -e "node_modules/$b" ] || ln -s "$d" "node_modules/$b"; done
  echo '{"name":"@prisma/client","main":"index.js"}' > node_modules/@prisma/client/package.json; echo 'module.exports={PrismaClient:class{}}' > node_modules/@prisma/client/index.js
  echo '{"name":"arch","private":true}' > package.json; echo '{"compilerOptions":{"module":"esnext","moduleResolution":"bundler","jsx":"react-jsx"}}' > tsconfig.json
  cp "$ROOT/plugins/maestro-core/skills/00-onboard/assets/architecture/dependency-cruiser.node.cjs" .dependency-cruiser.cjs
  printf 'export interface Repo { save(): Promise<void>; }\n' > src/domain/repo.ts
  printf 'import { PrismaClient } from "@prisma/client";\nexport const leak = new PrismaClient();\n' > src/domain/bad.ts
  printf 'import { Repo } from "../domain/repo";\nexport const uc = (r: Repo) => r.save();\n' > src/application/uc.ts
  printf 'import { Repo } from "../domain/repo";\nexport class PrismaRepo implements Repo { async save() {} }\n' > src/infrastructure/prisma-repo.ts
  printf 'import { PrismaRepo } from "../infrastructure/prisma-repo";\nexport const S = () => new PrismaRepo();\n' > src/ui/Screen.tsx
  git init -q && git add -A
  J=$(bash "$CHECK" --level standard --json-only 2>/dev/null)
  chk "boundaries red: domain→@prisma and ui→infrastructure named" "$(echo "$J" | node -e 'const j=JSON.parse(require("fs").readFileSync(0,"utf8"));const b=j.checks.find(c=>c.name==="boundaries");console.log(b.status, /domain-no-framework/.test(b.output), /ui-no-infrastructure/.test(b.output))')" "red true true"
  rm src/domain/bad.ts; printf 'import { uc } from "../application/uc";\nexport const S = () => uc({ save: async () => {} });\n' > src/ui/Screen.tsx; git add -A
  J=$(bash "$CHECK" --level standard --json-only 2>/dev/null)
  chk "boundaries green once the layers point one way" "$(echo "$J" | node -e 'console.log(JSON.parse(require("fs").readFileSync(0,"utf8")).checks.find(c=>c.name==="boundaries").status)')" "green"
else
  echo "  ⏭  boundaries fixture skipped (dependency-cruiser/typescript not in $NM)"
fi

echo "maestro-check: $pass passed, $fail failed"
[ "$fail" = "0" ] || exit 1
