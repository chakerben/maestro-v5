#!/usr/bin/env node
/**
 * Maestro 5 — bash-guard.js
 * Hook: PreToolUse(Bash) (the ONLY hook in maestro-quality — Philosophy rule #1)
 *
 * Pure SECURITY gate. Blocks destructive or exfiltrating commands.
 * Nothing else runs here: no quality checks, no typecheck, no format
 * (Philosophy rule #2 — quality lives in the workflow, this is safety only).
 *
 * Note: the official `security-guidance` plugin reviews code diffs for
 * vulnerabilities. This guard covers the complementary surface: the bash
 * commands themselves.
 *
 * Contract (Philosophy rule #3):
 *   - < 20 ms (single stdin read + regex pass, no subprocess)
 *   - exit 0 on internal error (fail open)
 *   - exit 2 + stderr message to BLOCK a dangerous command
 *
 * Claude Code contract: tool input arrives as JSON on stdin:
 *   { "tool_name": "Bash", "tool_input": { "command": "..." } }
 */

'use strict';

const RULES = [
  {
    // rm recursive+force targeting root, home ITSELF, or $HOME itself.
    // Flags in any order: combined (-rf/-fr), separate (-r -f), or long
    // (--recursive --force). Deliberately does NOT block subpaths
    // (rm -rf ~/x/node_modules is legit).
    re: /\brm(?=[^\n]*\s(?:-[a-z]*r[a-z]*|--recursive)\b)(?=[^\n]*\s(?:-[a-z]*f[a-z]*|--force)\b)\s+[^\n]*\s(\/|~\/?|\$HOME\/?|"\$HOME"\/?)\s*(;|&&|\|\||$)/,
    msg: 'BLOCKED: recursive force-delete targeting / or home itself',
  },
  {
    // piped remote execution
    re: /\b(curl|wget)\b[^|;&]*\|\s*(ba|z|da)?sh\b/i,
    msg: 'BLOCKED: piping remote content into a shell',
  },
  {
    re: /\bchmod\s+(777|a\+rwx)\b/,
    msg: 'BLOCKED: world-writable permissions (chmod 777)',
  },
  {
    re: />\s*\/dev\/(sd[a-z]|disk\d)/,
    msg: 'BLOCKED: writing directly to a system disk device',
  },
  {
    // reading secret env files (any path prefix), EXCEPT template files
    // (.env.example/.env.sample/.env.template contain no secrets)
    re: /\b(cat|head|tail|less|more|bat|strings)\s+\S*\.env(\.(?!example\b|sample\b|template\b)\w+)?(\s|;|\||$)/,
    msg: 'BLOCKED: reading a secrets file (.env)',
  },
  {
    // echoing secret-looking env vars
    re: /\becho\s+[^\n]*\$\{?[A-Z_]*(SECRET|PASSWORD|TOKEN|API_KEY)/,
    msg: 'BLOCKED: printing secrets from the environment',
  },
  {
    re: /\bgit\s+push\s+[^\n]*--force(?!-with-lease)\b/,
    msg: 'BLOCKED: git push --force (use --force-with-lease)',
  },
];

function readStdin() {
  try {
    return require('fs').readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function main() {
  const raw = readStdin();
  if (!raw) return 0;

  let cmd = '';
  try {
    const payload = JSON.parse(raw);
    cmd = (payload.tool_input && payload.tool_input.command) || '';
  } catch {
    return 0; // unparseable input: fail open
  }
  if (!cmd) return 0;

  for (const rule of RULES) {
    if (rule.re.test(cmd)) {
      process.stderr.write(rule.msg + '\n');
      return 2;
    }
  }
  return 0;
}

let code = 0;
try {
  code = main();
} catch {
  code = 0; // Philosophy rule #3: fail open on our own bugs
}
process.exit(code);
