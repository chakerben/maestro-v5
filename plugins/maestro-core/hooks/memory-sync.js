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
 *
 * Safety contract (added in 5.3.2, after the 5.3.1 audit):
 *   - The block is located by a PAIRED match. 0 or >1 matches, or a stray tag
 *     anywhere, means we bail out without writing. A mention of the tag in
 *     prose must never cost the user the text that follows it.
 *   - The write is atomic (tmp + rename) and serialised by a lockfile, so two
 *     concurrent sessions in the same repo cannot truncate CLAUDE.md.
 *   - Entry names are validated before interpolation (a filename containing a
 *     newline must not be able to inject instructions into CLAUDE.md).
 *   - A symlinked CLAUDE.md is left alone (never write outside the project).
 */

'use strict';

const fs = require('fs');
const path = require('path');

const BLOCK_OPEN = '<maestro_memory>';
const BLOCK_CLOSE = '</maestro_memory>';
// Anchored on its own line, exactly as buildBlock() emits it. Anchoring is
// what makes a prose mention ("le bloc <maestro_memory> est géré...") harmless:
// it is not a line of its own, so it can never become the start of the match.
const BLOCK_RE = /^<maestro_memory>[ \t]*\r?$[\s\S]*?^<\/maestro_memory>[ \t]*\r?$/gm;
const MEMORY_DIR = path.join('maestro_docs', 'memory');
const ON_DEMAND_DIRS = ['internal', 'external'];
const EXCLUDED = new Set(['.gitkeep', 'README.md']);
const SAFE_NAME = /^[A-Za-z0-9._-]+\.md$/;
const MAX_ON_DEMAND = 200;
const LOCK_STALE_MS = 10000;

/** Entries that are .md files with a name safe to interpolate. */
function listMd(dir) {
  return fs
    .readdirSync(dir, { withFileTypes: true })
    .filter(
      (e) =>
        (e.isFile() || e.isSymbolicLink()) &&
        SAFE_NAME.test(e.name) &&
        !EXCLUDED.has(e.name)
    )
    .map((e) => e.name)
    .sort();
}

function buildBlock(memoryPath) {
  let rootFiles = [];
  try {
    rootFiles = listMd(memoryPath).map((n) => `@${MEMORY_DIR}/${n}`);
  } catch {
    return null;
  }

  const onDemand = [];
  for (const sub of ON_DEMAND_DIRS) {
    try {
      for (const n of listMd(path.join(memoryPath, sub))) {
        onDemand.push(`${MEMORY_DIR}/${sub}/${n}`);
      }
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
    lines.push(...onDemand.slice(0, MAX_ON_DEMAND));
    if (onDemand.length > MAX_ON_DEMAND) {
      lines.push(`<!-- +${onDemand.length - MAX_ON_DEMAND} more, not listed -->`);
    }
  }
  lines.push(BLOCK_CLOSE);
  return lines.join('\n');
}

/**
 * Replace the block, or append it. Returns the new content, or null when the
 * file is in a shape we refuse to touch.
 */
function applyBlock(content, newBlock) {
  const matches = content.match(BLOCK_RE) || [];

  if (matches.length === 1) {
    return content.replace(BLOCK_RE, () => newBlock);
  }
  if (matches.length > 1) {
    // Several well-formed blocks: ambiguous, a human must resolve it.
    return null;
  }
  // No well-formed block. If a tag appears anyway (prose mention, code fence,
  // unclosed block, close-before-open), appending would compound the mess and
  // replacing would eat user content. Bail — a stale block costs a sync, a
  // wrong edit costs the user's file.
  if (content.includes(BLOCK_OPEN) || content.includes(BLOCK_CLOSE)) return null;

  return content.trimEnd() + '\n\n' + newBlock + '\n';
}

/** Serialise concurrent sessions; returns a release fn, or null if locked. */
function acquireLock(lockPath) {
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      fs.closeSync(fs.openSync(lockPath, 'wx'));
      return () => {
        try {
          fs.unlinkSync(lockPath);
        } catch {
          /* already gone */
        }
      };
    } catch {
      // Held by someone else — reclaim only if clearly stale, else give up.
      try {
        if (Date.now() - fs.statSync(lockPath).mtimeMs > LOCK_STALE_MS) {
          fs.unlinkSync(lockPath);
          continue;
        }
      } catch {
        continue; /* vanished between calls: retry once */
      }
      return null;
    }
  }
  return null;
}

function writeAtomic(target, content) {
  const tmp = `${target}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, content, 'utf8');
  try {
    fs.renameSync(tmp, target);
  } catch (e) {
    try {
      fs.unlinkSync(tmp);
    } catch {
      /* best effort */
    }
    throw e;
  }
}

function main() {
  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const memoryPath = path.join(projectDir, MEMORY_DIR);
  const claudeMd = path.join(projectDir, 'CLAUDE.md');

  // Not a Maestro project or no memory bank yet -> silently exit
  if (!fs.existsSync(memoryPath)) return;

  // Never follow a symlink out of the project.
  let st;
  try {
    st = fs.lstatSync(claudeMd);
  } catch {
    return; // no CLAUDE.md
  }
  if (!st.isFile()) return;

  const newBlock = buildBlock(memoryPath);
  if (newBlock === null) return;

  const release = acquireLock(path.join(projectDir, '.claude-md.maestro.lock'));
  if (!release) return; // another session is syncing: fail open

  try {
    let content;
    try {
      content = fs.readFileSync(claudeMd, 'utf8');
    } catch {
      return;
    }

    const updated = applyBlock(content, newBlock);
    if (updated === null || updated === content) return;

    try {
      writeAtomic(claudeMd, updated);
    } catch {
      /* fail open */
    }
  } finally {
    release();
  }
}

try {
  main();
} catch {
  /* Philosophy rule #3: exit 0 on any error */
}
process.exit(0);
