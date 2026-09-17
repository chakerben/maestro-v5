#!/usr/bin/env node
/**
 * Maestro 5 — context budget guard (5.9.1).
 *
 * Every session pays the skill index (all descriptions) and the routing
 * block; every agent dispatch pays its preloaded skills. Those numbers only
 * ever grow unless something says no. This says no.
 *
 * Budgets are in characters (deterministic; ≈ chars/3.6 tokens for this
 * repo's EN/FR/AR mix). Exit 1 on any breach; prints the bill otherwise.
 */
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const BUDGET = {
  descriptionsTotal: 11000, // all skills, description + when_to_use — paid every session
  descriptionEach: 700,     // platform truncates at 1536; past ~700 a description is a body
  routingMd: 2000,          // <maestro_routing> block — paid every session, every project
  preloadedSkillEach: 4000, // a SKILL.md preloaded into an agent is paid per dispatch
  agentPreloadTotal: 6000,  // agent body + all its preloaded skills
  skillMdEach: 5500,        // any SKILL.md (invocation cost; actions are read one by one)
  hookScriptMs: 100,        // rule #3 — measured here as a smoke test, not a benchmark
};
const tok = (n) => Math.round(n / 3.6);
let bad = 0;
const fail = (m) => { console.error('  ❌ ' + m); bad++; };
const ok = (m) => console.log('  ✅ ' + m);
const fm = (t) => { const m = t.replace(/\r\n/g, '\n').match(/^---\n([\s\S]*?)\n---/); return m ? m[1] : ''; };

console.log('▶ Context budget');
const skills = {}; // id -> { chars, desc }
let descTotal = 0;
for (const p of fs.readdirSync(path.join(ROOT, 'plugins'))) {
  const sd = path.join(ROOT, 'plugins', p, 'skills');
  if (!fs.existsSync(sd)) continue;
  for (const s of fs.readdirSync(sd)) {
    const f = path.join(sd, s, 'SKILL.md');
    if (!fs.existsSync(f)) continue;
    const txt = fs.readFileSync(f, 'utf8');
    const front = fm(txt);
    const desc = ((front.match(/^description:\s*(.*)$/m) || [])[1] || '') + ((front.match(/^when_to_use:\s*(.*)$/m) || [])[1] || '');
    const id = `${p}:${s}`;
    skills[id] = { chars: txt.length, desc: desc.length };
    descTotal += desc.length;
    if (desc.length > BUDGET.descriptionEach) fail(`${id}: description ${desc.length} chars > ${BUDGET.descriptionEach} — move the "what" into the body, keep the "when"`);
    if (txt.length > BUDGET.skillMdEach) fail(`${id}: SKILL.md ${txt.length} chars > ${BUDGET.skillMdEach} — split into actions/ or references/`);
  }
}
if (descTotal > BUDGET.descriptionsTotal) fail(`skill index ${descTotal} chars (≈${tok(descTotal)} tok/session) > ${BUDGET.descriptionsTotal}`);
else ok(`skill index: ${Object.keys(skills).length} skills, ${descTotal} chars ≈ ${tok(descTotal)} tok per session`);

const routing = fs.readFileSync(path.join(ROOT, 'plugins/maestro-core/references/routing.md'), 'utf8');
if (routing.length > BUDGET.routingMd) fail(`routing.md ${routing.length} chars > ${BUDGET.routingMd} — it is paid in every session of every project`);
else ok(`routing block: ${routing.length} chars ≈ ${tok(routing.length)} tok per session`);

console.log('▶ Agent dispatch cost');
const agentsDir = path.join(ROOT, 'plugins/maestro-dev/agents');
for (const a of fs.readdirSync(agentsDir)) {
  const txt = fs.readFileSync(path.join(agentsDir, a), 'utf8');
  const pre = [...fm(txt).matchAll(/^\s+-\s+([a-z0-9-]+:[a-z0-9-]+)\s*$/gm)].map((m) => m[1]);
  let total = txt.length;
  for (const id of pre) {
    const sk = skills[id];
    if (!sk) { fail(`${a}: preloads unknown skill ${id}`); continue; }
    if (sk.chars > BUDGET.preloadedSkillEach) fail(`${a}: preloaded ${id} is ${sk.chars} chars > ${BUDGET.preloadedSkillEach} — trim it or load it on demand`);
    total += sk.chars;
  }
  if (total > BUDGET.agentPreloadTotal) fail(`${a}: ${total} chars per dispatch (≈${tok(total)} tok) > ${BUDGET.agentPreloadTotal}`);
  else ok(`${a}: ≈ ${tok(total)} tok per dispatch (body + ${pre.length} preloaded)`);
}

console.log('▶ Hook wall time (smoke)');
const { spawnSync } = require('child_process');
const os = require('os');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'maestro-budget-'));
fs.mkdirSync(path.join(tmp, 'maestro_docs/memory'), { recursive: true });
fs.writeFileSync(path.join(tmp, 'maestro_docs/memory/a.md'), '# m\n');
fs.writeFileSync(path.join(tmp, 'CLAUDE.md'), '# P\n');
for (const [name, args, input] of [
  ['memory-sync', [path.join(ROOT, 'plugins/maestro-core/hooks/memory-sync.js')], ''],
  ['bash-guard', [path.join(ROOT, 'plugins/maestro-quality/hooks/bash-guard.js')], '{"tool_name":"Bash","tool_input":{"command":"ls"}}'],
]) {
  const t0 = Date.now();
  spawnSync(process.execPath, args, { input, env: { ...process.env, CLAUDE_PROJECT_DIR: tmp } });
  const ms = Date.now() - t0;
  if (ms > BUDGET.hookScriptMs) fail(`${name}: ${ms} ms > ${BUDGET.hookScriptMs} ms (rule #3)`);
  else ok(`${name}: ${ms} ms`);
}
fs.rmSync(tmp, { recursive: true, force: true });

if (bad) { console.error(`${bad} budget breach(es).`); process.exit(1); }
console.log('Within budget.');
