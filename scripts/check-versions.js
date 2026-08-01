#!/usr/bin/env node
/**
 * Maestro 5 — version drift guard.
 *
 * The version lives in 9 files by hand. 5.2.1 already shipped a fix for
 * "versions aligned across marketplace + all plugin manifests" — that class of
 * incident is exactly what this catches, before a tag goes out.
 *
 * package.json is the source of truth. Exit 1 on any drift.
 */
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const read = (p) => JSON.parse(fs.readFileSync(path.join(ROOT, p), 'utf8'));

const truth = read('package.json').version;
const targets = ['.claude-plugin/marketplace.json'];
for (const d of fs.readdirSync(path.join(ROOT, 'plugins'), { withFileTypes: true })) {
  if (d.isDirectory()) targets.push(`plugins/${d.name}/.claude-plugin/plugin.json`);
}

let bad = 0;
console.log(`▶ Version drift — package.json says ${truth}`);
for (const t of targets) {
  let v;
  try {
    v = read(t).version;
  } catch (e) {
    console.error(`  ❌ ${t}: unreadable — ${e.message}`);
    bad++;
    continue;
  }
  if (v === truth) console.log(`  ✅ ${t}`);
  else {
    console.error(`  ❌ ${t}: ${v} (expected ${truth})`);
    bad++;
  }
}

// The git tag the publish workflow fires on must match too. Checked only when
// a tag is being built (CI sets GITHUB_REF), so local runs stay quiet.
const ref = process.env.GITHUB_REF || '';
if (ref.startsWith('refs/tags/v')) {
  const tag = ref.slice('refs/tags/v'.length);
  if (tag === truth) console.log(`  ✅ git tag v${tag}`);
  else {
    console.error(`  ❌ git tag v${tag} does not match package.json ${truth}`);
    bad++;
  }
}

if (bad) {
  console.error(`${bad} version mismatch(es).`);
  process.exit(1);
}
console.log(`All ${targets.length} manifests at ${truth}.`);
