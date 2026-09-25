#!/bin/bash
# validate.js negative tests — run from repo root: bash scripts/tests/validate.test.sh
# Each case copies the repo to a temp root, breaks ONE thing, and expects
# validate.js (pointed at the copy via its root argument) to go red.
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
chk() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "  ❌ [$1] got=$2 want=$3"; fi; }

fresh() { # a clean copy of the repo at $T/r
  rm -rf "$T/r"; mkdir -p "$T/r"
  cp -R .claude-plugin plugins scripts "$T/r/"
}
red() { # $1=label — validate.js on $T/r must exit ≠ 0 and print $2
  local out; out=$(node scripts/validate.js "$T/r" 2>&1); local code=$?
  chk "$1: exit ≠ 0" "$([ "$code" -ne 0 ] && echo red || echo green)" "red"
  chk "$1: names the cause" "$(echo "$out" | grep -q "$2" && echo yes || echo no)" "yes"
}

# 0. Sanity: the untouched copy is green.
fresh
node scripts/validate.js "$T/r" >/dev/null 2>&1
chk "clean copy: green" "$?" "0"
MAESTRO_ROOT="$T/r" node scripts/validate.js >/dev/null 2>&1
chk "clean copy via MAESTRO_ROOT: green" "$?" "0"

# 1. execSync injected in a hook script after 'use strict' (the 5.10.0 regression:
#    a backtick inside a regex literal hid everything that followed).
fresh
node -e '
  const fs=require("fs"), f=process.argv[1];
  fs.writeFileSync(f, fs.readFileSync(f,"utf8").replace("\x27use strict\x27;", "\x27use strict\x27;\nrequire(\x27child_process\x27).execSync(\x27true\x27);"));
' "$T/r/plugins/maestro-core/hooks/memory-sync.js"
red "injected execSync" "must not spawn"

# 1b. Same, injected at the END of the file (past the regex literal).
fresh
printf '\nconst cp = require("child_process"); cp.spawnSync("true");\n' >> "$T/r/plugins/maestro-core/hooks/memory-sync.js"
red "execSync appended at EOF" "must not spawn"

# 2. plugin.json with dependencies (Philosophy rule #7b).
fresh
node -e '
  const fs=require("fs"), f=process.argv[1]; const j=JSON.parse(fs.readFileSync(f,"utf8"));
  j.dependencies=["maestro-core"]; fs.writeFileSync(f, JSON.stringify(j,null,2));
' "$T/r/plugins/maestro-vcs/.claude-plugin/plugin.json"
red "plugin.json dependencies" "dependencies"

# 3. routing.md naming a skill that does not exist.
fresh
printf -- '- ghost → maestro-dev:99-ghost\n' >> "$T/r/plugins/maestro-core/references/routing.md"
red "routing.md → unknown skill" "99-ghost"

# 4. routing.md naming an agent that does not exist.
fresh
printf -- '- ghost → agent m-ghost\n' >> "$T/r/plugins/maestro-core/references/routing.md"
red "routing.md → unknown agent" "m-ghost"

# 5. A skill with an undocumented frontmatter key is a WARNING, not an error.
fresh
node -e '
  const fs=require("fs"), f=process.argv[1];
  fs.writeFileSync(f, fs.readFileSync(f,"utf8").replace(/^---\n/, "---\nbogus-key: 1\n"));
' "$T/r/plugins/maestro-core/skills/03-condense/SKILL.md"
OUT=$(node scripts/validate.js "$T/r" 2>&1); CODE=$?
chk "unknown frontmatter key: still green" "$CODE" "0"
chk "unknown frontmatter key: warned" "$(echo "$OUT" | grep -c 'bogus-key')" "1"

# 6. An agent with no model pin (the ladder needs every agent to declare one).
fresh
node -e '
  const fs=require("fs"), f=process.argv[1];
  fs.writeFileSync(f, fs.readFileSync(f,"utf8").replace(/^model: .*\n/m, ""));
' "$T/r/plugins/maestro-dev/agents/executor.md"
red "agent without model" "model"

# 7. A skill pinned to opus with no "critical"/"security" in its body.
fresh
node -e '
  const fs=require("fs"), f=process.argv[1];
  fs.writeFileSync(f, fs.readFileSync(f,"utf8").replace(/^---\n/, "---\nmodel: opus\n"));
' "$T/r/plugins/maestro-core/skills/01-memory/SKILL.md"
red "opus pin without justification" "opus"

# 8. The 5.12.1 fiction: a body promising that a dispatch overrides a pin.
#    Frontmatter carries one model; "dispatch X with model: opus" can never
#    happen, and three such escalations shipped believed-real (rule 5).
fresh
printf -- '\n- The orchestrator dispatches me with model: opus when the change is critical.\n' >> "$T/r/plugins/maestro-dev/agents/checker.md"
red "dispatch overriding a pinned model" "cannot override"

# 8b. The quoted counter-example stays legal (model-policy.md forbids the
#     phrasing by quoting it) — the negation must be adjacent, not anywhere.
fresh
printf -- '\nGoing up means dispatching another agent, never "dispatching it with model: opus".\n' >> "$T/r/plugins/maestro-dev/agents/checker.md"
node scripts/validate.js "$T/r" >/dev/null 2>&1
chk "quoted counter-example: still green" "$?" "0"

# 9. Promising opus without naming an agent that is pinned to opus.
fresh
printf -- '\nEscalate to opus when the analysis is unsure.\n' >> "$T/r/plugins/maestro-core/skills/01-memory/SKILL.md"
red "opus promised, no opus agent named" "without naming an opus-pinned agent"

# 10. The executor back on the cheapest tier: the code-writing step is where
#     local architecture is decided (5.13.0).
fresh
node -e '
  const fs=require("fs"), f=process.argv[1];
  fs.writeFileSync(f, fs.readFileSync(f,"utf8").replace(/^model: fable$/m, "model: sonnet"));
' "$T/r/plugins/maestro-dev/agents/executor.md"
red "executor demoted to sonnet" "fable or above"

# 11. The opus rung demoted: the escalations would become fiction again.
fresh
node -e '
  const fs=require("fs"), f=process.argv[1];
  fs.writeFileSync(f, fs.readFileSync(f,"utf8").replace(/^model: opus$/m, "model: fable"));
' "$T/r/plugins/maestro-dev/agents/checker-critical.md"
red "checker-critical demoted" "opus rung"

# 12. The opus rung deleted entirely.
fresh
rm "$T/r/plugins/maestro-dev/agents/m-deep-analyst.md"
red "m-deep-analyst removed" "does not exist"

echo "validate: $PASS passed, $FAIL failed"
[ "$FAIL" = "0" ] || exit 1
