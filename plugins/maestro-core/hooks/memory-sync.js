#!/usr/bin/env node
/**
 * Maestro 5 — memory-sync.js
 * Hook: SessionStart (the ONLY hook in maestro-core — Philosophy rule #1)
 *
 * Syncs the <maestro_memory> block in the project's CLAUDE.md with references
 * to the memory bank files under maestro_docs/memory/.
 *
 * Two tiers:
 *   - Root files in maestro_docs/memory/  -> always loaded (@-references)
 *   - internal/ and external/ subdirs     -> listed as read-on-demand paths
 *
 * Contract (Philosophy rule #3):
 *   - < 100 ms
 *   - exit 0 on ANY error (fail open, never break a session)
 *   - no subprocess, no network
 */

'use strict';

const fs = require('fs');
const path = require('path');

const BLOCK_OPEN = '<maestro_memory>';
const BLOCK_CLOSE = '</maestro_memory>';
const MEMORY_DIR = path.join('maestro_docs', 'memory');
const ON_DEMAND_DIRS = ['internal', 'external'];
const EXCLUDED = new Set(['.gitkeep', 'README.md']);

function main() {
  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const memoryPath = path.join(projectDir, MEMORY_DIR);
  const claudeMd = path.join(projectDir, 'CLAUDE.md');

  // Not a Maestro project or no memory bank yet -> silently exit
  if (!fs.existsSync(memoryPath)) return;
  if (!fs.existsSync(claudeMd)) return;

  // Tier 1: root memory files (always loaded)
  let rootFiles = [];
  try {
    rootFiles = fs
      .readdirSync(memoryPath, { withFileTypes: true })
      .filter((e) => e.isFile() && e.name.endsWith('.md') && !EXCLUDED.has(e.name))
      .map((e) => `@${MEMORY_DIR}/${e.name}`)
      .sort();
  } catch {
    return;
  }

  // Tier 2: on-demand files (listed, not loaded)
  const onDemand = [];
  for (const sub of ON_DEMAND_DIRS) {
    const subPath = path.join(memoryPath, sub);
    try {
      const entries = fs
        .readdirSync(subPath, { withFileTypes: true })
        .filter((e) => e.isFile() && e.name.endsWith('.md') && !EXCLUDED.has(e.name))
        .map((e) => `${MEMORY_DIR}/${sub}/${e.name}`)
        .sort();
      onDemand.push(...entries);
    } catch {
      /* subdir absent: fine */
    }
  }

  const lines = [BLOCK_OPEN];
  if (rootFiles.length) {
    lines.push('<!-- always loaded -->');
    lines.push(...rootFiles);
  }
  if (onDemand.length) {
    lines.push('<!-- read on demand, not auto-loaded -->');
    lines.push(...onDemand);
  }
  lines.push(BLOCK_CLOSE);
  const newBlock = lines.join('\n');

  let content;
  try {
    content = fs.readFileSync(claudeMd, 'utf8');
  } catch {
    return;
  }

  const openIdx = content.indexOf(BLOCK_OPEN);
  const closeIdx = content.indexOf(BLOCK_CLOSE);

  let updated;
  if (openIdx !== -1 && closeIdx !== -1 && closeIdx > openIdx) {
    updated =
      content.slice(0, openIdx) + newBlock + content.slice(closeIdx + BLOCK_CLOSE.length);
  } else {
    updated = content.trimEnd() + '\n\n' + newBlock + '\n';
  }

  if (updated !== content) {
    try {
      fs.writeFileSync(claudeMd, updated, 'utf8');
    } catch {
      /* fail open */
    }
  }
}

try {
  main();
} catch {
  /* Philosophy rule #3: exit 0 on any error */
}
process.exit(0);
