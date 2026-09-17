#!/usr/bin/env node
/**
 * Maestro 5 — marketplace validator.
 * Checks structure, JSON validity, and Philosophy compliance.
 * Exit 1 on any failure. Used locally and in CI (via `npm test`).
 *
 * What it guards against, concretely (5.3.1 P0-3, closed in 5.6.0):
 *   - a hook smuggled through the `hooks` key of a plugin.json, a
 *     hooks-*.json, or a versioned .claude/settings.json at the repo root
 *   - a hook script that spawns processes or runs test/format tooling
 *   - a reviewer agent (frontmatter `role: reviewer`) carrying a tool that
 *     can write
 *   - a skill with no `## Test` anywhere (Philosophy rule #4, two shapes)
 */
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
let errors = 0;
const fail = (msg) => { console.error('  ❌ ' + msg); errors++; };
const ok = (msg) => console.log('  ✅ ' + msg);
const rel = (p) => path.relative(ROOT, p);
const read = (p) => fs.readFileSync(p, 'utf8');
const frontmatter = (txt) => {
  const m = txt.replace(/\r\n/g, '\n').match(/^---\n([\s\S]*?)\n---/);
  return m ? m[1] : '';
};

// ── Marketplace manifest ───────────────────────────────────
console.log('▶ Marketplace manifest');
const mpPath = path.join(ROOT, '.claude-plugin', 'marketplace.json');
let marketplace;
try {
  marketplace = JSON.parse(read(mpPath));
  ok('marketplace.json is valid JSON');
} catch (e) {
  fail('marketplace.json invalid: ' + e.message);
  process.exit(1);
}
if (!marketplace.name) fail('marketplace.name missing');
if (!Array.isArray(marketplace.plugins) || !marketplace.plugins.length)
  fail('marketplace.plugins empty');
for (const entry of marketplace.plugins) {
  for (const k of ['recommended']) {
    if (k in entry) fail(`${entry.name}: marketplace key "${k}" is not documented by the platform (use defaultEnabled / relevance)`);
  }
}

// ── Plugins, skills (rule #4) ──────────────────────────────
console.log('▶ Plugins & skills');
const pluginDirs = [];
const knownPlugins = new Set(marketplace.plugins.map((e) => e.name));
const knownSkills = new Set(); // "plugin:skill"
for (const entry of marketplace.plugins) {
  const dir = path.join(ROOT, entry.source);
  if (!fs.existsSync(dir)) { fail(`${entry.name}: source dir missing (${entry.source})`); continue; }
  pluginDirs.push({ name: entry.name, dir });
  const manifest = path.join(dir, '.claude-plugin', 'plugin.json');
  try {
    const pj = JSON.parse(read(manifest));
    if (pj.name !== entry.name) fail(`${entry.name}: plugin.json name mismatch (${pj.name})`);
    else ok(`${entry.name}: manifest valid`);
    if (Array.isArray(pj.dependencies) && pj.dependencies.length)
      fail(`${entry.name}: "dependencies" is forbidden — the platform resolves it per scope, and on a user-scope core + project-scope plugins install (the fleet's shape) every dependent plugin fails to load and cannot be updated (5.9.3 incident)`);
  } catch (e) {
    fail(`${entry.name}: plugin.json invalid — ${e.message}`);
  }
  const skillsDir = path.join(dir, 'skills');
  if (!fs.existsSync(skillsDir)) continue;
  for (const s of fs.readdirSync(skillsDir, { withFileTypes: true })) {
    if (!s.isDirectory()) continue;
    const skillDir = path.join(skillsDir, s.name);
    const skillMd = path.join(skillDir, 'SKILL.md');
    const tag = `${entry.name}/${s.name}`;
    if (!fs.existsSync(skillMd)) { fail(`${tag}: SKILL.md missing`); continue; }
    const txt = read(skillMd);
    const fm = frontmatter(txt);
    const name = (fm.match(/^name:\s*(\S+)/m) || [])[1];
    knownSkills.add(`${entry.name}:${s.name}`);
    if (!name || !/^description:\s*\S+/m.test(fm)) { fail(`${tag}: SKILL.md frontmatter missing name/description`); continue; }
    // A skill that injects live context (!`cmd`) must pre-approve Bash, or a
    // permission prompt aborts the invocation.
    if (/(^|\s)!`/m.test(txt) && !/^allowed-tools:\s*\S/m.test(fm))
      fail(`${tag}: uses !\`cmd\` injection but declares no allowed-tools`);
    if (name !== s.name) fail(`${tag}: frontmatter name "${name}" ≠ directory name`);
    // Rule #4: router (every action has ## Test) or contract (SKILL.md has ## Test)
    const actionsDir = path.join(skillDir, 'actions');
    if (fs.existsSync(actionsDir)) {
      const actions = fs.readdirSync(actionsDir).filter((f) => f.endsWith('.md'));
      if (!actions.length) fail(`${tag}: actions/ exists but is empty`);
      const untested = actions.filter((f) => !/^## Test\b/m.test(read(path.join(actionsDir, f))));
      if (untested.length) fail(`${tag}: actions without a "## Test" section: ${untested.join(', ')}`);
      else ok(`${tag}: router skill, ${actions.length} action(s) tested`);
    } else if (/^## Test\b/m.test(txt)) {
      ok(`${tag}: contract skill, has ## Test`);
    } else {
      fail(`${tag}: no actions/ and no "## Test" in SKILL.md (Philosophy rule #4)`);
    }
  }
}

// dependency cycles
{
  const deps = {};
  for (const { name, dir } of pluginDirs) {
    try { deps[name] = (JSON.parse(read(path.join(dir, '.claude-plugin', 'plugin.json'))).dependencies || []).map((d) => (typeof d === 'string' ? d : d.name)); }
    catch { deps[name] = []; }
  }
  const seen = new Set();
  const visit = (n, stack) => {
    if (stack.includes(n)) { fail(`dependency cycle: ${[...stack, n].join(' → ')}`); return; }
    if (seen.has(n)) return;
    for (const d of deps[n] || []) visit(d, [...stack, n]);
    seen.add(n);
  };
  for (const n of Object.keys(deps)) visit(n, []);
}

// ── Rule #1: hooks, wherever they could be declared ────────
console.log('▶ Philosophy rule #1 — max 2 hooks in the whole framework');
const hookSources = []; // { file, cfg }
function walk(dir, onFile) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) { if (e.name !== 'node_modules' && e.name !== '.git') walk(p, onFile); }
    else onFile(p, e.name);
  }
}
walk(ROOT, (p, name) => {
  if (/^hooks.*\.json$/.test(name)) hookSources.push({ file: p, key: null });
  if (name === 'plugin.json') hookSources.push({ file: p, key: 'hooks' });
  if (/^settings(\.local)?\.json$/.test(name) && path.basename(path.dirname(p)) === '.claude')
    hookSources.push({ file: p, key: 'hooks', rootSettings: true });
});
let hookCount = 0;
const hookCommands = [];
for (const src of hookSources) {
  let cfg;
  try { cfg = JSON.parse(read(src.file)); }
  catch (e) { fail(`${rel(src.file)}: invalid JSON — ${e.message}`); continue; }
  let hooks = src.key ? cfg[src.key] : cfg.hooks;
  if (src.key === 'hooks' && (typeof hooks === 'string' || Array.isArray(hooks))) {
    // plugin.json may point at one or several hook files (documented forms).
    // Refuse the indirection AND count what it points to, so a smuggled file
    // still trips rule #1 even if someone deletes the first check.
    const targets = Array.isArray(hooks) ? hooks : [hooks];
    fail(`${rel(src.file)}: "hooks" points to ${JSON.stringify(targets)} — declare hooks in hooks/hooks.json only, so rule #1 stays checkable`);
    for (const t of targets) {
      if (typeof t !== 'string') continue;
      const tp = path.resolve(path.dirname(src.file), '..', t.replace(/^\$\{CLAUDE_PLUGIN_ROOT\}\/?/, ''));
      try {
        const sub = JSON.parse(read(tp));
        for (const event of Object.keys(sub.hooks || {}))
          for (const group of sub.hooks[event] || [])
            for (const h of group.hooks || []) { hookCount++; hookCommands.push({ file: tp, event, h }); }
      } catch { fail(`${rel(src.file)}: hooks target "${t}" unreadable`); }
    }
    continue;
  }
  if (!hooks) continue;
  if (src.rootSettings) fail(`${rel(src.file)}: hooks declared in a versioned settings.json — forbidden (this is how v4 came back)`);
  for (const event of Object.keys(hooks)) {
    for (const group of hooks[event] || []) {
      for (const h of group.hooks || []) {
        hookCount++;
        hookCommands.push({ file: src.file, event, h });
      }
    }
  }
}
for (const { file, event, h } of hookCommands) {
  const cmd = h.command || '';
  if (h.type === 'command' && !/\$\{CLAUDE_PLUGIN_ROOT\}/.test(cmd))
    fail(`${rel(file)} [${event}]: command must use \${CLAUDE_PLUGIN_ROOT} (got: ${cmd})`);
  if (typeof h.timeout !== 'number')
    fail(`${rel(file)} [${event}]: hook has no "timeout" (rule #5: hooks carry a platform timeout)`);
}
// Skills and agents can register hooks through their own frontmatter
// (`hooks:` key) — those run for the rest of the session. Rule #1 covers them.
walk(path.join(ROOT, 'plugins'), (p, name) => {
  if (!name.endsWith('.md')) return;
  const fm = frontmatter(read(p));
  if (/^hooks:/m.test(fm)) fail(`${rel(p)}: frontmatter declares hooks — rule #1 allows hooks in hooks/hooks.json only`);
});
if (hookCount > 2) fail(`${hookCount} hooks found — Philosophy rule #1 allows 2`);
else ok(`${hookCount} hook(s) total across ${hookSources.length} candidate file(s) — compliant`);

// ── Rule #2: hook scripts must not spawn or run tooling ────
console.log('▶ Philosophy rule #2 — no typecheck/test/format, no subprocess in hooks');
const hookScripts = new Set();
for (const { h } of hookCommands) {
  const m = (h.command || '').match(/\$\{CLAUDE_PLUGIN_ROOT\}\/(\S+)/);
  if (!m) continue;
  for (const { dir } of pluginDirs) {
    const p = path.join(dir, m[1]);
    if (fs.existsSync(p)) hookScripts.add(p);
  }
}
for (const p of hookScripts) {
  let src = read(p);
  // Strip comments AND string literals: a URL in a string must not eat the
  // line, and a forbidden word inside a message string is not a call.
  src = src
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/(^|[^:\\])\/\/[^\n]*/g, '$1')
    .replace(/'(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*"|`(?:[^`\\]|\\.)*`/g, '""');
  const spawn = /\b(child_process|execSync|spawnSync|execFileSync|spawn|exec|fork|worker_threads)\b/.exec(src);
  const tooling = /\b(tsc|typecheck|jest|vitest|prettier|eslint|npx)\b/.exec(src);
  if (spawn) fail(`${rel(p)}: uses ${spawn[1]} — a hook must not spawn processes (rule #2/#3)`);
  else if (tooling) fail(`${rel(p)}: references ${tooling[1]} — forbidden in hooks`);
  else ok(`${rel(p)}: clean`);
}
if (hookCommands.length && !hookScripts.size) fail('hook commands found but no script resolved — check the command paths');

// ── Agents & commands (rule #5) ────────────────────────────
console.log('▶ Agents & commands frontmatter');
const REVIEWER_ALLOWLIST = new Set(['Read', 'Grep', 'Glob', 'WebFetch', 'WebSearch', 'Bash']);
for (const { name, dir } of pluginDirs) {
  for (const sub of ['agents', 'commands']) {
    const d = path.join(dir, sub);
    if (!fs.existsSync(d)) continue;
    for (const f of fs.readdirSync(d)) {
      if (!f.endsWith('.md')) continue;
      const tag = `${name}/${sub}/${f}`;
      const fm = frontmatter(read(path.join(d, f)));
      const isAgent = sub === 'agents';
      const problems = [];
      if (!/^description:\s*\S+/m.test(fm)) problems.push('description');
      if (isAgent && !/^name:\s*\S+/m.test(fm)) problems.push('name');
      if (isAgent && !/^model:\s*(sonnet|opus|haiku|inherit)\b/m.test(fm)) problems.push('model');
      const role = (fm.match(/^role:\s*(\S+)/m) || [])[1];
      const toolsLine = (fm.match(/^tools:\s*(.+)$/m) || [])[1] || '';
      const tools = toolsLine.split(/[,\s]+/).filter(Boolean);
      if (isAgent && !['reviewer', 'builder', 'advisor'].includes(role))
        problems.push('every agent declares role: reviewer | builder | advisor (rule #5 keys on it, not on the file name)');
      const descLine = (fm.match(/^description:\s*(.+)$/m) || [])[1] || '';
      const descNoNeg = descLine.replace(/\b(never|not|no)\s+\w+/gi, ''); // "never judges its own work" is not a reviewer
      if (isAgent && role !== 'reviewer' && /\b(review|judge|audit|verif|critique|challenge)/i.test(f + ' ' + descNoNeg))
        problems.push('description says it reviews/judges but role is not reviewer');
      const disallowedLine = (fm.match(/^disallowedTools:\s*(.+)$/m) || [])[1] || '';
      const disallowed = disallowedLine.split(/[,\s]+/).filter(Boolean);
      if (isAgent) {
        const skillRefs = [...fm.matchAll(/^\s+-\s+([a-z0-9-]+:[a-z0-9-]+)\s*$/gm)].map((m) => m[1]);
        for (const ref of skillRefs) if (!knownSkills.has(ref)) problems.push(`preloads unknown skill "${ref}"`);
      }
      if (role === 'reviewer') {
        if (!tools.length) problems.push('reviewer without a tools: allowlist');
        const bad = tools.filter((t) => !REVIEWER_ALLOWLIST.has(t));
        if (bad.length) problems.push(`reviewer carries non-allowlisted tool(s): ${bad.join(', ')}`);
        for (const t of ['Write', 'Edit']) if (!disallowed.includes(t)) problems.push(`reviewer must list ${t} in disallowedTools (belt and braces)`);
        if (!/^maxTurns:\s*\d+/m.test(fm)) problems.push('reviewer without maxTurns');
        if (tools.includes('Bash') && !/instructed,\s+not enforced/i.test(read(path.join(d, f))))
          problems.push('reviewer with Bash must say "instructed, not enforced" in its body');
      }
      if (problems.length) fail(`${tag}: ${problems.join('; ')}`);
      else ok(tag);
    }
  }
}

console.log('');
if (errors) { console.error(`${errors} error(s).`); process.exit(1); }
console.log('All checks passed.');
