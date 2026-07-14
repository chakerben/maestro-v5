#!/usr/bin/env node
/**
 * Maestro 5 — marketplace validator.
 * Checks structure, JSON validity, and Philosophy compliance (hook count).
 * Exit 1 on any failure. Used locally and in CI.
 */
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
let errors = 0;
const fail = (msg) => { console.error('  ❌ ' + msg); errors++; };
const ok = (msg) => console.log('  ✅ ' + msg);

console.log('▶ Marketplace manifest');
const mpPath = path.join(ROOT, '.claude-plugin', 'marketplace.json');
let marketplace;
try {
  marketplace = JSON.parse(fs.readFileSync(mpPath, 'utf8'));
  ok('marketplace.json is valid JSON');
} catch (e) {
  fail('marketplace.json invalid: ' + e.message);
  process.exit(1);
}
if (!marketplace.name) fail('marketplace.name missing');
if (!Array.isArray(marketplace.plugins) || !marketplace.plugins.length)
  fail('marketplace.plugins empty');

console.log('▶ Plugins');
for (const entry of marketplace.plugins) {
  const dir = path.join(ROOT, entry.source);
  if (!fs.existsSync(dir)) { fail(`${entry.name}: source dir missing (${entry.source})`); continue; }
  const manifest = path.join(dir, '.claude-plugin', 'plugin.json');
  try {
    const pj = JSON.parse(fs.readFileSync(manifest, 'utf8'));
    if (pj.name !== entry.name)
      fail(`${entry.name}: plugin.json name mismatch (${pj.name})`);
    else ok(`${entry.name}: manifest valid`);
  } catch (e) {
    fail(`${entry.name}: plugin.json invalid — ${e.message}`);
  }
  // Every SKILL.md must have frontmatter with name + description
  const skillsDir = path.join(dir, 'skills');
  if (fs.existsSync(skillsDir)) {
    for (const s of fs.readdirSync(skillsDir, { withFileTypes: true })) {
      if (!s.isDirectory()) continue;
      const skillMd = path.join(skillsDir, s.name, 'SKILL.md');
      if (!fs.existsSync(skillMd)) { fail(`${entry.name}/${s.name}: SKILL.md missing`); continue; }
      const txt = fs.readFileSync(skillMd, 'utf8');
      const fmMatch = txt.match(/^---\n([\s\S]*?)\n---/);
      const fm = fmMatch ? fmMatch[1] : '';
      if (!/^name:\s*\S+/m.test(fm) || !/^description:\s*\S+/m.test(fm))
        fail(`${entry.name}/${s.name}: SKILL.md frontmatter missing name/description`);
      else ok(`${entry.name}/${s.name}: SKILL.md valid`);
    }
  }
}

console.log('▶ Philosophy rule #1 — max 2 hooks in the whole framework');
let hookCount = 0;
const hookFiles = [];
function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name === 'hooks.json') hookFiles.push(p);
  }
}
walk(path.join(ROOT, 'plugins'));
for (const hf of hookFiles) {
  let cfg;
  try {
    cfg = JSON.parse(fs.readFileSync(hf, 'utf8'));
  } catch (e) {
    fail(`${path.relative(ROOT, hf)}: invalid JSON — ${e.message}`);
    continue;
  }
  for (const event of Object.keys(cfg.hooks || {})) {
    for (const group of cfg.hooks[event]) hookCount += (group.hooks || []).length;
  }
  if (!/\$\{CLAUDE_PLUGIN_ROOT\}/.test(fs.readFileSync(hf, 'utf8')))
    fail(`${path.relative(ROOT, hf)}: hook command must use \${CLAUDE_PLUGIN_ROOT}`);
}
if (hookCount > 2) fail(`${hookCount} hooks found — Philosophy rule #1 allows 2`);
else ok(`${hookCount} hook(s) total — compliant`);

console.log('▶ Philosophy rule #2 — no typecheck/test/format in hooks');
for (const hf of hookFiles) {
  const dir = path.dirname(hf);
  for (const f of fs.readdirSync(dir)) {
    if (!f.endsWith('.js')) continue;
    let src = fs.readFileSync(path.join(dir, f), 'utf8');
    // strip comments before scanning — mentions in comments are fine
    src = src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/[^\n]*/g, '');
    if (/\b(tsc|typecheck|jest|vitest|prettier|eslint)\b/.test(src))
      fail(`${f}: references typecheck/test/format tooling — forbidden in hooks`);
    else ok(`${f}: clean`);
  }
}

console.log('▶ Agents & commands frontmatter');
for (const entry of marketplace.plugins) {
  const dir = path.join(ROOT, entry.source);
  for (const sub of ['agents', 'commands']) {
    const d = path.join(dir, sub);
    if (!fs.existsSync(d)) continue;
    for (const f of fs.readdirSync(d)) {
      if (!f.endsWith('.md')) continue;
      const txt = fs.readFileSync(path.join(d, f), 'utf8');
      const m = txt.match(/^---\n([\s\S]*?)\n---/);
      const fm = m ? m[1] : '';
      const needName = sub === 'agents';
      const okDesc = /^description:\s*\S+/m.test(fm);
      const okName = !needName || /^name:\s*\S+/m.test(fm);
      const okModel = sub !== 'agents' || /^model:\s*(sonnet|opus|haiku|inherit)\b/m.test(fm);
      // Reviewer agents must not carry Edit/Write (Philosophy rule #5 enforcement)
      const isReviewer = /checker|devil-advocate/.test(f);
      const toolsLine = (fm.match(/^tools:\s*(.+)$/m) || [])[1] || '';
      const badTools = isReviewer && (/\b(Edit|Write|MultiEdit)\b/.test(toolsLine) || !toolsLine);
      if (okDesc && okName && okModel && !badTools) ok(`${entry.name}/${sub}/${f}`);
      else if (badTools) fail(`${entry.name}/${sub}/${f}: reviewer agent must declare tools WITHOUT Edit/Write`);
      else fail(`${entry.name}/${sub}/${f}: frontmatter incomplete (needs description${needName ? ', name, model' : ''})`);
    }
  }
}

console.log('');
if (errors) { console.error(`${errors} error(s).`); process.exit(1); }
console.log('All checks passed.');
