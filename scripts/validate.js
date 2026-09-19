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
 *   - a model pin outside the ladder (maestro-core references/model-policy.md):
 *     an agent without a model, an opus pin with no stated criticality, a
 *     think-step not on fable
 */
'use strict';
const fs = require('fs');
const path = require('path');

// Optional root override (argv or MAESTRO_ROOT) so tests can validate a modified copy.
const ROOT = path.resolve(process.argv[2] || process.env.MAESTRO_ROOT || path.join(__dirname, '..'));
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
/**
 * Blank comments and regex literals (and, with `strings`, string literals)
 * with same-length filler. A regex-based strip is not enough: a backtick
 * inside a regex literal (/^\s*(```|~~~)/) opened a phantom template string
 * and swallowed most of the file, so an injected execSync passed as "clean".
 */
function blankJs(src, { strings }) {
  let out = '', i = 0, prev = '';
  const keep = (c) => { out += c; if (!/\s/.test(c)) prev = c; };
  const skip = (c) => { out += c === '\n' ? '\n' : ' '; };
  while (i < src.length) {
    const c = src[i], n = src[i + 1];
    if (c === '/' && n === '/') { while (i < src.length && src[i] !== '\n') skip(src[i++]); continue; }
    if (c === '/' && n === '*') { const e = src.indexOf('*/', i + 2); const end = e < 0 ? src.length : e + 2; while (i < end) skip(src[i++]); continue; }
    if (c === "'" || c === '"' || c === '`') {
      const q = c; (strings ? skip : keep)(src[i++]);
      while (i < src.length && src[i] !== q) { if (src[i] === '\\') (strings ? skip : keep)(src[i++]); if (i < src.length) (strings ? skip : keep)(src[i++]); }
      if (i < src.length) (strings ? skip : keep)(src[i++]);
      prev = ')'; // a string is an operand: a `/` after it is division
      continue;
    }
    // A `/` after an operand is division; otherwise it opens a regex literal.
    if (c === '/' && !/[\w$)\]]/.test(prev)) {
      skip(src[i++]); let cls = false;
      while (i < src.length && src[i] !== '\n' && (cls || src[i] !== '/')) {
        if (src[i] === '\\') skip(src[i++]); else if (src[i] === '[') cls = true; else if (src[i] === ']') cls = false;
        if (i < src.length) skip(src[i++]);
      }
      if (i < src.length) skip(src[i++]);
      while (/[a-z]/.test(src[i] || '')) skip(src[i++]);
      prev = ')';
      continue;
    }
    keep(src[i++]);
  }
  return out;
}
for (const p of hookScripts) {
  const raw = read(p);
  const code = blankJs(raw, { strings: false }); // strings kept: require('child_process') is a string
  const bare = blankJs(raw, { strings: true }); // strings gone: "run tsc" in a message is not a call
  const spawn = /\b(require|import)\s*\(\s*['"`](child_process|worker_threads)['"`]/.exec(code)
    || /\bfrom\s+['"](child_process|worker_threads)['"]/.exec(code)
    || /\b(execSync|execFileSync|spawnSync|execFile|spawn|fork)\s*\(/.exec(bare)
    || /(?<![.\w$])exec\s*\(/.exec(bare); // `.exec(` is RegExp.prototype.exec
  const tooling = /\b(tsc|typecheck|jest|vitest|prettier|eslint|npx)\b/.exec(bare);
  if (spawn) fail(`${rel(p)}: uses ${spawn[spawn.length - 1]} — a hook must not spawn processes (rule #2/#3)`);
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
      if (isAgent && !/^model:\s*(sonnet|fable|opus|inherit)\b/m.test(fm)) problems.push('model (sonnet | fable | opus | inherit)');
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

// ── Model policy (maestro-core references/model-policy.md) ──────────
// sonnet executes, fable thinks, opus only when critical. The ladder is
// instructed everywhere else; here the pins that carry it are checked.
console.log('▶ Model policy');
{
  const MODELS = new Set(['sonnet', 'fable', 'opus', 'inherit']);
  const THINK = new Set(['maestro-dev:01-plan', 'maestro-dev:03-brainstorm', 'agent m-architect', 'agent m-analyst', 'agent checker']);
  const pinned = []; // { tag, model, body }
  for (const { name, dir } of pluginDirs) {
    const sd = path.join(dir, 'skills');
    if (fs.existsSync(sd)) for (const s of fs.readdirSync(sd)) {
      const f = path.join(sd, s, 'SKILL.md');
      if (fs.existsSync(f)) pinned.push({ tag: `${name}:${s}`, file: f, agent: false });
    }
    const ad = path.join(dir, 'agents');
    if (fs.existsSync(ad)) for (const a of fs.readdirSync(ad)) {
      if (a.endsWith('.md')) pinned.push({ tag: `agent ${a.slice(0, -3)}`, file: path.join(ad, a), agent: true });
    }
  }
  let bad = 0;
  for (const { tag, file, agent } of pinned) {
    const txt = read(file);
    const model = (frontmatter(txt).match(/^model:\s*(\S+)/m) || [])[1];
    if (agent && !MODELS.has(model || '')) { fail(`${tag}: model "${model || '(none)'}" — every agent pins sonnet | fable | opus | inherit`); bad++; }
    if (model === 'opus' && !/\b(critical|security)\b/i.test(txt)) { fail(`${tag}: pins opus without saying "critical" or "security" in its body — opus is for critical work only`); bad++; }
    if (THINK.has(tag) && model !== 'fable') { fail(`${tag}: is a think-step, the ladder pins it to fable (got ${model || '(none)'})`); bad++; }
  }
  const missing = [...THINK].filter((t) => !pinned.some((p) => p.tag === t));
  if (missing.length) { fail(`model policy names think-steps that do not exist: ${missing.join(', ')}`); bad++; }
  if (!bad) ok(`${pinned.length} skills/agents on the ladder — opus pins justified, think-steps on fable`);
}

// ── Cross-references: every skill/agent the router names must exist ──
// ── Mirrored assets stay byte-identical to their source ──────────────────
console.log('▶ Mirrored assets');
{
  const mirrors = [
    ['plugins/maestro-vcs/skills/00-commit/assets/secret-patterns.md',
     'plugins/maestro-dev/skills/02-implement/assets/secret-patterns.md'],
  ];
  for (const [src, dst] of mirrors) {
    const a = path.join(ROOT, src), b = path.join(ROOT, dst);
    if (!fs.existsSync(b)) continue;
    // The mirror may carry a leading "Mirror of …" comment line; compare the table rows only.
    const rows = (t) => read(t).split('\n').filter((l) => /^\|\s*`/.test(l)).join('\n');
    if (rows(a) !== rows(b)) fail(`${dst} drifted from ${src} — copy the table rows over`);
    else ok(`${dst} mirrors ${src}`);
  }
}

console.log('▶ Router references');
{
  const knownAgents = new Set();
  for (const { dir } of pluginDirs) {
    const d = path.join(dir, 'agents');
    if (fs.existsSync(d)) for (const f of fs.readdirSync(d)) if (f.endsWith('.md')) knownAgents.add(f.slice(0, -3));
  }
  const routers = [
    'plugins/maestro-core/references/routing.md',
    'plugins/maestro-core/commands/maestro.md',
    'scripts/install-shortcuts.sh',
  ];
  for (const r of routers) {
    const p = path.join(ROOT, r);
    if (!fs.existsSync(p)) { fail(`${r}: missing`); continue; }
    const txt = read(p);
    const missing = new Set();
    for (const [, ref] of txt.matchAll(/\b(maestro-[a-z]+:\d{2}-[a-z0-9-]+)/g)) if (!knownSkills.has(ref)) missing.add(ref);
    if (r.endsWith('routing.md'))
      for (const m of txt.matchAll(/\bagent\s+([a-z0-9-]+)|\b(m-[a-z0-9-]+)\b/g)) {
        const a = m[1] || m[2];
        if (!knownAgents.has(a)) missing.add(`agent ${a}`);
      }
    if (missing.size) fail(`${r}: references that do not exist: ${[...missing].join(', ')}`);
    else ok(`${r}: every skill/agent reference resolves`);
  }
}

// ── Frontmatter keys the platform does not document (warning only) ──
console.log('▶ Frontmatter keys');
{
  // Documented at https://code.claude.com/docs/en/skills (checked 2026-09-19).
  const SKILL_KEYS = new Set(['name', 'description', 'argument-hint', 'arguments', 'allowed-tools', 'disallowed-tools', 'disable-model-invocation', 'user-invocable', 'paths', 'model', 'effort', 'context', 'agent', 'background', 'shell', 'hooks', 'when_to_use', 'license', 'compatibility', 'metadata', 'version']);
  // Documented at https://code.claude.com/docs/en/sub-agents (checked 2026-09-19); `role` is Maestro's own key.
  const AGENT_KEYS = new Set(['name', 'description', 'model', 'tools', 'disallowedTools', 'maxTurns', 'skills', 'role', 'permissionMode', 'color', 'hooks', 'effort', 'mcpServers', 'memory', 'background', 'omitClaudeMd', 'isolation', 'initialPrompt', 'experimental']);
  let warned = 0;
  for (const { name, dir } of pluginDirs) {
    for (const [sub, allowed, file] of [['skills', SKILL_KEYS, 'SKILL.md'], ['agents', AGENT_KEYS, null]]) {
      const d = path.join(dir, sub);
      if (!fs.existsSync(d)) continue;
      for (const e of fs.readdirSync(d)) {
        const p = file ? path.join(d, e, file) : path.join(d, e);
        if (!fs.existsSync(p) || !p.endsWith('.md')) continue;
        const keys = [...frontmatter(read(p)).matchAll(/^([A-Za-z_-]+):/gm)].map((m) => m[1]);
        const unknown = keys.filter((k) => !allowed.has(k));
        if (unknown.length) { warned++; console.warn(`  ⚠️  ${name}/${sub}/${e}: undocumented frontmatter key(s): ${unknown.join(', ')} — the platform ignores them`); }
      }
    }
  }
  if (!warned) ok('no undocumented frontmatter keys');
}

console.log('');
if (errors) { console.error(`${errors} error(s).`); process.exit(1); }
console.log('All checks passed.');
