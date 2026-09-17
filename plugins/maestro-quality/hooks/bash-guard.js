#!/usr/bin/env node
/**
 * Maestro 5 — bash-guard.js
 * Hook: PreToolUse(Bash) (the ONLY hook in maestro-quality — Philosophy rule #1)
 *
 * ACCIDENT GUARD, not a security boundary. It blocks the canonical spellings
 * of a few irreversible commands so a slip of the model ("rm -rf ~" instead
 * of "rm -rf ~/x") is caught before it runs. It does NOT try to stop a caller
 * that wants to get around it: regexes over one line of shell never will
 * (subshells, $(...), eval, scripts on disk, aliases). The 5.3.1 audit listed
 * 45 bypasses; the 5.5.0 audit re-confirmed 30. That is the nature of the
 * tool, and it is stated here so nobody relies on it for more.
 *
 * The ENFORCED layer is the platform: `permissions.deny` in settings.json
 * (Philosophy rule #8 — never rebuild what Anthropic maintains). This guard
 * is the belt; that is the braces.
 *
 * Nothing else runs here: no quality checks, no typecheck, no format
 * (Philosophy rule #2 — quality lives in the workflow, this is safety only).
 *
 * Contract (Philosophy rule #3):
 *   - one stdin read + one regex pass, no subprocess (≈ Node start-up time,
 *     40–60 ms measured; the work itself is < 1 ms)
 *   - exit 0 on internal error (fail open)
 *   - exit 2 + stderr message to BLOCK a dangerous command
 *
 * Claude Code contract: tool input arrives as JSON on stdin:
 *   { "tool_name": "Bash", "tool_input": { "command": "..." } }
 */

'use strict';

const RULES = [
  {
    // rm recursive+force targeting root, root wildcard, home ITSELF, or
    // $HOME itself. Flags in any order: combined (-rf/-fr/-Rf), separate
    // (-r -f), or long (--recursive --force). Deliberately does NOT block
    // subpaths (rm -rf ~/x/node_modules is legit). A trailing "# comment"
    // is tolerated.
    re: /\brm(?=[^\n]*\s(?:-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)\b)(?=[^\n]*\s(?:-[a-zA-Z]*f[a-zA-Z]*|--force)\b)\s+[^\n]*\s(\/\*?|~\/?|\$HOME\/?|"\$HOME"\/?|\$\{HOME\}\/?|"\$\{HOME\}"\/?)\s*(;|&&|\|\||#|$)/,
    msg: 'BLOCKED: recursive force-delete targeting / or home itself',
  },
  {
    // piped remote execution — also via sudo, and process substitution
    re: /\b(curl|wget)\b[^|;&]*\|\s*(sudo\s+)?(ba|z|da)?sh\b|\b(ba|z|da)?sh\s+<\(\s*(curl|wget)\b/i,
    msg: 'BLOCKED: piping remote content into a shell',
  },
  {
    re: /\bchmod\s+(?:-[a-zA-Z]+\s+)*0?777\b|\bchmod\s+(?:-[a-zA-Z]+\s+)*a\+rwx\b/,
    msg: 'BLOCKED: world-writable permissions (chmod 777)',
  },
  {
    re: />\s*\/dev\/(sd[a-z]|disk\d|nvme\d)|\bdd\b[^\n]*\bof=\/dev\/(sd[a-z]|disk\d|nvme\d)|\bmkfs(\.\w+)?\s+[^\n]*\/dev\//,
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
    re: /\bgit\s+push(?=[^\n]*(\s--force(?!-with-lease)\b|\s-f\b|\s\+\w))/,
    msg: 'BLOCKED: git push --force / -f / +ref (use --force-with-lease)',
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
