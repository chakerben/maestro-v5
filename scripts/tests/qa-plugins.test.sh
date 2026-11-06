#!/bin/bash
# maestro-test-e2e scripts — qa-resolve-repo refuses cleanly (no origin, no key, no project, several projects, Injaz
# refusal or down, a non-https URL), never prints the key, never executes the env file; qa-coverage computes the map's
# counts and lists every inconsistency. A fake Injaz on 127.0.0.1, no network.
set -u
cd "$(dirname "$0")/../.." || exit 1
pass=0; fail=0
check() { if eval "$2"; then pass=$((pass+1)); else fail=$((fail+1)); echo "  ❌ $1"; fi; }
RESOLVE="$PWD/plugins/maestro-test-e2e/bin/qa-resolve-repo"
COVERAGE="$PWD/plugins/maestro-test-e2e/bin/qa-coverage"
T=$(mktemp -d); trap 'kill $SERVER 2>/dev/null; rm -rf "$T"' EXIT
KEY="qa_workstation_test_key_0123456789abcdefghijkl"

# ── fake Injaz: answers by repository name, records the Authorization header ──
cat > "$T/server.py" <<'PY'
import json, sys, urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer
EXPECTED = sys.argv[2]
LOG = sys.argv[3]
ONE = {"id": "p-1", "code": "TECH", "name": "منصة التقنية", "state": "active", "via": ["project"]}
class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        q = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query)
        open(LOG, "a").write(self.headers.get("Authorization", "") + "\n")
        if self.headers.get("Authorization") != f"Bearer {EXPECTED}":
            body, status = {"error": {"code": "UNAUTHORIZED"}}, 401
        else:
            repo = q.get("url", [""])[0].rsplit("/", 1)[-1].lower()
            projects = {"tech1": [ONE], "nobody": [], "twice": [ONE, {**ONE, "id": "p-2", "code": "REMS"}]}.get(repo)
            body, status = ({"error": {"code": "WORKSTATION_READ_ONLY"}}, 403) if projects is None else ({"owner": "content-it", "repo": repo, "cloneUrl": "x", "projects": projects, "targets": []}, 200)
        data = json.dumps(body).encode()
        self.send_response(status); self.send_header("Content-Type", "application/json"); self.end_headers(); self.wfile.write(data)
HTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
PY
PORT=$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1])')
python3 "$T/server.py" "$PORT" "$KEY" "$T/auth.log" & SERVER=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null "http://127.0.0.1:$PORT/" && break; sleep 0.3; done

repo() { mkdir -p "$T/$1" && git -C "$T/$1" init -q && { [ -z "${2:-}" ] || git -C "$T/$1" remote add origin "$2"; }; }
repo tech1 "git@github.com:content-it/Tech1.git"
repo nobody "https://github.com/content-it/nobody"
repo twice "https://github.com/content-it/twice.git"
repo refused "https://github.com/content-it/refused"
repo gitlab "https://gitlab.com/content-it/tech1"
repo bare ""
printf 'QA_WORKSTATION_KEY=%s\nINJAZ_QA_URL=http://127.0.0.1:%s\n' "$KEY" "$PORT" > "$T/qa.env"
run() { QA_ENV_FILE="$T/qa.env" "$RESOLVE" "$@" > "$T/out" 2> "$T/err"; echo $?; }

check "one project → exit 0 and CODE<TAB>name<TAB>owner/repo<TAB>id" '[ "$(run "$T/tech1")" = 0 ] && [ "$(cut -f1 "$T/out")" = TECH ] && [ "$(cut -f3 "$T/out")" = "content-it/Tech1" ] && [ "$(cut -f4 "$T/out")" = p-1 ]'
check "the key travelled in the Authorization header" 'grep -qx "Bearer $KEY" "$T/auth.log"'
check "no project → exit 3 with what to do" '[ "$(run "$T/nobody")" = 3 ] && grep -q "no Injaz technical project" "$T/err" && [ ! -s "$T/out" ]'
check "several projects → exit 4 naming them" '[ "$(run "$T/twice")" = 4 ] && grep -q "TECH, REMS" "$T/err"'
check "Injaz refusal → exit 7 with its code" '[ "$(run "$T/refused")" = 7 ] && grep -q "403 WORKSTATION_READ_ONLY" "$T/err"'
check "not a GitHub origin → exit 5" '[ "$(run "$T/gitlab")" = 5 ] && [ "$(run "$T/bare")" = 5 ]'
check "--json: ok + the projects" '[ "$(run --json "$T/tech1")" = 0 ] && python3 -c "import json;d=json.load(open(\"$T/out\"));assert d[\"ok\"] and d[\"projects\"][0][\"code\"]==\"TECH\""'
check "--json refusal is JSON too" '[ "$(run --json "$T/nobody")" = 3 ] && python3 -c "import json;d=json.load(open(\"$T/out\"));assert d[\"ok\"] is False and d[\"exit\"]==3"'
check "the key is never printed" '! grep -rq "$KEY" "$T/out" "$T/err"'
printf 'INJAZ_QA_URL=http://127.0.0.1:%s\n' "$PORT" > "$T/nokey.env"
check "no key → exit 6, nothing sent" '[ "$(QA_ENV_FILE="$T/nokey.env" "$RESOLVE" "$T/tech1" >/dev/null 2>&1; echo $?)" = 6 ] && [ "$(wc -l < "$T/auth.log" | tr -d " ")" = 7 ]'
printf 'QA_WORKSTATION_KEY=%s\nINJAZ_QA_URL=http://injaz.example.sa\n' "$KEY" > "$T/http.env"
check "a non-https Injaz URL is refused before any request" '[ "$(QA_ENV_FILE="$T/http.env" "$RESOLVE" "$T/tech1" >/dev/null 2>&1; echo $?)" = 7 ]'
printf 'QA_WORKSTATION_KEY=$(touch %s/pwned)\nINJAZ_QA_URL=http://127.0.0.1:%s\n' "$T" "$PORT" > "$T/evil.env"
QA_ENV_FILE="$T/evil.env" "$RESOLVE" "$T/tech1" >/dev/null 2>&1
check "the env file is read, never executed" '[ ! -e "$T/pwned" ]'
kill $SERVER 2>/dev/null; wait $SERVER 2>/dev/null
check "Injaz down → exit 7" '[ "$(run "$T/tech1")" = 7 ] && grep -q "unreachable" "$T/err"'

# ── qa-coverage ──
C="$T/cov"; mkdir -p "$C/e2e" "$C/.maestro/sub" "$C/qa/map"
check "no map → exit 2" '[ "$("$COVERAGE" "$C" >/dev/null 2>&1; echo $?)" = 2 ]'
cat > "$C/qa/map/TECH.scenarios.json" <<'JSON'
{ "project": "TECH", "version": 1, "entries": [
  { "ref": "AUTH-001", "status": "automated", "kind": "web", "spec": "e2e/auth.spec.ts", "tags": ["smoke"] },
  { "ref": "AUTH-002", "status": "automated", "kind": "mobile", "flow": ".maestro/01-login.yaml" },
  { "ref": "PAY-014", "status": "manual", "reason": "دفع حقيقي", "owner": "human" }
] }
JSON
printf "test('دخول [AUTH-001] @smoke', async () => {})\n" > "$C/e2e/auth.spec.ts"
printf "appId: x\n---\n- launchApp\n" > "$C/.maestro/01-login.yaml"
printf "appId: x\n" > "$C/.maestro/sub/helper.yaml"
printf '{"format":"injaz-test-scenarios","scenarios":[{"ref":"AUTH-001"},{"ref":"AUTH-002"},{"ref":"PAY-014"},{"ref":"OLD-001","state":"deprecated"}]}\n' > "$C/injaz-test-scenarios.json"
OUT=$("$COVERAGE" --json "$C"); RC=$?
check "a consistent map → exit 0 and the counts" '[ "$RC" = 0 ] && echo "$OUT" | python3 -c "import json,sys;d=json.load(sys.stdin);assert d[\"counts\"]=={\"automated\":2,\"manual\":1,\"blocked\":0} and d[\"automatedPercent\"]==67 and d[\"problems\"]==[]"'
check "a sub-flow is not a test case" '! echo "$OUT" | grep -q helper.yaml'
B1=$(cat "$C/qa/map/TECH.scenarios.json")
cat > "$C/qa/map/TECH.scenarios.json" <<'JSON'
{ "project": "TECH", "version": 1, "entries": [
  { "ref": "AUTH-001", "status": "automated", "kind": "web", "spec": "e2e/missing.spec.ts" },
  { "ref": "PAY-014", "status": "manual" },
  { "ref": "GHOST-009", "status": "blocked", "reason": "x" }
] }
JSON
printf "test('بحث [SRCH-003]', async () => {})\n" > "$C/e2e/search.spec.ts"
OUT=$("$COVERAGE" "$C"); RC=$?
check "inconsistencies → exit 1, each one listed" '[ "$RC" = 1 ] && echo "$OUT" | grep -q "e2e/missing.spec.ts does not exist" && echo "$OUT" | grep -q "PAY-014: manual without a reason" && echo "$OUT" | grep -q "GHOST-009: not in the scenario library" && echo "$OUT" | grep -q "SRCH-003" && echo "$OUT" | grep -q "01-login.yaml" && echo "$OUT" | grep -q "AUTH-002"'
check "coverage never writes" '[ "$(cat "$C/qa/map/TECH.scenarios.json")" != "$B1" ] && [ -z "$(find "$C" -newer "$C/e2e/search.spec.ts" -type f)" ]'

# ── qa-set-workstation-key ──
SET="$PWD/plugins/maestro-test-e2e/bin/qa-set-workstation-key"
printf 'OTHER=1\nQA_WORKSTATION_KEY=qa_old\nINJAZ_QA_URL=https://injaz-staging.vercel.app\n' > "$T/set.env"
printf 'qa_new_key_123\n' | QA_ENV_FILE="$T/set.env" "$SET" > "$T/set.out"
check "the setter replaces the key, keeps every other line, mode 600" '[ "$(grep -c "^QA_WORKSTATION_KEY=qa_new_key_123$" "$T/set.env")" = 1 ] && ! grep -q qa_old "$T/set.env" && grep -q "^OTHER=1$" "$T/set.env" && grep -q "^INJAZ_QA_URL=https://injaz-staging" "$T/set.env" && [ "$(stat -f %Lp "$T/set.env" 2>/dev/null || stat -c %a "$T/set.env")" = 600 ]'
check "the setter never prints the key" '! grep -q qa_new_key_123 "$T/set.out"'
B2=$(cat "$T/set.env")
check "a key given as an argument is refused, nothing stored" '[ "$(QA_ENV_FILE="$T/set.env" "$SET" qa_in_argv </dev/null >/dev/null 2>&1; echo $?)" = 2 ] && [ "$(cat "$T/set.env")" = "$B2" ]'
check "a value that is not a qa_ key is refused" '[ "$(printf "sk-or-v1-x\n" | QA_ENV_FILE="$T/set.env" "$SET" >/dev/null 2>&1; echo $?)" = 1 ] && [ "$(cat "$T/set.env")" = "$B2" ]'
printf 'qa_k2\n' | QA_ENV_FILE="$T/set.env" "$SET" --url https://www.injaz365.com >/dev/null
check "--url replaces the Injaz URL" '[ "$(grep -c "^INJAZ_QA_URL=" "$T/set.env")" = 1 ] && grep -q "^INJAZ_QA_URL=https://www.injaz365.com$" "$T/set.env"'
check "--url refuses plain http" '[ "$(printf "qa_k3\n" | QA_ENV_FILE="$T/set.env" "$SET" --url http://injaz.example.sa >/dev/null 2>&1; echo $?)" = 2 ]'

echo "qa-plugins: $pass passed, $fail failed"
[ "$fail" = 0 ]
