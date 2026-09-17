#!/usr/bin/env node
/**
 * Maestro 5 — memory-sync.js
 * Hook: SessionStart (the ONLY hook in maestro-core — Philosophy rule #1)
 *
 * Syncs two blocks in the project's CLAUDE.md:
 *   <maestro_memory>  — references to the memory bank files under
 *                        maestro_docs/memory/ (two tiers, see below)
 *   <maestro_routing> — the plain-prompt router, copied from this plugin's
 *                        references/routing.md so every project gets the
 *                        current map at session start without anyone typing
 *                        anything. Refreshed only when its content hash
 *                        changes (5.9.0). Same paired-match safety as memory.
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
const BLOCK_RE = /^<maestro_memory>[ \t]*\r?$[\s\S]*?^<\/maestro_memory>[ \t]*(?=\r?$)/gm;
const ROUTING_OPEN = '<maestro_routing>';
const ROUTING_CLOSE = '</maestro_routing>';
const ROUTING_RE = /^<maestro_routing>[ \t]*\r?$[\s\S]*?^<\/maestro_routing>[ \t]*(?=\r?$)/gm;
const ROUTING_SRC = path.join(__dirname, '..', 'references', 'routing.md');
const MAX_ROUTING_BYTES = 8192;
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
/**
 * A block that sits inside a fenced code block (``` or ~~~) is documentation,
 * not the block. Mask fenced regions with same-length filler so offsets are
 * preserved, match on the mask, then apply to the real content.
 */
function maskFences(content) {
  const lines = content.split('\n');
  let inFence = false;
  return lines
    .map((l) => {
      if (/^\s*(```|~~~)/.test(l)) { inFence = !inFence; return '#'.repeat(l.length); }
      return inFence ? '#'.repeat(l.length) : l;
    })
    .join('\n');
}

function applyBlock(content, newBlock, re = BLOCK_RE, open = BLOCK_OPEN, close = BLOCK_CLOSE) {
  const masked = maskFences(content);
  const eol = content.includes('\r\n') ? '\r\n' : '\n';
  if (eol !== '\n') newBlock = newBlock.replace(/\r?\n/g, eol);
  const matches = [];
  re.lastIndex = 0;
  let m;
  while ((m = re.exec(masked)) !== null) matches.push({ index: m.index, length: m[0].length });
  re.lastIndex = 0;

  if (matches.length === 1) {
    const { index, length } = matches[0];
    return content.slice(0, index) + newBlock + content.slice(index + length);
  }
  if (matches.length > 1) {
    // Several well-formed blocks: ambiguous, a human must resolve it.
    return null;
  }
  // No well-formed block OUTSIDE fences. If a tag appears anyway outside a
  // fence (prose mention, unclosed block, close-before-open), appending would
  // compound the mess and replacing would eat user content. Bail — a stale
  // block costs a sync, a wrong edit costs the user's file. Tags that live
  // only inside fences are documentation: append normally.
  if (masked.includes(open) || masked.includes(close)) return null;

  return content.replace(/\s+$/, '') + eol + eol + newBlock + eol;
}

/**
 * The routing block: references/routing.md wrapped in tags, with a hash line
 * so an unchanged router costs nothing. Returns null when the source is
 * missing, oversized, or contains a tag of its own (never nest).
 */
function buildRoutingBlock() {
  let src;
  try {
    src = fs.readFileSync(ROUTING_SRC, 'utf8');
  } catch {
    return null;
  }
  if (src.length > MAX_ROUTING_BYTES) return null;
  if (src.includes(ROUTING_OPEN) || src.includes(ROUTING_CLOSE)) return null;
  const hash = require('crypto').createHash('sha1').update(src).digest('hex').slice(0, 12);
  return [ROUTING_OPEN, `<!-- maestro-routing ${hash} — managed by maestro-core, edit references/routing.md instead -->`, src.trimEnd(), ROUTING_CLOSE].join('\n');
}

/** Only the routing block: replace if present and stale, append if absent. */
function applyRouting(content, newBlock) {
  const matches = maskFences(content).match(ROUTING_RE) || [];
  const hashLine = newBlock.split('\n')[1];
  if (matches.length === 1 && content.includes(hashLine)) return content; // up to date
  return applyBlock(content, newBlock, ROUTING_RE, ROUTING_OPEN, ROUTING_CLOSE);
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

  // A Maestro project has a memory bank (memory block) and/or a routing block
  // already in its CLAUDE.md. Anything else is not ours: silently exit.
  let hasMemory = false;
  try { hasMemory = fs.statSync(memoryPath).isDirectory(); } catch { /* absent */ }

  // Never follow a symlink out of the project.
  let st;
  try {
    st = fs.lstatSync(claudeMd);
  } catch {
    return; // no CLAUDE.md
  }
  if (!st.isFile()) return;

  const newBlock = hasMemory ? buildBlock(memoryPath) : null;
  const routingBlock = buildRoutingBlock();
  if (newBlock === null && routingBlock === null) return;

  const release = acquireLock(path.join(projectDir, '.claude-md.maestro.lock'));
  if (!release) return; // another session is syncing: fail open

  try {
    let content;
    try {
      content = fs.readFileSync(claudeMd, 'utf8');
    } catch {
      return;
    }

    // Routing: only for projects that are already Maestro's (a routing block
    // present, or a memory bank). Never append a router to a foreign repo.
    const isMaestroProject = hasMemory || ROUTING_RE.test(maskFences(content));
    ROUTING_RE.lastIndex = 0;
    if (!isMaestroProject) return;

    // Any ambiguity in either block (0 well-formed + stray tag, or >1) means
    // a human must look: the file is left exactly as it is.
    let updated = content;
    if (newBlock !== null) {
      updated = applyBlock(updated, newBlock);
      if (updated === null) return;
    }
    if (routingBlock !== null) {
      updated = applyRouting(updated, routingBlock);
      if (updated === null) return;
    }
    if (updated === content) return;

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
