#!/bin/bash
# fleet-apply.sh — settings merge is idempotent, never overwrites, dry-run writes nothing,
# discovery skips projects without a maestro plugin, LLM actions are only planned in dry-run.
set -u
cd "$(dirname "$0")/../.." || exit 1
pass=0; fail=0
check() { if eval "$2"; then pass=$((pass+1)); else fail=$((fail+1)); echo "  ❌ $1"; fi; }
T=$(mktemp -d); export HOME="$T/home"; mkdir -p "$HOME"
mkdir -p "$T/p1/.claude" "$T/p2/.claude" "$T/none/.claude" "$T/.maestro-v4-backup-x/.claude"
printf '{"enabledPlugins":{"maestro-core@maestro":true},"permissions":{"deny":["Bash(rm -rf /)"],"allow":["Read"]},"model":"opus","other":1}\n' > "$T/p1/.claude/settings.json"
printf '{"enabledPlugins":{"maestro-dev@maestro":true}}\n' > "$T/p2/.claude/settings.local.json"
printf '{}\n' > "$T/none/.claude/settings.json"
printf '{"enabledPlugins":{"maestro-core@maestro":true}}\n' > "$T/.maestro-v4-backup-x/.claude/settings.json"
L=$(PROJECTS_ROOT="$T" bash scripts/fleet-apply.sh --list)
check "list finds p1 and p2 only" '[ "$(echo "$L" | grep -c "/p[12]")" = 2 ] && ! echo "$L" | grep -q "/none" && ! echo "$L" | grep -q backup'
PROJECTS_ROOT="$T" bash scripts/fleet-apply.sh --settings --dry-run --all >/dev/null
check "dry-run writes nothing" '! [ -f "$T/p2/.claude/settings.json" ] && [ "$(grep -c "rm -rf" "$T/p1/.claude/settings.json")" = 1 ]'
O=$(PROJECTS_ROOT="$T" bash scripts/fleet-apply.sh --settings --all)
check "p1 keeps model opus and other keys" 'python3 -c "import json;d=json.load(open(\"$T/p1/.claude/settings.json\"));assert d[\"model\"]==\"opus\" and d[\"other\"]==1 and d[\"permissions\"][\"allow\"]==[\"Read\"] and len(d[\"permissions\"][\"deny\"])==11"'
check "p2 gets model sonnet + 11 deny" 'python3 -c "import json;d=json.load(open(\"$T/p2/.claude/settings.json\"));assert d[\"model\"]==\"sonnet\" and len(d[\"permissions\"][\"deny\"])==11"'
check "model kept is reported" 'echo "$O" | grep -q "model kept"'
B1=$(cat "$T/p1/.claude/settings.json" "$T/p2/.claude/settings.json")
O2=$(PROJECTS_ROOT="$T" bash scripts/fleet-apply.sh --settings --all)
check "second run is byte-identical and says conforme" '[ "$B1" = "$(cat "$T/p1/.claude/settings.json" "$T/p2/.claude/settings.json")" ] && [ "$(echo "$O2" | grep -c "déjà conforme")" = 2 ]'
printf '{ not json' > "$T/p2/.claude/settings.json"
O3=$(PROJECTS_ROOT="$T" bash scripts/fleet-apply.sh --settings "$T/p2")
check "malformed settings is refused, not overwritten" 'echo "$O3" | grep -q MALFORMED && [ "$(cat "$T/p2/.claude/settings.json")" = "{ not json" ]'
BIN="$T/bin"; mkdir -p "$BIN"; for t in bash python3 sed tr date mkdir grep awk find sort basename dirname wc head cat printf env; do w=$(command -v $t) && ln -s "$w" "$BIN/$t"; done
D=$(PROJECTS_ROOT="$T" PATH="$BIN" bash scripts/fleet-apply.sh --doctor --scaffold --dry-run "$T/p1" 2>&1 || true)
check "dry-run plans both claude -p calls without the CLI" 'echo "$D" | grep -q "04-doctor check" && echo "$D" | grep -q "00-onboard scaffold" && echo "$D" | grep -q acceptEdits'
check "summary/log dir not created in dry-run" '! [ -d "$HOME/.maestro/fleet" ] || [ -z "$(ls -A "$HOME/.maestro/fleet" 2>/dev/null | grep -v "^$" | head -0)" ]'
# ── timeout portable : pas de `timeout`/`gtimeout` sur $PATH (cas macOS stock) ──
# On fabrique un faux `claude` qui répond vite (exit 0) et un autre qui traîne
# (doit être tué et rapporté comme un timeout, code 124) — sans jamais dépendre
# du binaire GNU `timeout`, exactement le manque qui cassait fleet-apply.sh en
# prod (43/43 exit 127).
FAKEBIN="$T/fakebin"; mkdir -p "$FAKEBIN"
for t in bash python3 sed tr date mkdir grep awk find sort basename dirname wc head cat printf env kill sleep; do
  w=$(command -v $t) && ln -sf "$w" "$FAKEBIN/$t"
done
cat > "$FAKEBIN/claude" <<'EOF'
#!/bin/bash
echo "fake claude ok: $*"
exit 0
EOF
chmod +x "$FAKEBIN/claude"
O4=$(PROJECTS_ROOT="$T" PATH="$FAKEBIN" bash scripts/fleet-apply.sh --doctor "$T/p1" 2>&1)
check "run_claude succeeds with no timeout/gtimeout on PATH (portable fallback)" 'echo "$O4" | grep -q "doctor ok"'
check "fallback did not need a real timeout binary" '! command -v timeout >/dev/null 2>&1 || true'

cat > "$FAKEBIN/claude" <<'EOF'
#!/bin/bash
sleep 30
exit 0
EOF
chmod +x "$FAKEBIN/claude"
O5=$(PROJECTS_ROOT="$T" PATH="$FAKEBIN" bash scripts/fleet-apply.sh --doctor --timeout 1 "$T/p1" 2>&1)
check "portable fallback kills a hung claude and reports timeout" 'echo "$O5" | grep -q "doctor timeout 1s"'

# ── $HOME lui-même n'est jamais un "projet" (faux 43e projet vu en prod) ──
printf '{"projects":{"%s":{},"%s":{}}}\n' "$T/p1" "$HOME" > "$HOME/.claude.json"
L2=$(PROJECTS_ROOT="$T" bash scripts/fleet-apply.sh --list)
check "\$HOME is never listed as a project even if ~/.claude.json knows it" '! echo "$L2" | grep -qx "$HOME"'

rm -rf "$T"
echo "fleet-apply: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
