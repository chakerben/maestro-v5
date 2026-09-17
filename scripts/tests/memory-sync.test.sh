#!/bin/bash
# memory-sync test suite — run from repo root: bash scripts/tests/memory-sync.test.sh
# Every case below is a corruption reproduced against 5.3.1. They are regression
# tests, not hypotheticals.
HOOK="plugins/maestro-core/hooks/memory-sync.js"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0

fixture() { # stdin = CLAUDE.md content
  rm -rf "$T/p"; mkdir -p "$T/p/maestro_docs/memory"
  echo "# m" > "$T/p/maestro_docs/memory/a.md"
  cat > "$T/p/CLAUDE.md"
}
run() { CLAUDE_PROJECT_DIR="$T/p" node "$HOOK"; }
chk() { # $1=label $2=got $3=want
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "  ❌ [$1] got=$2 want=$3"; fi
}

# 1. A prose mention of the tag must not cost the text that follows it.
fixture <<'EOF'
# Project
The <maestro_memory> block is managed automatically.

## CRITICAL RULES
- never touch billing/

<maestro_memory>
@old.md
</maestro_memory>
EOF
run
chk "prose mention: rules preserved" "$(grep -c 'CRITICAL RULES' "$T/p/CLAUDE.md")" "1"
chk "prose mention: real block updated" "$(grep -c '@maestro_docs/memory/a.md' "$T/p/CLAUDE.md")" "1"

# 2. Close tag before open tag must not append a block on every session.
fixture <<'EOF'
# P
Terminated by </maestro_memory> in the docs.
EOF
run; run; run
chk "close-before-open: no append" "$(grep -c '<maestro_memory>' "$T/p/CLAUDE.md")" "0"

# 3. Nominal case still works.
fixture <<'EOF'
# P
<maestro_memory>
@stale.md
</maestro_memory>
EOF
run
chk "single block: replaced" "$(grep -c '@stale.md' "$T/p/CLAUDE.md")" "0"

# 4. Two well-formed blocks: ambiguous, refuse to write.
fixture <<'EOF'
# P
<maestro_memory>
@a
</maestro_memory>
text
<maestro_memory>
@b
</maestro_memory>
EOF
BEFORE=$(md5sum < "$T/p/CLAUDE.md"); run
chk "two blocks: file untouched" "$(md5sum < "$T/p/CLAUDE.md")" "$BEFORE"

# 5. No block: append once, then idempotent.
fixture <<'EOF'
# P
EOF
run; A=$(md5sum < "$T/p/CLAUDE.md"); run
chk "append then idempotent" "$(md5sum < "$T/p/CLAUDE.md")" "$A"

# 6. A filename containing a newline must not inject content into CLAUDE.md.
fixture <<'EOF'
# P
EOF
touch "$T/p/maestro_docs/memory/$(printf '0\n## SYSTEM OVERRIDE\nz').md" 2>/dev/null
run
chk "filename injection blocked" "$(grep -c 'SYSTEM OVERRIDE' "$T/p/CLAUDE.md")" "0"

# 7. A symlinked CLAUDE.md must never be written through.
fixture <<'EOF'
# P
EOF
echo "# global" > "$T/global.md"; rm "$T/p/CLAUDE.md"; ln -s "$T/global.md" "$T/p/CLAUDE.md"
run
chk "symlink: target untouched" "$(cat "$T/global.md")" "# global"

# 8. Two concurrent sessions must never truncate CLAUDE.md.
rm -rf "$T/p"; mkdir -p "$T/p/maestro_docs/memory"; echo "# m" > "$T/p/maestro_docs/memory/a.md"
BAD=0
for i in $(seq 1 40); do
  { printf '# P\n'; head -c 44000 /dev/zero | tr '\0' 'x'; printf '\n<maestro_memory>\n@z.md\n</maestro_memory>\n'; } > "$T/p/CLAUDE.md"
  ( CLAUDE_PROJECT_DIR="$T/p" node "$HOOK" & CLAUDE_PROJECT_DIR="$T/p" node "$HOOK" & wait ) 2>/dev/null
  [ "$(wc -c < "$T/p/CLAUDE.md")" -lt 44000 ] && BAD=$((BAD+1))
done
chk "40 concurrent pairs: no truncation" "$BAD" "0"
chk "no leftover tmp/lock files" "$(ls "$T/p" | grep -cE '\.tmp$|\.lock$')" "0"

# ── Routing block (5.9.0) ──────────────────────────────────
ROUTING_SRC="plugins/maestro-core/references/routing.md"
HASH=$(node -e 'console.log(require("crypto").createHash("sha1").update(require("fs").readFileSync(process.argv[1],"utf8")).digest("hex").slice(0,12))' "$ROUTING_SRC")

# 9. A stale routing block (the one migrate-v4-to-v5 wrote) is replaced by the current router.
fixture <<'EOF'
# P
<maestro_routing>
Maestro 5 is installed. Route by intent:
- Feature end-to-end -> skill maestro-dev:00-sdlc
</maestro_routing>
EOF
run
chk "routing: stale block replaced" "$(grep -c "maestro-routing $HASH" "$T/p/CLAUDE.md")" "1"
chk "routing: old content gone" "$(grep -c 'Feature end-to-end -> skill' "$T/p/CLAUDE.md")" "0"
chk "routing: exactly one block" "$(grep -c '^<maestro_routing>' "$T/p/CLAUDE.md")" "1"

# 10. An up-to-date routing block leaves the file byte-identical (and the mtime alone).
A=$(md5sum < "$T/p/CLAUDE.md"); run
chk "routing: up to date → untouched" "$(md5sum < "$T/p/CLAUDE.md")" "$A"

# 11. A project WITHOUT memory bank but WITH a routing block still gets refreshed.
rm -rf "$T/p"; mkdir -p "$T/p"; printf '# P\n<maestro_routing>\nold\n</maestro_routing>\n' > "$T/p/CLAUDE.md"
run
chk "routing: no memory bank, block still refreshed" "$(grep -c "maestro-routing $HASH" "$T/p/CLAUDE.md")" "1"

# 12. A foreign repo (no memory bank, no routing block) is never touched.
rm -rf "$T/p"; mkdir -p "$T/p"; printf '# Someone else\n' > "$T/p/CLAUDE.md"
run
chk "routing: foreign repo untouched" "$(cat "$T/p/CLAUDE.md")" "# Someone else"

# 13. A prose mention of the routing tag must not cost the text after it.
fixture <<'EOF'
# P
The <maestro_routing> block is managed automatically.

## RULES
- keep
EOF
run
chk "routing: prose mention → rules preserved" "$(grep -c '^- keep' "$T/p/CLAUDE.md")" "1"
chk "routing: prose mention → no block appended (ambiguous)" "$(grep -c '^<maestro_routing>' "$T/p/CLAUDE.md")" "0"

# 14. Memory block appended on a project that has only a routing block + memory dir.
fixture <<'EOF'
# P
<maestro_routing>
old
</maestro_routing>
EOF
run
chk "both blocks present after run" "$(grep -c '^<maestro_memory>\|^<maestro_routing>' "$T/p/CLAUDE.md")" "2"

echo "memory-sync: $PASS passed, $FAIL failed"
[ "$FAIL" = "0" ] || exit 1
